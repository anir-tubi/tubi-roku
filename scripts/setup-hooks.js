#!/usr/bin/env node

/**
 * Automatically configure git hooks to use .githooks directory
 * This runs after npm install to ensure all developers have the pre-commit hook enabled
 * Sets up hooks for both command line and GUI tools like SourceTree
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Check if we're in a git repository
const gitDir = path.join(__dirname, '..', '.git');
if (!fs.existsSync(gitDir)) {
  process.exit(0);
}

// Check if source hook exists - exit early if not to avoid partial configuration
const sourceHook = path.join(__dirname, '..', '.githooks', 'pre-commit');
if (!fs.existsSync(sourceHook)) {
  process.exit(0);
}

try {
  // Make source hook executable (required for core.hooksPath to work)
  fs.chmodSync(sourceHook, '755');
  
  // Method 1: Configure git to use .githooks directory (for command line and modern tools)
  execSync('git config core.hooksPath .githooks', { stdio: 'pipe' });
  
  // Method 2: Copy hook to standard location (for SourceTree and other GUI tools)
  const hooksDir = path.join(gitDir, 'hooks');
  const targetHook = path.join(hooksDir, 'pre-commit');
  
  // Ensure hooks directory exists
  if (!fs.existsSync(hooksDir)) {
    fs.mkdirSync(hooksDir, { recursive: true });
  }
  
  // Copy the hook file (sourceHook is guaranteed to exist at this point)
  fs.copyFileSync(sourceHook, targetHook);
  
  // Make copy executable as well
  fs.chmodSync(targetHook, '755');
} catch (error) {
  // Silently fail - not critical for package installation
  process.exit(0);
}
