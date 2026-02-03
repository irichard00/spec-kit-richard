---
description: Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts.
tools: ['github/github-mcp-server/issue_write']
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Determine Target Spec Folder**:

   a. **Check if folder name provided in user input**:
      - Parse `$ARGUMENTS` for a spec folder name (format: `NNN-feature-name`, e.g., `001-user-auth`)
      - If found, use that folder name and proceed to step 2

   b. **If no folder name provided, list available folders and prompt user**:
      - Run `{SCRIPT} --list-folders --json` to get available spec folders
      - If no folders exist, ERROR: "No spec folders found. Run /rr.specify first to create a feature specification."
      - If exactly one folder exists, use it automatically and inform the user
      - If multiple folders exist, present the list and ask user to specify which one:

        ```markdown
        Multiple spec folders found. Which one would you like to convert to GitHub issues?

        | # | Folder Name |
        |---|-------------|
        | 1 | 001-user-auth |
        | 2 | 002-payment-flow |
        | ... | ... |

        Please reply with the folder name (e.g., `001-user-auth`) or the number.
        ```

      - Wait for user response before proceeding

2. Run `{SCRIPT} --json <folder-name>` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

3. From the executed script, extract the path to **tasks**.

4. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

5. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL
