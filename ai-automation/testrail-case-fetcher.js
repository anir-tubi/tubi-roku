const https = require('https');

// TestRail Configuration
const TESTRAIL_BASE_URL = 'https://tubi.testrail.io';
const API_KEY = process.env.TEST_RAIL_KEY;
const USER_NAME = process.env.TEST_RAIL_USER_NAME;

/**
 * Makes an authenticated request to TestRail API
 */
function makeTestRailRequest(endpoint) {
  return new Promise((resolve, reject) => {
    if (!API_KEY) {
      reject(new Error('❌ TEST_RAIL_KEY environment variable is not set'));
      return;
    }

    if (!USER_NAME) {
      reject(new Error('❌ TEST_RAIL_USER_NAME environment variable is not set'));
      return;
    }

    const url = `${TESTRAIL_BASE_URL}/index.php?/api/v2/${endpoint}`;
    const auth = Buffer.from(`${USER_NAME}:${API_KEY}`).toString('base64');

    const options = {
      hostname: 'tubi.testrail.io',
      port: 443,
      path: `/index.php?/api/v2/${endpoint}`,
      method: 'GET',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
        'User-Agent': 'TestRail API Client'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`❌ HTTP ${res.statusCode}: ${data}`));
          return;
        }

        try {
          const jsonData = JSON.parse(data);
          resolve(jsonData);
        } catch (error) {
          reject(new Error(`❌ Failed to parse JSON response: ${error.message}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`❌ Request failed: ${error.message}`));
    });

    req.end();
  });
}

/**
 * Fetches test case with section information and returns clean object
 */
async function fetchTestCaseWithContext(caseId) {
  try {
    // Convert to string and remove C prefix if present (TestRail API expects numeric ID)
    caseId = String(caseId);
    if (caseId.startsWith('C')) {
      caseId = caseId.substring(1);
    }

    // Fetch test case data
    const caseData = await makeTestRailRequest(`get_case/${caseId}`);

    // Fetch section information with full hierarchy
    let sectionName = null;
    let mainSection = null;
    let subSection = null;

    if (caseData.section_id) {
      try {
        const sectionData = await makeTestRailRequest(`get_section/${caseData.section_id}`);
        sectionName = sectionData.name;

        // Build full hierarchy by fetching parent sections
        let currentSection = sectionData;
        const hierarchy = [currentSection.name];

        while (currentSection.parent_id && currentSection.parent_id !== null) {
          try {
            const parentSection = await makeTestRailRequest(`get_section/${currentSection.parent_id}`);
            hierarchy.unshift(parentSection.name); // Add parent to beginning
            currentSection = parentSection;
          } catch (error) {
            // Stop if we can't fetch parent
            break;
          }
        }

        // Set main section and sub section
        if (hierarchy.length > 1) {
          mainSection = hierarchy[0];
          subSection = hierarchy.slice(1).join(' › ');
        } else {
          mainSection = hierarchy[0];
          subSection = null;
        }

        // Join hierarchy with › separator for backward compatibility
        sectionName = hierarchy.join(' › ');
      } catch (error) {
        // Silently continue if section info can't be fetched
      }
    }

    // Return clean object with essential information
    const result = {
      caseId: caseData.id,
      title: caseData.title,
      link: `https://tubi.testrail.io/index.php?/cases/view/${caseData.id}`,
      testSteps: caseData.custom_steps || null,
      expectedResult: caseData.custom_expected || null,
      preConditions: caseData.custom_preconds || null,
      sectionName: sectionName,
      mainSection: mainSection,
      subSection: subSection
    };

    return result;

  } catch (error) {
    console.error(`❌ Error fetching test case: ${error.message}`);
    throw error;
  }
}


/**
 * Fetches all test cases from a suite or section
 * @param {number} suiteId - TestRail suite ID
 * @param {number} sectionId - Optional section ID to filter cases
 * @param {number} projectId - Optional TestRail project ID (will be fetched from suite if not provided)
 * @returns {Promise<Array>} Array of case objects with id and title
 */
async function fetchCasesFromSuite(suiteId, sectionId = null, projectId = null) {
  try {
    console.log(`📋 Fetching test cases from suite ${suiteId}${sectionId ? ` section ${sectionId}` : ''}...`);

    // If project ID not provided, fetch it from the suite
    if (!projectId) {
      const suiteData = await makeTestRailRequest(`get_suite/${suiteId}`);
      projectId = suiteData.project_id;
      console.log(`   Project ID: ${projectId} (from suite)`);
    }

    // Build endpoint with filters
    let endpoint = `get_cases/${projectId}&suite_id=${suiteId}`;
    if (sectionId) {
      endpoint += `&section_id=${sectionId}`;
    }

    const response = await makeTestRailRequest(endpoint);

    // The API returns an object with a 'cases' array
    if (!response || !response.cases || !Array.isArray(response.cases)) {
      throw new Error('Invalid response from TestRail API');
    }

    const cases = response.cases;
    console.log(`✅ Found ${cases.length} test cases`);

    // Return simplified case objects
    return cases.map(c => ({
      id: c.id,
      title: c.title,
      section_id: c.section_id
    }));

  } catch (error) {
    console.error(`❌ Error fetching cases from suite: ${error.message}`);
    throw error;
  }
}

module.exports = {
  fetchTestCaseWithContext,
  makeTestRailRequest,
  fetchCasesFromSuite
};
