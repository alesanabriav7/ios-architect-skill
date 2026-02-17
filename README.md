# ios-architect

A reusable AI skill for scaffolding iOS apps and features following Clean Architecture with SwiftUI, GRDB, Swift Concurrency, and optional Apple Foundation Models integration.

Works with **Claude Code**, **Codex**, and **Gemini**.

## Install

### Claude Code

```bash
# Install as a folder so relative references resolve
mkdir -p ~/.claude/skills/ios-architect
ln -s ~/dev/ios-architect-skill/SKILL.md ~/.claude/skills/ios-architect/SKILL.md
ln -s ~/dev/ios-architect-skill/references ~/.claude/skills/ios-architect/references
```

Or add to a project's `.claude/skills/` directory.

### Codex / Gemini

Copy or symlink `SKILL.md` and `references/` into your skills directory. `SKILL.md` now loads only task-specific references for token efficiency.

## Validate

```bash
python3 /Users/ale/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
```

## Usage

Tell your AI assistant:

> Use the ios-architect skill. I want to build a new app called BudgetTracker.

Or for a new feature in an existing project:

> Use the ios-architect skill. I need a new Subscriptions feature with title, amount, billing cycle, and next billing date.

For on-device AI integration:

> Use the ios-architect skill. Add AI-generated insights to an existing feature with FoundationModels and a deterministic fallback.

For iOS 26+ Liquid Glass adoption:

> Use the ios-architect skill. Add Liquid Glass styling to key finance dashboard surfaces with iOS version-gated fallbacks for earlier versions.
