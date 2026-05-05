const log = require('fancy-log');
const https = require('https');
const { getBuildTag } = require('./config');


/**
 * Makes an HTTPS request to the Jira API. Returns parsed JSON response.
 * @param {string} method - HTTP method (GET, POST, PUT)
 * @param {string} path - URL path (e.g. /rest/api/3/issue/TOTT-123)
 * @param {string} auth - Base64 encoded auth string
 * @param {Object} [body] - Request body (for POST/PUT)
 * @param {Object} [queryParams] - Query string parameters (for GET)
 */
function jiraRequest(method, path, auth, body, queryParams) {
  return new Promise((resolve, reject) => {
    let fullPath = path;
    if (queryParams) {
      const qs = Object.entries(queryParams)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      fullPath += `?${qs}`;
    }

    const options = {
      hostname: JIRA_BASE_URL,
      path: fullPath,
      method,
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json',
      }
    };

    const payload = body ? JSON.stringify(body) : null;
    if (payload) {
      options.headers['Content-Type'] = 'application/json';
      options.headers['Content-Length'] = Buffer.byteLength(payload);
    }

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = data ? JSON.parse(data) : {};
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ data: parsed, status: res.statusCode });
          } else {
            const err = Object.assign(new Error(`Jira API ${res.statusCode}`), {
              response: { status: res.statusCode, data: parsed }
            });
            reject(err);
          }
        } catch (parseError) {
          reject(new Error(`Jira API ${res.statusCode}: invalid JSON response`));
        }
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

const JIRA_BASE_URL = 'tubitv.atlassian.net';
const JIRA_PROJECT_ID = '10232';
const JIRA_PARENT_EPIC_KEY = 'TOTT-1269';
const JIRA_ASSIGNEE_ACCOUNT_ID = '712020:34b43eca-620f-497e-86f7-a1ea6e607357'; // Tuan Vo
const GITHUB_REPO_URL = 'https://github.com/adRise/tubi-roku';


function logJiraError(action, error) {
  log(`Failed to ${action}: ${error.message}`);
  if (error.response) {
    log(`Status: ${error.response.status}`);
    log(`Response: ${JSON.stringify(error.response.data)}`);
  }
}


function logTicketUrl(ticketKey, status) {
  const url = `https://${JIRA_BASE_URL}/browse/${ticketKey}`;
  console.log('');
  console.log('=======================================================================');
  console.log(`  QA TICKET ${status}: ${ticketKey}`);
  console.log(`  ${url}`);
  console.log('=======================================================================');
  console.log('');
}


// ADF helper: plain text paragraph
function adfParagraph(text) {
  if (!text) return { type: 'paragraph', content: [] };
  return {
    type: 'paragraph',
    content: [{ type: 'text', text }]
  };
}


// ADF helper: paragraph with bold text
function adfBoldParagraph(text) {
  return {
    type: 'paragraph',
    content: [{ type: 'text', text, marks: [{ type: 'strong' }] }]
  };
}


// ADF helper: horizontal rule
function adfRule() {
  return { type: 'rule' };
}


// ADF helper: inline card (smart link)
function adfInlineCard(url) {
  return {
    type: 'paragraph',
    content: [
      { type: 'inlineCard', attrs: { url } },
      { type: 'text', text: ' ' }
    ]
  };
}


// ADF helper: ordered list from an array of strings
function adfOrderedList(items) {
  return {
    type: 'orderedList',
    attrs: { order: 1 },
    content: items.map(item => ({
      type: 'listItem',
      content: [adfParagraph(item)]
    }))
  };
}


// ADF helper: heading node
function adfHeading(text, level) {
  return {
    type: 'heading',
    attrs: { level },
    content: [{ type: 'text', text }]
  };
}


// ADF helper: table cell (header or data)
function adfTableCell(text, isHeader) {
  return {
    type: isHeader ? 'tableHeader' : 'tableCell',
    content: [adfParagraph(text)]
  };
}


// ADF helper: table from parsed rows
function adfTable(headerRow, dataRows) {
  const rows = [];
  rows.push({
    type: 'tableRow',
    content: headerRow.map(cell => adfTableCell(cell, true))
  });
  for (const row of dataRows) {
    rows.push({
      type: 'tableRow',
      content: row.map(cell => adfTableCell(cell, false))
    });
  }
  return {
    type: 'table',
    attrs: { isNumberColumnEnabled: false, layout: 'default' },
    content: rows
  };
}


/**
 * Parses a markdown table row into cell values.
 * e.g. "| a | b | c |" => ["a", "b", "c"]
 */
function parseTableRow(line) {
  return line.split('|').slice(1, -1).map(cell => cell.trim());
}


/**
 * Checks if a line is a markdown table separator (e.g. "|---|---|")
 */
function isTableSeparator(line) {
  return /^\|[\s\-:]+(\|[\s\-:]+)+\|$/.test(line.trim());
}


/**
 * Converts markdown text into an array of ADF content nodes.
 * Handles headings, tables, horizontal rules, numbered lists, and plain paragraphs.
 */
function markdownToAdf(text) {
  const nodes = [];
  const lines = text.split('\n');
  let i = 0;

  while (i < lines.length) {
    const line = lines[i].trimEnd();
    const trimmed = line.trim();

    // Skip empty lines
    if (!trimmed) {
      i++;
      continue;
    }

    // Horizontal rule
    if (/^---+$/.test(trimmed)) {
      nodes.push(adfRule());
      i++;
      continue;
    }

    // Headings (### then ## then #)
    const headingMatch = trimmed.match(/^(#{1,6})\s+(.+)$/);
    if (headingMatch) {
      const level = Math.min(headingMatch[1].length, 6);
      nodes.push(adfHeading(headingMatch[2], level));
      i++;
      continue;
    }

    // Table: starts with | and has at least one inner |
    if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.indexOf('|', 1) < trimmed.length - 1) {
      const headerCells = parseTableRow(trimmed);
      i++;

      // Skip separator row
      if (i < lines.length && isTableSeparator(lines[i])) {
        i++;
      }

      // Collect data rows
      const dataRows = [];
      while (i < lines.length) {
        const rowLine = lines[i].trim();
        if (!rowLine.startsWith('|') || !rowLine.endsWith('|')) break;
        if (isTableSeparator(rowLine)) { i++; continue; }
        dataRows.push(parseTableRow(rowLine));
        i++;
      }

      nodes.push(adfTable(headerCells, dataRows));
      continue;
    }

    // Numbered list: collect consecutive numbered lines
    const numberedMatch = trimmed.match(/^\d+\.\s+(.+)$/);
    if (numberedMatch) {
      const items = [];
      while (i < lines.length) {
        const numLine = lines[i].trim();
        const m = numLine.match(/^\d+\.\s+(.+)$/);
        if (!m) break;
        items.push(m[1]);
        i++;
      }
      nodes.push(adfOrderedList(items));
      continue;
    }

    // Default: plain paragraph
    nodes.push(adfParagraph(trimmed));
    i++;
  }

  return nodes;
}


/**
 * Converts structured QA changes data into ADF content for a Jira ticket description.
 * Mirrors the Markdown layout produced by buildQaChanges() in js/git.js.
 *
 * @param {Array} changes - The qaChangesData array from buildQaChanges()
 * @param {string} minorVersion - e.g. "3_9"
 * @param {string} buildVersion - e.g. "3_9_104"
 * @returns {Array} ADF content nodes
 */
function buildQaTicketDescription(changes, minorVersion, buildVersion, existingTargetDate) {
  const content = [];

  let targetDateStr;
  if (existingTargetDate) {
    targetDateStr = existingTargetDate;
  } else {
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + 7);
    targetDateStr = `${String(targetDate.getMonth() + 1).padStart(2, '0')}/${String(targetDate.getDate()).padStart(2, '0')}/${targetDate.getFullYear()}`;
  }

  content.push(adfBoldParagraph('Target Release Date'));
  content.push(adfParagraph(targetDateStr));
  content.push(adfParagraph());

  content.push(adfBoldParagraph('Staging Channel'));
  content.push(adfParagraph(minorVersion));
  content.push(adfParagraph());

  content.push(adfBoldParagraph('Branch Name (for automated testing)'));
  content.push(adfParagraph(`\`qa_${buildVersion}\``));
  content.push(adfInlineCard(`${GITHUB_REPO_URL}/tree/qa_${buildVersion}`));
  content.push(adfParagraph());

  const sections = [
    { label: 'Testing Required', changes: [] },
    { label: 'Regression', changes: [] },
    { label: 'No Testing', changes: [] },
    { label: 'Undetermined', changes: [] },
  ];

  for (const change of changes) {
    const type = change.testingType;
    const section = sections.find(s => s.label === type) || sections.find(s => s.label === 'Undetermined');
    section.changes.push(change);
  }

  let globalIndex = 0;

  for (const section of sections) {
    if (section.changes.length === 0) continue;

    content.push(adfRule());
    content.push(adfHeading(`${section.label} (${section.changes.length})`, 2));
    content.push(adfParagraph());

    section.changes.forEach((change, i) => {
      globalIndex++;

      if (i > 0) {
        content.push(adfRule());
        content.push(adfParagraph());
      }

      content.push(adfBoldParagraph(`${globalIndex}) What changed`));

      if (change.whatChanged) {
        content.push(...markdownToAdf(change.whatChanged));
      }

      if (change.ticketUrl) {
        content.push(adfInlineCard(change.ticketUrl));
      }

      if (change.pullNumber) {
        content.push(adfInlineCard(`${GITHUB_REPO_URL}/pull/${change.pullNumber}`));
      }

      content.push(adfParagraph());

      content.push(adfBoldParagraph('How to test (plus any other areas this change might affect)'));

      if (change.testingSteps) {
        content.push(...markdownToAdf(change.testingSteps));
      }

      content.push(adfParagraph());

      content.push(adfBoldParagraph('Point Developer'));
      content.push(adfParagraph(change.pointDeveloper.name));
      content.push(adfParagraph());
    });
  }

  return content;
}


/**
 * Searches for an existing open QA ticket in the TOTT project matching the build version.
 */
async function findExistingOpenQaTicket(auth, buildVersion) {
  try {
    const label = `roku_qa_${buildVersion}`;
    const jql = `project = TOTT AND labels = "${label}" AND status NOT IN (Done, Released) ORDER BY created DESC`;

    const response = await jiraRequest('GET', '/rest/api/3/search/jql', auth, null, {
      jql,
      maxResults: 1,
      fields: 'key,summary,status'
    });

    if (response.data.issues && response.data.issues.length > 0) {
      const issue = response.data.issues[0];
      log(`Found existing QA ticket: ${issue.key} - ${issue.fields.summary}`);
      return issue;
    }

    log(`No existing open QA ticket found for build "${buildVersion}".`);
    return null;
  } catch (error) {
    log(`Error searching for existing QA tickets: ${error.message}`);
    return null;
  }
}


/**
 * Creates a new QA ticket in the TOTT project.
 */
async function createNewQaTicket(descriptionContent, auth, buildVersion) {
  const versionDotted = buildVersion.replace(/_/g, '.');

  const issueData = {
    fields: {
      project: { id: JIRA_PROJECT_ID },
      summary: `QA Roku ${versionDotted}`,
      description: {
        type: 'doc',
        version: 1,
        content: descriptionContent
      },
      issuetype: { name: 'Story' },
      assignee: { accountId: JIRA_ASSIGNEE_ACCOUNT_ID },
      customfield_10375: { value: 'Chore' },
      customfield_10276: { value: 'Engineering' },
      parent: { key: JIRA_PARENT_EPIC_KEY },
      labels: [`roku_qa_${buildVersion}`]
    }
  };

  try {
    const response = await jiraRequest('POST', '/rest/api/3/issue', auth, issueData);

    logTicketUrl(response.data.key, 'CREATED');
    return response.data;
  } catch (error) {
    logJiraError('create QA ticket', error);
    throw error;
  }
}


/**
 * Fetches the current ADF content array from a Jira ticket's description.
 */
async function fetchTicketDescription(issueKey, auth) {
  try {
    const response = await jiraRequest('GET', `/rest/api/3/issue/${issueKey}`, auth, null, {
      fields: 'description'
    });
    return response.data.fields.description?.content || [];
  } catch (error) {
    log(`Warning: Could not fetch ticket description for ${issueKey}: ${error.message}`);
    return [];
  }
}


/**
 * Extracts the Target Release Date string from existing ADF description content.
 * Looks for a bold "Target Release Date" paragraph followed by a paragraph with the date text.
 */
function extractTargetReleaseDateFromAdf(adfContent) {
  for (let i = 0; i < adfContent.length - 1; i++) {
    const node = adfContent[i];
    if (node.type === 'paragraph' && node.content) {
      const hasBoldTargetDate = node.content.some(c =>
        c.type === 'text' && c.text === 'Target Release Date' &&
        c.marks && c.marks.some(m => m.type === 'strong')
      );
      if (hasBoldTargetDate) {
        const nextNode = adfContent[i + 1];
        if (nextNode && nextNode.type === 'paragraph' && nextNode.content && nextNode.content[0]) {
          return nextNode.content[0].text;
        }
      }
    }
  }
  return null;
}


/**
 * Extracts PR numbers from existing ADF description by finding inlineCard URLs
 * matching the GitHub PR pattern.
 */
function extractExistingPrNumbers(adfContent) {
  const prNumbers = new Set();
  const json = JSON.stringify(adfContent);
  const matches = json.matchAll(/github\.com\/[^/]+\/[^/]+\/pull\/(\d+)/g);
  for (const match of matches) {
    prNumbers.add(match[1]);
  }
  return prNumbers;
}


/**
 * Updates the description of an existing Jira ticket.
 */
async function updateTicketDescription(issueKey, descriptionContent, auth) {
  try {
    const response = await jiraRequest('PUT', `/rest/api/3/issue/${issueKey}`, auth, {
      fields: {
        description: {
          type: 'doc',
          version: 1,
          content: descriptionContent
        }
      }
    });

    log(`Description updated for ticket: ${issueKey}`);
    return response.data;
  } catch (error) {
    logJiraError(`update ticket description for ${issueKey}`, error);
    throw error;
  }
}


/**
 * Adds a timestamped comment to a Jira ticket.
 */
async function addCommentToTicket(issueKey, commentContent, auth) {
  try {
    const response = await jiraRequest('POST', `/rest/api/3/issue/${issueKey}/comment`, auth, {
      body: {
        type: 'doc',
        version: 1,
        content: commentContent
      }
    });

    log(`Comment added to ticket: ${issueKey}`);
    return response.data;
  } catch (error) {
    logJiraError(`add comment to ${issueKey}`, error);
    throw error;
  }
}


/**
 * Updates an existing QA ticket: compares descriptions to find newly added PRs,
 * updates the description, and adds a comment listing only the new changes.
 */
async function updateExistingQaTicket(existingTicket, descriptionContent, currentContent, auth, changes, buildVersion) {
  log(`Updating existing QA ticket: ${existingTicket.key}`);

  if (JSON.stringify(currentContent) === JSON.stringify(descriptionContent)) {
    log('Description unchanged. No update needed.');
    logTicketUrl(existingTicket.key, 'UP TO DATE');
    return existingTicket;
  }

  const existingPrNumbers = extractExistingPrNumbers(currentContent);
  const newChanges = changes.filter(c => !existingPrNumbers.has(String(c.pullNumber)));

  log('Description has changed. Updating ticket...');
  await updateTicketDescription(existingTicket.key, descriptionContent, auth);

  const versionDotted = buildVersion.replace(/_/g, '.');
  const date = new Date();
  const dateStr = `${date.toLocaleDateString('en-US')} at ${date.toLocaleTimeString('en-US')}`;

  const commentContent = [];
  commentContent.push(adfBoldParagraph(`Published new build ${versionDotted} - ${dateStr}`));

  if (newChanges.length > 0) {
    commentContent.push(adfParagraph(`${newChanges.length} new change(s) added:`));
    newChanges.forEach((change, i) => {
      const devName = change.pointDeveloper ? ` — ${change.pointDeveloper.name}` : '';
      commentContent.push(adfParagraph(`${i + 1}. ${change.whatChanged}${devName}`));
    });
  } else {
    commentContent.push(adfParagraph('Description updated (no new PRs added).'));
  }

  await addCommentToTicket(existingTicket.key, commentContent, auth);
  logTicketUrl(existingTicket.key, 'UPDATED');

  return existingTicket;
}


/**
 * Main orchestrator: creates or updates a QA Jira ticket from buildQaChanges() output.
 *
 * @param {Array} changes - The qaChangesData array from buildQaChanges()
 * @returns {Promise<Object|void>} The created or updated ticket, or void if env vars missing
 */
async function createOrUpdateQaTicket(changes) {
  const JIRA_TOKEN = process.env.JIRA_TOKEN;
  const JIRA_EMAIL = process.env.JIRA_EMAIL;

  if (!JIRA_TOKEN || !JIRA_EMAIL) {
    log('JIRA_TOKEN and JIRA_EMAIL environment variables are required for QA ticket creation. Skipping.');
    return;
  }

  if (!changes || changes.length === 0) {
    log('No QA changes to create a ticket for. Skipping.');
    return;
  }

  const auth = Buffer.from(`${JIRA_EMAIL}:${JIRA_TOKEN}`).toString('base64');
  const minorVersion = getBuildTag('minor');
  const buildVersion = getBuildTag('build');

  const existingTicket = await findExistingOpenQaTicket(auth, buildVersion);

  let existingTargetDate = null;
  let currentContent = [];
  if (existingTicket) {
    currentContent = await fetchTicketDescription(existingTicket.key, auth);
    existingTargetDate = extractTargetReleaseDateFromAdf(currentContent);
  }

  const descriptionContent = buildQaTicketDescription(changes, minorVersion, buildVersion, existingTargetDate);

  if (existingTicket) {
    return await updateExistingQaTicket(existingTicket, descriptionContent, currentContent, auth, changes, buildVersion);
  } else {
    return await createNewQaTicket(descriptionContent, auth, buildVersion);
  }
}


module.exports = {
  createOrUpdateQaTicket,
  buildQaTicketDescription
};
