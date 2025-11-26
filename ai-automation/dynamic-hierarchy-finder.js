#!/usr/bin/env node

const http = require('http');
const path = require('path');
const fs = require('fs');

// ============================================================================
// CONFIGURATION
// ============================================================================

function loadDeviceConfig() {
  try {
    const rtaConfigPath = path.join(__dirname, '..', 'rta-config.json');
    if (fs.existsSync(rtaConfigPath)) {
      const rtaConfig = JSON.parse(fs.readFileSync(rtaConfigPath, 'utf8'));
      if (rtaConfig.RokuDevice?.devices) {
        const deviceIndex = rtaConfig.RokuDevice.deviceIndex || 0;
        const device = rtaConfig.RokuDevice.devices[deviceIndex];
        if (device?.host) {
          return { host: device.host, port: 8060 };
        }
      }
    }
    if (process.env.ROKU_DEV_TARGET) {
      return { host: process.env.ROKU_DEV_TARGET, port: 8060 };
    }
    throw new Error('No Roku device configuration found');
  } catch (e) {
    console.error(`❌ Error loading device config: ${e.message}`);
    process.exit(1);
  }
}

// ============================================================================
// DOM FETCHING
// ============================================================================

function fetchDOM(device) {
  return new Promise((resolve, reject) => {
    const url = `http://${device.host}:${device.port}/query/app-ui`;
    console.log(`🔍 Fetching DOM from: ${url}`);

    http.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        console.log(`✅ DOM fetched successfully (${data.length} characters)`);
        resolve(data);
      });
    }).on('error', (err) => {
      console.error(`❌ Error fetching DOM: ${err.message}`);
      reject(err);
    });
  });
}

// ============================================================================
// DYNAMIC HIERARCHY ANALYSIS
// ============================================================================

/**
 * Parses an XML line to extract element information
 */
function parseElementLine(line) {
  const elementMatch = line.match(/<(\w+)(?:\s+[^>]*?name="([^"]+)"[^>]*?)?(?:\s+[^>]*?visible="([^"]+)"[^>]*?)?(?:\s+[^>]*?text="([^"]*)"[^>]*?)?>/);
  if (!elementMatch) return null;

  const tagName = elementMatch[1];
  const name = elementMatch[2] || tagName;
  const visible = elementMatch[3] || 'true'; // Default to visible if not specified
  const text = elementMatch[4] || ''; // Extract text attribute if present
  const indent = line.search(/\S|$/);

  return { name, type: tagName, visible, text, indent };
}

/**
 * Checks if an element is a system-level element that should be filtered out
 */
function isSystemElement(name, type) {
  // Filter out generic system elements only
  const genericSystemElements = [
    'app', 'status', 'topscreen', 'plugin', 'screen', 'TubiScene'
  ];

  // Filter out generic system elements
  if (genericSystemElements.includes(name) || genericSystemElements.includes(type)) {
    return true;
  }

  return false;
}

// Removed isImportantElement - it was redundant!

/**
 * Fuzzy match element names - more flexible than exact matching
 * Examples:
 * - "ButtonList" matches "Menu" (similar concepts)
 * - "ButtonList" matches "buttonList" (case insensitive)
 * - "Title" matches "ScreenTitle" (partial match)
 */
function matchElement(actualName, searchName) {
  // Normalize to lowercase for comparison
  const actual = actualName.toLowerCase();
  const search = searchName.toLowerCase();

  // 1. Exact match (case insensitive)
  if (actual === search) {
    return true;
  }

  // 2. One contains the other
  if (actual.includes(search) || search.includes(actual)) {
    return true;
  }

  // 3. Common synonyms/aliases and acronyms
  const synonyms = {
    'menu': ['buttonlist', 'menulist', 'buttons', 'list'],
    'buttonlist': ['menu', 'menulist', 'buttons'],
    'title': ['label', 'text', 'heading'],
    'list': ['grid', 'row', 'menu'],
    'button': ['btn', 'menuitem'],
    // Common acronyms and alternative names
    'bww': ['browsewatchwhile', 'browsewatching', 'ymal', 'youmayalsolike', 'related', 'recommendations'],
    'ymal': ['youmayalsolike', 'bww', 'browsewatchwhile', 'related', 'recommendations'],
    'youmayalsolike': ['ymal', 'bww', 'related', 'recommendations'],
    'browsewatchwhile': ['bww', 'ymal', 'related'],
    'related': ['ymal', 'bww', 'youmayalsolike', 'recommendations'],
    'cw': ['continuewatching', 'resume', 'inprogress'],
    'continuewatching': ['cw', 'resume', 'inprogress'],
    'ml': ['mylist', 'watchlist', 'favorites'],
    'mylist': ['ml', 'watchlist', 'favorites'],
    'mystuff': ['mylist', 'ml', 'watchlist', 'favorites'],
    'pc': ['parentalcontrol', 'parentalcontrols', 'kidssafe'],
    'parentalcontrol': ['pc', 'kidssafe'],
    'sl': ['sealion', 'live', 'livetv'],
    'sealion': ['sl', 'live', 'livetv'],
    'vp': ['videopreview', 'preview', 'trailer'],
    'videopreview': ['vp', 'preview', 'trailer'],
  };

  // Check if search term has synonyms that match actual
  for (const [key, values] of Object.entries(synonyms)) {
    if (search.includes(key)) {
      for (const synonym of values) {
        if (actual.includes(synonym)) {
          console.log(`  💡 Fuzzy match: "${actualName}" matches "${searchName}" (via synonym: ${key}↔${synonym})`);
          return true;
        }
      }
    }
    // Also check reverse
    if (actual.includes(key)) {
      for (const synonym of values) {
        if (search.includes(synonym)) {
          console.log(`  💡 Fuzzy match: "${actualName}" matches "${searchName}" (via synonym: ${key}↔${synonym})`);
          return true;
        }
      }
    }
  }

  // 4. Remove common prefixes and compare
  const prefixes = ['detail', 'home', 'screen', 'movie', 'series', 'tv'];
  let actualStripped = actual;
  let searchStripped = search;

  for (const prefix of prefixes) {
    actualStripped = actualStripped.replace(prefix, '');
    searchStripped = searchStripped.replace(prefix, '');
  }

  if (actualStripped === searchStripped && actualStripped.length > 0) {
    console.log(`  💡 Fuzzy match: "${actualName}" matches "${searchName}" (stripped prefixes)`);
    return true;
  }

  return false;
}

/**
 * Find similar elements when exact match fails
 * Returns all visible elements with their text content for LLM to analyze
 */
function findSimilarElements(xmlData, targetElement) {
  const lines = xmlData.split('\n');
  const allElements = [];
  const seen = new Set();
  let foundContentController = false;

  console.log(`  🤖 Collecting visible elements for AI analysis...`);

  for (const line of lines) {
    const element = parseElementLine(line);
    if (!element) continue;

    // Start processing from ContentController
    if (element.name === 'ContentController') {
      foundContentController = true;
    }

    if (!foundContentController) continue;

    // Skip system elements and invisible elements
    if (isSystemElement(element.name, element.type) || element.visible === 'false') {
      continue;
    }

    // Skip duplicates
    if (seen.has(element.name)) continue;
    seen.add(element.name);

    const elementText = element.text || '';

    // Collect all visible elements with their text
    // The LLM will decide which one matches best
    allElements.push({
      name: element.name,
      type: element.type,
      text: elementText
    });
  }

  console.log(`  📊 Found ${allElements.length} visible elements on screen`);

  // Return up to 20 elements for LLM analysis
  // Prioritize elements with text content
  const elementsWithText = allElements.filter(e => e.text && e.text.trim().length > 0);
  const elementsWithoutText = allElements.filter(e => !e.text || e.text.trim().length === 0);

  const suggestions = [...elementsWithText, ...elementsWithoutText].slice(0, 20);

  return suggestions;
}

/**
 * Dynamically finds the path to any element
 */
function findElementPath(xmlData, targetElement) {
  console.log(`🔍 Dynamically analyzing DOM structure for: ${targetElement}`);

  const lines = xmlData.split('\n');
  let currentPath = [];
  let foundTarget = false;
  let targetPath = [];
  let lastIndent = -1;
  let foundContentController = false;

  for (const line of lines) {
    const element = parseElementLine(line);
    if (!element) continue;

    // Adjust currentPath based on indentation
    if (element.indent > lastIndent) {
      currentPath.push(element);
    } else if (element.indent < lastIndent) {
      while (currentPath.length > 0 && currentPath[currentPath.length - 1].indent >= element.indent) {
        currentPath.pop();
      }
      currentPath.push(element);
    } else {
      if (currentPath.length > 0) {
        currentPath[currentPath.length - 1] = element;
      } else {
        currentPath.push(element);
      }
    }
    lastIndent = element.indent;

    // Start processing from ContentController
    if (element.name === 'ContentController') {
      foundContentController = true;
    }

    // Only process after finding ContentController
    if (foundContentController) {
      // Skip system elements
      if (isSystemElement(element.name, element.type)) {
        continue;
      }

      // Skip invisible elements
      if (element.visible === 'false') {
        continue;
      }

      // Skip elements that are children of invisible parents
      const hasInvisibleParent = currentPath.some(parent => parent.visible === 'false');
      if (hasInvisibleParent) {
        continue;
      }

      // Process visible elements
      if (true) {
        // Check if this is our target - use FUZZY matching
        const isMatch = matchElement(element.name, targetElement);

        if (isMatch) {
          foundTarget = true;
          // Build path from ContentController, filtering to important elements
          const contentControllerIndex = currentPath.findIndex(e => e.name === 'ContentController');
          if (contentControllerIndex !== -1) {
            const fullPath = currentPath.slice(contentControllerIndex);
            // No filtering - show all elements in path
            targetPath = fullPath.map(e => e.name);
          }
          console.log(`\n🎯 Found target element: ${element.name} (matched search: ${targetElement})`);
          break;
        }
      }
    }
  }

  return { foundTarget, targetPath };
}

// ============================================================================
// LLM-BASED ELEMENT FINDING
// ============================================================================

/**
 * Find element using LLM (Claude) for intelligent DOM analysis
 * This replaces 200+ lines of regex/heuristic logic with natural language understanding
 */
async function findElementHierarchyWithLLM(targetElement, context = null) {
  console.log('🚀 Dynamic Hierarchy Finder (LLM-Enhanced)');
  console.log('🤖 Using Claude AI for intelligent element matching...');
  if (context) {
    console.log(`📍 Screen context: ${context}`);
  }

  const device = loadDeviceConfig();

  try {
    const xmlData = await fetchDOM(device);

    // Use LLM to analyze DOM and find element
    const { callClaudeForDOMParsing } = require('./lib/llm-client');
    const result = await callClaudeForDOMParsing(xmlData, targetElement, context);

    if (!result) {
      console.error('❌ LLM analysis failed, falling back to regex-based approach...');
      return findElementHierarchyLegacy(targetElement, xmlData);
    }

    if (result.found) {
      console.log(`\n🎯 LLM found element: ${result.matchedElement || targetElement}`);
      console.log(`   Confidence: ${result.confidence}`);
      console.log(`   Reasoning: ${result.reasoning}`);

      console.log(`\n🛤️  Dynamic Path to ${targetElement}:`);
      for (let i = 0; i < result.path.length; i++) {
        const element = result.path[i];
        const prefix = '  '.repeat(i);
        console.log(`${prefix}${element}`);
      }

      // Normalize xpath format: convert > or / to . (Roku keyPath format)
      let normalizedXpath = result.xpath;
      if (normalizedXpath.includes('>') || normalizedXpath.includes('/')) {
        console.log(`   ⚠️  Fixing xpath format (converting > or / to .)`);
        normalizedXpath = normalizedXpath.replace(/>/g, '.').replace(/\//g, '.');
        // Remove any double dots that might have been created
        normalizedXpath = normalizedXpath.replace(/\.+/g, '.');
      }

      console.log(`\n📍 Generated XPath: ${normalizedXpath}`);

      return {
        found: true,
        path: result.path,
        xpath: normalizedXpath,
        confidence: result.confidence,
        reasoning: result.reasoning
      };
    } else {
      console.log(`\n❌ Target element '${targetElement}' not found in DOM`);

      if (result.suggestions && result.suggestions.length > 0) {
        console.log(`\n💡 LLM suggests ${result.suggestions.length} possible alternatives:`);
        result.suggestions.forEach((suggestion, index) => {
          const textInfo = suggestion.text ? ` [text: "${suggestion.text}"]` : '';
          console.log(`   ${index + 1}. ${suggestion.name} (${suggestion.type})${textInfo}`);
        });
        console.log(`\n💡 Try using one of these element names instead.`);
      }

      return {
        found: false,
        path: [],
        xpath: null,
        suggestions: result.suggestions || []
      };
    }

  } catch (error) {
    console.error(`\n❌ LLM analysis failed: ${error.message}`);
    console.error('   Falling back to regex-based approach...');

    const device = loadDeviceConfig();
    const xmlData = await fetchDOM(device);
    return findElementHierarchyLegacy(targetElement, xmlData);
  }
}

/**
 * Legacy regex-based element finding (fallback)
 * Kept for backward compatibility and fallback when LLM fails
 */
async function findElementHierarchyLegacy(targetElement, xmlData = null) {
  console.log('🚀 Dynamic Hierarchy Finder (Regex-Based)');

  if (!xmlData) {
    const device = loadDeviceConfig();
    xmlData = await fetchDOM(device);
  }

  const { foundTarget, targetPath } = findElementPath(xmlData, targetElement);

  if (foundTarget) {
    console.log(`\n🛤️  Dynamic Path to ${targetElement}:`);
    for (let i = 0; i < targetPath.length; i++) {
      const element = targetPath[i];
      const prefix = '  '.repeat(i);
      console.log(`${prefix}${element}`);
    }

    const xpath = targetPath.map(element => `#${element}`).join('.');
    console.log(`\n📍 Generated XPath: ${xpath}`);

    return {
      found: true,
      path: targetPath,
      xpath: xpath
    };
  } else {
    console.log(`\n❌ Target element '${targetElement}' not found in DOM`);

    // Try to find similar elements using fuzzy matching
    console.log(`\n🔍 Searching for similar elements...`);
    const suggestions = findSimilarElements(xmlData, targetElement);

    if (suggestions.length > 0) {
      console.log(`\n💡 Found ${suggestions.length} similar element(s):`);
      suggestions.slice(0, 5).forEach((suggestion, index) => {
        const textInfo = suggestion.text ? ` [text: "${suggestion.text}"]` : '';
        console.log(`   ${index + 1}. ${suggestion.name}${textInfo}`);
      });
      console.log(`\n💡 Try using one of these element names instead, or they might be what you're looking for.`);

      return {
        found: false,
        path: [],
        xpath: null,
        suggestions: suggestions.slice(0, 5)
      };
    }

    return {
      found: false,
      path: [],
      xpath: null,
      suggestions: []
    };
  }
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function findElementHierarchy(targetElement = null, useLLM = true, context = null) {
  // If no targetElement provided, get from command line args
  if (!targetElement) {
    targetElement = process.argv[2];
  }

  if (!targetElement) {
    console.error('❌ Usage: node dynamic-hierarchy-finder.js <elementName>');
    console.error('   Example: node dynamic-hierarchy-finder.js Menu');
    console.error('   Example: node dynamic-hierarchy-finder.js Title');
    console.error('   Example: node dynamic-hierarchy-finder.js RelatedGrid');
    process.exit(1);
  }

  try {
    // Check config for feature-specific toggle
    const config = require('./config');
    const domParsingEnabled = config.llm && config.llm.features && config.llm.features.domParsing !== false;

    // Use LLM-based approach only if enabled in config
    if (useLLM && domParsingEnabled) {
      return await findElementHierarchyWithLLM(targetElement, context);
    } else {
      if (!domParsingEnabled) {
        console.log('💡 DOM parsing LLM disabled in config, using regex approach');
      }
      return await findElementHierarchyLegacy(targetElement);
    }
  } catch (error) {
    console.error(`\n❌ Analysis failed: ${error.message}`);
    throw error;
  }
}

if (require.main === module) {
  findElementHierarchy();
}

module.exports = {
  findElementHierarchy,
  findElementHierarchyWithLLM,
  findElementHierarchyLegacy,
  findElementPath,
  fetchDOM,
  loadDeviceConfig
};
