// @ts-check
const path = require('path');

/**
 * Configuration for test generation system
 */
const config = {
  // Timeouts and intervals
  CLAUDE_TIMEOUT: 900000, // 15 minutes (increased for sonnet model with better reliability)
  MAX_LINT_ATTEMPTS: 2,
  MAX_TEST_RETRY_ATTEMPTS: 3,
  PROGRESS_INTERVAL: 2000,
  TIMEOUT_WARNING: 10000,

  // Paths
  paths: {
    projectRoot: path.resolve(__dirname, '..'),
    testsDir: 'js/automated-tests/tests',
    configDir: 'automated-tests-config',
    claudeDir: '.claude',
    learnedFixes: 'ai-automation/learned-fixes.md'
  },

  // Regex patterns
  patterns: {
    DESCRIBE_DECLARATION: /describe\(['"]([^'"]+)['"]/,
    IT_BLOCK_START: /^it(?:\.only)?\s*\(/,
    CLOSING_BRACE: /^\}\);?\s*(\/\/.*)?$/,
    TEST_RAIL_COMMENT: /\/\/.*Test Rail Link/i,
    TEST_CASE_ID: /^(C\d+)/,
    MARKDOWN_CODE_BLOCK: /^```(?:typescript|ts)\n?/gm,
    CLOSING_CODE_BLOCK: /\n?```$/gm
  },

  // Error categories that should be auto-fixed by AI
  fixableErrorTypes: [
    'EMPTY_STRING',
    'VISIBILITY',
    'UNDEFINED',
    'TIMEOUT',
    'FOCUS',
    'GRID_CONTENT',
    'PLAYER_STATE',
    'NAVIGATION'
  ],

  // Keywords for matching describe blocks
  describeMatchers: {
    movie: ['movie', 'movies'],
    series: ['series', 'tv', 'show', 'shows'],
    details: ['detail', 'details']
  },

  // LLM configuration
  llm: {
    // Enable LLM features (set to false to use legacy regex/keyword approaches)
    enabled: true,
    // Skip Claude workspace trust prompts (recommended for automation)
    // Set to false if running in untrusted directories
    skipPermissions: true,
    // Feature-specific toggles
    features: {
      errorCategorization: true, // LLM for error categorization
      userTypeDetermination: true // LLM for user type
    }
  }
};

module.exports = config;
