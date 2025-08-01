import { spawnSync } from "child_process"
import { relative } from "path"
import { exit } from "process"

/*
 * Workflow script for enforcing formatting rules defined in `bsfmt.json`
 * on files changed in a Pull Request 
 */


function isBrightscriptFile(line: string) {
    return line.endsWith('.brs') || line.endsWith('.bs')
}

function fetchBranch(branch: string) {
    const fetchHeadResult = spawnSync('git', ['fetch', 'origin', branch])
    if (fetchHeadResult.status != 0) {
        console.error(`Failed to fetch ${branch} branch`)
        console.error(fetchHeadResult.output.toString())
        exit(1)
    }
}

/**
 * Uses the HEAD ref and the target branch to determine all changed files, then runs bsfmt on those files. 
 * If the formatting check fails, we return an error
 */
async function main() {
    const pullRequestRef = process.env.GITHUB_HEAD_REF // branch for the PR
    const target = process.env.GITHUB_BASE_REF // target branch, usually master
    fetchBranch(pullRequestRef)
    fetchBranch(target)

    // logs file path/name only, no commit messages or anything extra
    const logResult = spawnSync('git', ['log', '--name-only', '--pretty=format:', `origin/${pullRequestRef}`, '--not', `origin/${target}`])
    if (logResult.status != 0) {
        console.error('Failed to log changed files')
        console.error(logResult.output.toString())
        exit(1)
    }
    let files = logResult.stdout.toString()
        .trim()
        .split('\n')
        .map(l => l.trim())
        .filter(isBrightscriptFile)
    files = [...new Set(files)]

    if (files.length > 0) {
        const formatResult = spawnSync('npx', ['bsfmt', ...files, '--check'])
        if (formatResult.status != 0) {
            console.log('Formatting check failed on files:')
            console.log(formatResult.stdout.toString().split('\n').filter(isBrightscriptFile).map(l => relative(process.cwd(), l)).join('\n'))
            exit(1)
        }
    } else {
        console.log('No files found for formatting.')
    }
    console.log('Formatting check passed.')
}

main()