---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
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

## Outline

### Step 0: Select Spec Folder

1. Run `{LIST_SCRIPT}` from repo root to get available spec folders
2. Parse the FOLDERS array from JSON response
3. If empty: Report "No spec folders available for implementation" and exit
4. If user provided a folder name as argument ($ARGUMENTS), use that folder
5. Otherwise, display folders to user in a numbered list and ask which one to implement:

   ```text
   Available spec folders:
     1. 001-user-auth
     2. 002-payment-integration
     3. 003-dashboard-analytics

   Which folder would you like to implement? (Enter number or folder name)
   ```

6. Once folder is selected, run `{START_SCRIPT} --folder <selected-folder>` to create/checkout the git branch
7. Parse BRANCH_NAME and FEATURE_DIR from response

### Step 1: Validate Prerequisites

Run `{PREREQ_SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### Step 2: Check Checklists Status

(if FEATURE_DIR/checklists/ exists):
- Scan all checklist files in the checklists/ directory
- For each checklist, count:
  - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
  - Completed items: Lines matching `- [X]` or `- [x]`
  - Incomplete items: Lines matching `- [ ]`
- Create a status table:

  ```text
  | Checklist | Total | Completed | Incomplete | Status |
  |-----------|-------|-----------|------------|--------|
  | ux.md     | 12    | 12        | 0          | ✓ PASS |
  | test.md   | 8     | 5         | 3          | ✗ FAIL |
  | security.md | 6   | 6         | 0          | ✓ PASS |
  ```

- Calculate overall status:
  - **PASS**: All checklists have 0 incomplete items
  - **FAIL**: One or more checklists have incomplete items

- **If any checklist is incomplete**:
  - Display the table with incomplete item counts
  - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
  - Wait for user response before continuing
  - If user says "no" or "wait" or "stop", halt execution
  - If user says "yes" or "proceed" or "continue", proceed to step 3

- **If all checklists are complete**:
  - Display the table showing all checklists passed
  - Automatically proceed to step 3

### Step 3: Load Implementation Context

- **REQUIRED**: Read tasks.md for the complete task list and execution plan
- **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
- **IF EXISTS**: Read data-model.md for entities and relationships
- **IF EXISTS**: Read contracts/ for API specifications and test requirements
- **IF EXISTS**: Read research.md for technical decisions and constraints
- **IF EXISTS**: Read quickstart.md for integration scenarios

### Step 4: Project Setup Verification

- **REQUIRED**: Create/verify ignore files based on actual project setup:

**Detection & Creation Logic**:
- Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

  ```sh
  git rev-parse --git-dir 2>/dev/null
  ```

- Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
- Check if .eslintrc* exists → create/verify .eslintignore
- Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
- Check if .prettierrc* exists → create/verify .prettierignore
- Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
- Check if terraform files (*.tf) exist → create/verify .terraformignore
- Check if .helmignore needed (helm charts present) → create/verify .helmignore

**If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
**If ignore file missing**: Create with full pattern set for detected technology

**Common Patterns by Technology** (from plan.md tech stack):
- **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
- **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
- **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
- **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
- **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
- **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
- **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
- **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
- **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
- **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
- **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
- **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
- **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
- **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

**Tool-Specific Patterns**:
- **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
- **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
- **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
- **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

### Step 5: Parse Task Structure

Parse tasks.md structure and extract:
- **Task phases**: Setup, Tests, Core, Integration, Polish
- **Task dependencies**: Sequential vs parallel execution rules
- **Task details**: ID, description, file paths, parallel markers [P]
- **Execution flow**: Order and dependency requirements

### Step 6: Execute Implementation

**⚠️ CRITICAL: CONTINUOUS EXECUTION**
- **Do NOT pause or ask for user confirmation between phases or checkpoints**
- **Execute ALL tasks continuously until completion or failure**
- **Only stop if a blocking error occurs that prevents further progress**

Execute implementation following the task plan:
- **Phase-by-phase execution**: Complete each phase before moving to the next
- **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
- **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
- **File-based coordination**: Tasks affecting the same files must run sequentially
- **Checkpoint commits**: After completing each phase/checkpoint, commit changes to keep commits small and focused (see Step 6a below)

Implementation execution rules:
- **Setup first**: Initialize project structure, dependencies, configuration
- **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
- **Core development**: Implement models, services, CLI commands, endpoints
- **Integration work**: Database connections, middleware, logging, external services
- **Polish and validation**: Unit tests, performance optimization, documentation

#### Step 6a: Checkpoint Commits

After completing each phase (Setup, Foundational, each User Story, Polish), create a checkpoint commit:

1. **Stage changes for this phase**:
   ```bash
   git add -A
   ```

2. **Commit with phase-specific message**:
   ```bash
   git commit -m "feat(<folder-name>): complete <phase-name>

   Completed tasks: <list of task IDs completed in this phase>

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**Note**: Do NOT push after checkpoint commits. Continue immediately to the next phase. Push only happens at the end (Step 9).

### Step 7: Progress Tracking and Error Handling

- Report progress after each completed task (do NOT wait for user acknowledgment)
- Halt execution only if a blocking error occurs that prevents further progress
- For parallel tasks [P], continue with successful tasks, report failed ones
- Provide clear error messages with context for debugging
- If a task fails but other tasks can continue, note the failure and proceed
- **IMPORTANT**: For completed tasks, mark the task off as [X] in the tasks file immediately

### Step 8: Completion Validation

- Verify all required tasks are completed
- Check that implemented features match the original specification
- Validate that tests pass and coverage meets requirements
- Confirm the implementation follows the technical plan

### Step 9: Final Commit and Push

After all phases are complete, commit any remaining changes and push everything to remote:

1. **Stage any remaining changes**:
   ```bash
   git add -A
   ```

2. **Commit remaining changes (if any)**:
   ```bash
   git commit -m "feat(<folder-name>): complete implementation

   Completed all tasks from specs/<folder-name>/tasks.md

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```
   (Skip if nothing to commit - checkpoint commits may have captured everything)

3. **Push all commits to remote**:
   ```bash
   git push -u origin <branch-name>
   ```

**If push fails**: Retry once. If still failing, warn user that changes are committed locally but not pushed.

**Note**: Checkpoint commits from Step 6a are now pushed along with any final commit. This keeps individual commits small and focused.

### Step 10: Mark Completion Status

After commit and push:

**If all tasks completed successfully:**
1. Run `{MARK_SCRIPT} --folder <folder-name> --status DONE`
2. Report: "Implementation complete! Folder marked as DONE-<folder-name>"

**If any task failed:**
1. Run `{MARK_SCRIPT} --folder <folder-name> --status FAILED`
2. Report: "Implementation incomplete. Folder marked as FAILED-<folder-name>"
3. List the failed tasks and suggested next steps

Report final status with:
- Summary of completed work
- Branch name for reference
- Remote URL (if pushed successfully)
- New folder name (with DONE- or FAILED- prefix)

---

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/rr.tasks` first to regenerate the task list.
