# Pull requests

How to write PR bodies for this repo.

## Template

Use these sections, in this order:

- **Summary**: the smallest view that makes the change clear. Use:
  - a file tree for file responsibilities
  - pseudocode for logic or control flow
  - a Mermaid flowchart or sequence diagram for flows that cross components, following `docs/how-it-works.md`
- **Evidence**: before and after. Test output and console output count. Name the exact test that now fails and passes.
- **Merge Danger**: one-way or two-way door, and blast radius. Changes that delete data, rewrite history, or change what is shipped are one-way doors.

Keep prose brief. Use the domain terms from `CONTEXT.md`.

## Closing issues

End the body with `Closes #N` for the ticket it completes.
