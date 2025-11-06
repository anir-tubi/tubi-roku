// @ts-check

/**
 * Logging utility with consistent formatting
 */
class Logger {
  constructor(options = {}) {
    this.debugMode = options.debug || process.env.DEBUG === 'true';
  }

  info(message) {
    console.log('ℹ️ ', message);
  }

  success(message) {
    console.log('✅', message);
  }

  warning(message) {
    console.log('⚠️ ', message);
  }

  error(message) {
    console.error('❌', message);
  }

  debug(message) {
    if (this.debugMode) {
      console.log('🔍', message);
    }
  }

  section(title) {
    console.log('\n' + '='.repeat(60));
    console.log(title);
    console.log('='.repeat(60));
  }

  subsection(title) {
    console.log('\n' + '─'.repeat(60));
    console.log(title);
    console.log('─'.repeat(60));
  }

  separator() {
    console.log('━'.repeat(60));
  }

  progress(message) {
    console.log('⏳', message);
  }

  robot(message) {
    console.log('🤖', message);
  }

  file(message) {
    console.log('📁', message);
  }

  search(message) {
    console.log('🔍', message);
  }

  checkmark(message) {
    console.log('  ✓', message);
  }

  bullet(message) {
    console.log('  •', message);
  }

  /**
   * Log an error with full details in a bordered box
   */
  errorBox(title, content) {
    console.log('\n' + title + '\n');
    this.separator();
    console.log(content);
    this.separator();
    console.log('');
  }

  /**
   * Log extraction details
   */
  extraction(lines, firstLine, lastLine) {
    console.log(`📝 Extracted it() block (${lines} lines):`);
    console.log('   First line:', firstLine.substring(0, 80));
    console.log('   Last line:', lastLine.substring(0, 80));
  }
}

// Export singleton instance
module.exports = new Logger();
