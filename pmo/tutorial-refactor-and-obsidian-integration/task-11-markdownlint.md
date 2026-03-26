# Task 11: Fix markdownlint violations across tutorial files

**Workstream**: Tutorial Refactor & Obsidian Integration
**Phase**: 3 — Content Completion
**Status**: todo
**Prerequisites**: task-02 (file renaming should be done first)

---

## Goal

Ensure all files in `tutorial/*.md` pass markdownlint cleanly.

## Context

A `.markdownlint.yaml` config was added at the repo root (2026-03-22) that disables
overly strict rules (line length, code fence language, etc.) and standardises emphasis
style on asterisks. After applying the config, `tutorial/08-network-configuration.md`
is fully clean. Other tutorial files still have pre-existing violations.

## Steps

1. Run the linter across all tutorial files:
   ```bash
   npx markdownlint-cli tutorial/*.md
   ```

2. Fix each reported violation. Common issues in the existing files:
   - Trailing spaces (`MD009`) — already disabled in config, no action needed
   - Trailing newline (`MD047`) — already disabled, no action needed
   - Inline HTML (`MD033`) — already disabled, no action needed
   - Ordered list numbering (`MD029`) — already disabled, no action needed

3. If new violation types appear, evaluate whether to fix in the file or add to
   `.markdownlint.yaml` with a comment explaining why.

4. Verify clean:
   ```bash
   npx markdownlint-cli tutorial/*.md
   # Should produce no output
   ```

## Acceptance criteria

`npx markdownlint-cli tutorial/*.md` exits with no errors.
