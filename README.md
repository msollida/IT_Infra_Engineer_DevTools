# IT_Infra_Engineer_DevTools
IT Infrastructure engineering development, IaC &amp; CaC tools. Managed by Cloud Delivery


# Standard Operating Procedure: Git & VS Code Workflow

## 1. Purpose & Common Goal
The primary objective of this standard operating procedure (SOP) is to establish a unified, predictable, and resilient workflow for managing stored scripts and application code repositories using Git and Visual Studio Code (VS Code). 

Adhering to these standards ensures:
* **Traceability:** Every change to production scripts or codebase is documented, attributed, and reversible.
* **Consistency:** All team members share identical editor configurations, formatting rules, and branching models.
* **Resilience:** Rapid, standardized failback procedures minimize downtime and data loss when bad code or broken scripts are deployed.

---

## 2. VS Code Standardization
To prevent environment drift ("it works on my machine") and formatting noise in Git diffs, all repositories must include standardized workspace configurations.

### Required Workspace Files
Every repository root must contain a `.vscode/` directory with the following committed files:
* **`.vscode/extensions.json`**: Recommends essential extensions (e.g., `eamodio.gitlens`, linters, language formatters) so VS Code prompts developers to install them upon opening the folder.
* **`.vscode/settings.json`**: Enforces project-level editor behavior:
  * `"editor.formatOnSave": true`
  * `"files.trimTrailingWhitespace": true`
  * `"files.insertFinalNewline": true`
  * `"git.autofetch": true`
  * `"git.confirmSync": false`

### Integrated Git Practices in VS Code
* **Stage Changes Selectively:** Use VS Code's Source Control view (`Ctrl+Shift+G` / `Cmd+Shift+G`) to review diffs line-by-line before staging (`+`). Never blindly stage all files (`git add .`) without reviewing for unintended debug code or local configuration changes.
* **Credential & Secret Hygiene:** Never commit `.env` files, API keys, tokens, or passwords. Maintain an up-to-date `.gitignore` file in every repository root.

---

## 3. Code Repositories & Branching Strategy
We utilize a simplified **Trunk-Based / Feature-Branch** workflow to keep the primary branch deployable at all times.

| Branch Type | Naming Convention | Purpose | Merge Target |
| :--- | :--- | :--- | :--- |
| **Main / Trunk** | `main` | Production-ready, stable code. Direct commits are prohibited. | N/A (Protected) |
| **Feature / Update** | `feat/<ticket-or-topic>` | New functionality or script enhancements. | `main` via Pull Request |
| **Bugfix** | `fix/<ticket-or-topic>` | Non-critical bug fixes. | `main` via Pull Request |
| **Hotfix** | `hotfix/<issue>` | Urgent production fixes requiring immediate deployment. | `main` via expedited PR |

### Commit Message Standard
All commits must follow the **Conventional Commits** specification for automated changelog generation and clear history scanning:
* `feat: add automated backup rotation script`
* `fix: resolve timeout error in API polling loop`
* `docs: update README with environment setup steps`
* `chore: update dependencies and VS Code settings`

---

## 4. Stored Scripts Management
Standalone utility, automation, and operational scripts (e.g., Bash, PowerShell, Python) are treated with the same rigor as full software applications—never edited directly on production servers.

1. **Centralized Storage:** All operational scripts must reside in a dedicated, version-controlled repository (e.g., `ops-scripts` or `automation-tools`), categorized by function or platform.
2. **Header Documentation:** Every script must begin with a standardized comment block detailing:
   * **Purpose:** What the script does.
   * **Author & Date:** Initial creator and last modified date.
   * **Dependencies:** Required runtime versions, modules, or permissions.
   * **Usage Example:** Exact command-line execution syntax.
3. **Idempotency & Dry-Run Support:** Scripts that modify state (databases, file systems, cloud infrastructure) must be idempotent (safe to run multiple times) and should include a `--dry-run` or `-WhatIf` flag where feasible.
4. **Release Tagging:** Production-ready versions of critical scripts must be tagged using Semantic Versioning (e.g., `v1.2.0`) so deployment pipelines pull verified snapshots rather than mutable branch heads.

---

## 5. Failback & Recovery Procedures
When a merged commit or updated script introduces a regression, follow the appropriate failback tier immediately. **Do not attempt to "fix forward" under pressure unless the root cause is trivial and verified.**

### Tier 1: Reverting a Bad Commit (Safe & Preferred)
Use `git revert` when bad code has already been pushed to a shared branch (`main`). This creates a new commit that undoes the changes without rewriting shared history.

1. Identify the offending commit hash via VS Code's **Git Graph / Timeline** view or terminal:
   ```bash
   git log -n 5 --oneline
   ```
2. Execute the revert and push to trigger redeployment:
   ```bash
   git checkout main
   git pull origin main
   git revert <commit-hash> --no-edit
   git push origin main
   ```

### Tier 2: Rolling Back to a Previous Release Tag (Scripts & Releases)
If multiple commits or a recent release break production behavior, roll back the deployment target to the last known good tag.

1. List recent stable tags:
   ```bash
   git tag --sort=-creatordate | head -n 5
   ```
2. Check out the last known good tag into a hotfix/rollback branch or point the deployment runner directly to that tag:
   ```bash
   git checkout -b hotfix/rollback-to-v1.1.0 v1.1.0
   git push -u origin hotfix/rollback-to-v1.1.0
   ```
3. Merge the rollback branch into `main` via an expedited Pull Request.

### Tier 3: Local Workspace Recovery (Unpushed Mistakes)
If a developer makes destructive local changes in VS Code prior to pushing:

* **Discard unstaged file changes:** Right-click the file in VS Code Source Control and select **Discard Changes** (or run `git checkout -- <file>`).
* **Undo the last local commit (keep changes staged):**
  ```bash
  git reset --soft HEAD~1
  ```
* **Recover accidentally deleted commits/branches:** Locate the lost commit hash using `git reflog` and restore it:
  ```bash
  git reflog
  git checkout -b recovery-branch <reflog-hash>
  ```

---

## 6. Post-Incident Review
Following any Tier 1 or Tier 2 production failback:
1. Document the incident, the reverted commit/tag, and the root cause in the repository's issue tracker within 24 hours.
2. Add an automated test, linter rule, or pre-commit check to prevent the same class of error from passing review in the future.
````