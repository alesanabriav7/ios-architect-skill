# Contributing to ios-architect-skill

- Code examples live only in `ios-architect/templates/`. Don't paste Swift into `SKILL.md` or `references/`; point to the file instead.
- Every change under `templates/` must pass `ios-architect/scripts/verify-templates.sh`. A test only counts if it fails when you break the behavior it guards.
- A guardrail belongs in the skill only if models get it wrong without it, and it's stated once, in the reference for its area.
- Keep `SKILL.md` a map: when to use it, what the existing repo overrides, where the code is, and how to prove the result.
- Evals are behavioral: a fresh agent does the task with the skill, and the result is built and tested. Record runs in `ios-architect/evals/README.md`.
