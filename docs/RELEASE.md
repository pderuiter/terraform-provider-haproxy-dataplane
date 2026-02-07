# Release & Versioning

This provider uses automated Semantic Versioning with Git tags created on every commit to `main`.

## How versions are computed
The auto-tag workflow inspects commit messages since the last tag and determines the bump:

- **Major**: commit message contains `BREAKING CHANGE` or `!:` (for example `feat!: ...`)
- **Minor**: commit subject matches `feat:` or `feat(scope):`
- **Patch**: any other change

If no tags exist, the workflow starts with `v0.1.0`.

## Requirements
- Commit messages should follow Conventional Commits to get the expected bump behavior.
- Tags are created in Gitea and mirrored to GitHub via the mirror workflow.

## Terraform Registry
The Terraform Registry consumes SemVer tags (e.g. `v1.2.3`).
These tags are pushed automatically by the `Auto Tag (SemVer)` workflow.

## Notes
- If the head commit already has a tag, the workflow skips.
- If the computed tag already exists, the workflow skips.
