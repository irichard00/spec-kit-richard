---
description: Create or update the feature specification and technical implementation plan from a natural language feature description in one unified step.
handoffs: 
  - label: Create Tasks
    agent: rr.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Clarify Spec Requirements
    agent: rr.clarify
    prompt: Clarify specification requirements
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Overview

The `/rr.design` command combines the work of `/rr.specify` (capturing requirements) and `/rr.plan` (designing the technical implementation) into a single, streamlined process. 

## Outline

### Part 1: Specification (The "What")

The text the user typed after `/rr.design` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. 

1. **Generate a concise short name** (2-4 words) for the branch:
   - Analyze the feature description and extract keywords.
   - Use action-noun format when possible (e.g., "add-user-auth").

2. **Check for existing branches before creating new one**:
   a. `git fetch --all --prune`
   b. Find the highest feature number across all sources (remote, local, specs dir) for the short-name.
   c. Determine the next available number N+1.
   d. Run `{SCRIPT}` with `--number N+1` and `--short-name "your-short-name"` along with the feature description. The JSON output will contain `BRANCH_NAME` and `SPEC_FILE`.

3. **Generate the Specification (`spec.md`)**:
    1. Extract key concepts from the description (actors, actions, data, constraints).
    2. Make informed guesses based on context and industry standards for unclear aspects. Mark with `[NEEDS CLARIFICATION]` ONLY if critical. Maximum 3 markers.
    3. Generate User Scenarios & Testing section (P1, P2, P3 independent stories).
    4. Generate testable Functional Requirements.
    5. Define measurable, tech-agnostic Success Criteria.
    6. Identify Key Entities.
    7. Write the specification to `SPEC_FILE` using `templates/spec-template.md`.

### Part 2: Implementation Planning (The "How")

1. **Setup**: The `{SCRIPT}` from Part 1 also initialized the `IMPL_PLAN` file. Read `/memory/constitution.md`. Load `templates/plan-template.md`.

2. **Execute Design & Planning**: 
   - Fill Technical Context in the plan based on the generated spec.
   - Fill Constitution Check section from the constitution.
   - Extract entities from feature spec to define `data-model.md` (if applicable).
   - Generate API contracts (`/contracts/*`) from functional requirements (if applicable).
   - Resolve any major technical unknowns into `research.md`.

3. **Write the Plan**: Write the completed plan structure to `IMPL_PLAN`.

### Part 3: Architecture & Agent Context

1. **Agent Context Update**:
   - Run `{AGENT_SCRIPT}` to update the AI's internal context with the new tech stack.
   - This ensures the AI knows about any newly introduced technologies, DBs, or frameworks before tasks are generated.

### Part 4: Report and Handoff

1. Report completion with: 
    - Folder name
    - Path to `spec.md` and `plan.md`
    - Any critical `[NEEDS CLARIFICATION]` items remaining.
2. Indicate readiness for `/rr.tasks` (or `/rr.clarify` if major questions remain).

**NOTE:** No git branch is created at this stage - use `/rr.implement` to create the branch when ready to implement.

## General Guidelines

- **WHAT** + **HOW**: This command does both. The spec focuses on business value, the plan focuses on code structure.
- **Assumptions**: Make reasonable technical assumptions (e.g., REST API, standard auth) to avoid blocking the workflow, unless the choice drastically changes the architecture. 
- **Efficiency**: Do not run the standalone checklist validation scripts here; rely on your internal quality verification to produce a solid combined design.
