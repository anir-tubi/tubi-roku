// @ts-check
const path = require('path');

/**
 * Configuration for test generation system
 */
const config = {
  // Timeouts and intervals
  CLAUDE_TIMEOUT: 600000, // 10 minutes
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
    claudeInstructions: '.claude/instructions.md',
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
  }
};

module.exports = config;
