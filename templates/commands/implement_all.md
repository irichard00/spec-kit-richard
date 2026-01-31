---
description: Process all available spec folders sequentially - create branch, implement, commit, push for each
scripts:
  list_sh: scripts/bash/list-spec-folders.sh --json
  list_ps: scripts/powershell/list-spec-folders.ps1 -Json
  start_sh: scripts/bash/start-implementation.sh --json
  start_ps: scripts/powershell/start-implementation.ps1 -Json
  mark_sh: scripts/bash/mark-folder-status.sh --json
  mark_ps: scripts/powershell/mark-folder-status.ps1 -Json
  prereq_sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  prereq_ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

This command processes **ALL** available spec folders in sequence. For each folder it:
1. Creates a feature branch
2. Runs the full implementation workflow
3. Commits all changes
4. Pushes the branch to remote
5. Marks the folder as DONE or FAILED
6. Returns to main branch and continues to the next folder

## Outline

### Step 1: Get Available Folders

1. Run `{LIST_SCRIPT}` from repo root
2. Parse the FOLDERS array from JSON response
3. If empty: Report "No spec folders available for implementation" and exit
4. Display list of folders to process:

   ```text
   Found N spec folders to process:
     1. 001-user-auth
     2. 002-payment-integration
     3. 003-dashboard-analytics
   ```

### Step 2: Confirm Batch Processing

Ask user: "This will process N spec folders sequentially. Each folder will be implemented, committed, and pushed. Continue? (yes/no)"

- If "no": Exit gracefully with message "Batch processing cancelled."
- If "yes": Proceed to Step 3

### Step 3: Save Starting Branch

1. Run `git branch --show-current` to get current branch name
2. Store as STARTING_BRANCH for returning after each folder

### Step 4: Process Each Folder Sequentially

For each folder in FOLDERS array (in order):

#### 4.1: Initialize Implementation

1. Display: "Processing folder N of M: <folder-name>"
2. Run `{START_SCRIPT} --folder <folder>` to create/checkout branch
3. Parse BRANCH_NAME and FEATURE_DIR from response

#### 4.2: Run Implementation Workflow

Execute the full implementation workflow (same as `/rr.implement`):

1. **Validate Prerequisites**: Run `{PREREQ_SCRIPT}` and verify tasks.md exists
2. **Check Checklists**: If checklists/ exists, verify all pass (or ask to continue)
3. **Load Context**: Read tasks.md, plan.md, and other available documents
4. **Project Setup**: Verify/create ignore files
5. **Parse Tasks**: Extract phases, dependencies, and execution order
6. **Execute Tasks**: Run all tasks phase-by-phase
7. **Track Progress**: Mark tasks as [X] when complete

#### 4.3: Handle Completion

**If all tasks completed successfully:**

1. Stage all changes:
   ```bash
   git add -A
   ```

2. Commit with descriptive message:
   ```bash
   git commit -m "feat(<folder-name>): implement <feature-description>

   Implemented all tasks from specs/<folder-name>/tasks.md

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. Push branch to remote:
   ```bash
   git push -u origin <branch-name>
   ```

4. Run `{MARK_SCRIPT} --folder <folder> --status DONE`
5. Log: "✓ <folder-name>: Implementation complete, pushed to origin/<branch-name>"

**If any task failed:**

1. Stage and commit any partial work (if any changes):
   ```bash
   git add -A
   git commit -m "wip(<folder-name>): partial implementation (failed)

   Some tasks failed - see specs/FAILED-<folder-name>/tasks.md for details

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

2. Push the partial work:
   ```bash
   git push -u origin <branch-name>
   ```

3. Run `{MARK_SCRIPT} --folder <folder> --status FAILED`
4. Log: "✗ <folder-name>: Implementation failed"
5. Ask user: "Folder <folder-name> failed. Continue to next folder? (yes/no)"
   - If "no": Report current status and exit batch processing
   - If "yes": Continue to next folder

#### 4.4: Return to Starting Branch

After each folder (success or failure):
```bash
git checkout <STARTING_BRANCH>
```

### Step 5: Final Report

After all folders processed, output summary:

```markdown
## Batch Implementation Complete

| # | Folder | Status | Branch | Pushed |
|---|--------|--------|--------|--------|
| 1 | 001-user-auth | ✓ DONE | 001-user-auth | Yes |
| 2 | 002-payment-integration | ✗ FAILED | 002-payment-integration | Yes |
| 3 | 003-dashboard-analytics | ✓ DONE | 003-dashboard-analytics | Yes |

**Summary:**
- Total folders: 3
- Completed: 2
- Failed: 1

**Next steps for failed folders:**
- 002-payment-integration: Review FAILED-002-payment-integration/tasks.md for incomplete tasks
```

## Error Handling

### Git Errors
- If branch creation fails: Log error, mark as FAILED, ask to continue
- If commit fails: Log error, try to recover, mark as FAILED
- If push fails: Retry once, if still failing mark as FAILED (branch still exists locally)

### Missing Prerequisites
- If tasks.md missing: Skip folder, log "Missing tasks.md - run /rr.tasks first", continue to next

### Network Errors
- If push fails due to network: Retry once after 5 seconds
- If still failing: Mark as FAILED, note "Push failed - branch exists locally"

### User Interruption
- If user requests stop: Complete current folder's commit/push, then exit cleanly
- Report partial progress and remaining folders

## Notes

- Each folder is processed independently - failure of one doesn't affect others
- All branches are pushed to remote, even partial implementations
- The DONE- or FAILED- prefix on folders prevents reprocessing
- To reprocess a failed folder, rename it to remove the FAILED- prefix
