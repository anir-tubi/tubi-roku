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
  const elementMatch = line.match(/<(\w+)(?:\s+[^>]*?name="([^"]+)"[^>]*?)?(?:\s+[^>]*?visible="([^"]+)"[^>]*?)?>/);
  if (!elementMatch) return null;

  const tagName = elementMatch[1];
  const name = elementMatch[2] || tagName;
  const visible = elementMatch[3] || 'true'; // Default to visible if not specified
  const indent = line.search(/\S|$/);

  return { name, type: tagName, visible, indent };
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
        // Check if this is our target
        if (element.name === targetElement) {
          foundTarget = true;
          // Build path from ContentController, filtering to important elements
          const contentControllerIndex = currentPath.findIndex(e => e.name === 'ContentController');
          if (contentControllerIndex !== -1) {
            const fullPath = currentPath.slice(contentControllerIndex);
            // No filtering - show all elements in path
            targetPath = fullPath.map(e => e.name);
          }
          console.log(`\n🎯 Found target element: ${targetElement}`);
          break;
        }
      }
    }
  }

  return { foundTarget, targetPath };
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function findElementHierarchy(targetElement = null) {
  console.log('🚀 Dynamic Hierarchy Finder (Generic)');

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

  const device = loadDeviceConfig();

  try {
    const xmlData = await fetchDOM(device);
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
      return {
        found: false,
        path: [],
        xpath: null
      };
    }

    console.log(`\n✅ Dynamic analysis complete!`);

  } catch (error) {
    console.error(`\n❌ Analysis failed: ${error.message}`);
    throw error;
  }
}

if (require.main === module) {
  findElementHierarchy();
}

module.exports = { findElementHierarchy, findElementPath, fetchDOM, loadDeviceConfig };
