## Agent skills

### Issue tracker

GitHub Issues in this repo, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Pull requests

See `docs/agents/pull-requests.md` for the PR body template: summary with pseudocode and Mermaid diagrams, evidence, and merge danger.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Workflow

- **Branches:** all work happens on a feature branch. Changes reach `main` only through a merge from that branch. Never commit directly to `main`.
- **Questions:** when you need information from the user, use the question tool rather than asking in plain text.
