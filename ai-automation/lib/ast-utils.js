// @ts-check

/**
 * Utility for tracking brace depth in code
 */
class BraceTracker {
  constructor() {
    this.depth = 0;
  }

  /**
   * Process a line of code and update brace depth
   * @param {string} line
   */
  processLine(line) {
    for (const char of line) {
      if (char === '{') this.depth++;
      if (char === '}') this.depth--;
    }
  }

  /**
   * Check if braces are balanced (depth is 0)
   * @returns {boolean}
   */
  isBalanced() {
    return this.depth === 0;
  }

  /**
   * Get current depth
   * @returns {number}
   */
  getDepth() {
    return this.depth;
  }

  /**
   * Reset depth to 0
   */
  reset() {
    this.depth = 0;
  }
}

/**
 * Find describe blocks in file content
 * @param {string} fileContent - The file content
 * @param {RegExp} describePattern - Pattern to match describe declarations
 * @returns {Array<{name: string, startLine: number, endLine: number, level: number}>}
 */
function parseDescribeBlocks(fileContent, describePattern) {
  const lines = fileContent.split('\n');
  const describeBlocks = [];
  const describeStack = [];
  let globalBraceDepth = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    // Match describe declarations
    const describeMatch = trimmedLine.match(describePattern);
    if (describeMatch) {
      describeStack.push({
        name: describeMatch[1],
        startLine: i,
        level: describeStack.length,
        braceDepthAtStart: globalBraceDepth
      });
    }

    // Count braces in this line
    for (const char of line) {
      if (char === '{') globalBraceDepth++;
      if (char === '}') globalBraceDepth--;
    }

    // Check if we've closed a describe block
    if (trimmedLine.match(/^\}\);?\s*(\/\/.*)?$/) && describeStack.length > 0) {
      const topDescribe = describeStack[describeStack.length - 1];
      // Check if this closing brace matches the describe's opening depth
      if (globalBraceDepth === topDescribe.braceDepthAtStart) {
        const describe = { ...describeStack.pop(), endLine: i };
        describeBlocks.push(describe);
      }
    }
  }

  return { describeBlocks, unclosedDescribes: describeStack };
}

/**
 * Find all it() blocks within a range of lines
 * @param {string[]} lines - Array of file lines
 * @param {number} startLine - Start line index
 * @param {number} endLine - End line index
 * @param {RegExp} itPattern - Pattern to match it() declarations
 * @returns {Array<{startLine: number, endLine: number}>}
 */
function findItBlocks(lines, startLine, endLine, itPattern) {
  const itBlocks = [];
  let braceCount = 0;
  let inItBlock = false;
  let currentItStart = -1;

  for (let i = startLine + 1; i < endLine; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    // Detect start of an it() block
    if (trimmedLine.match(itPattern)) {
      inItBlock = true;
      currentItStart = i;
      braceCount = 0;
    }

    if (inItBlock) {
      // Count braces
      for (const char of line) {
        if (char === '{') braceCount++;
        if (char === '}') braceCount--;
      }

      // Check if this line closes the it() block
      if (braceCount === 0 && trimmedLine.match(/\}\);?\s*(\/\/.*)?$/)) {
        itBlocks.push({ startLine: currentItStart, endLine: i });
        inItBlock = false;
      }
    }
  }

  return itBlocks;
}

/**
 * Calculate byte position from line number
 * @param {string[]} lines - Array of file lines
 * @param {number} lineNumber - Line number (0-indexed)
 * @returns {number} Byte position
 */
function calculateBytePosition(lines, lineNumber) {
  let position = 0;
  for (let i = 0; i <= lineNumber && i < lines.length; i++) {
    position += lines[i].length + 1; // +1 for newline
  }
  return position;
}

/**
 * Extract code block using brace counting
 * @param {string[]} lines - Array of file lines
 * @param {number} startLine - Starting line index
 * @param {RegExp} closingPattern - Pattern to match closing line
 * @returns {{endLine: number, lines: string[]} | null}
 */
function extractBracedBlock(lines, startLine, closingPattern) {
  let braceCount = 0;
  let foundOpeningBrace = false;

  for (let i = startLine; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    // Count braces
    for (const char of line) {
      if (char === '{') {
        braceCount++;
        foundOpeningBrace = true;
      }
      if (char === '}') braceCount--;
    }

    // Check if this line closes the block
    if (foundOpeningBrace && braceCount === 0 && trimmedLine.match(closingPattern)) {
      return {
        endLine: i,
        lines: lines.slice(startLine, i + 1)
      };
    }
  }

  return null;
}

module.exports = {
  BraceTracker,
  parseDescribeBlocks,
  findItBlocks,
  calculateBytePosition,
  extractBracedBlock
};
