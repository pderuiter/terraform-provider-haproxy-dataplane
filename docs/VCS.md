# VCS Mirroring (Gitea Primary -> GitHub Mirror)

Gitea is the source of truth. GitHub is a read-only mirror.

## Gitea Actions Mirror (Recommended)

Create a GitHub personal access token with repo write access and store it as a Gitea secret named `GITHUBTOKEN`.

Create `.gitea/workflows/mirror_github.yml` (already included in this repo). It runs on every push to `main` and every tag, and mirrors the `main` branch and all tags to GitHub.

The workflow uses the following URL:

```
https://x-access-token:${GITHUB_TOKEN}@github.com/pderuiter/terraform-provider-haproxy-dataplane.git
```

Notes:
- Use a fine-grained or classic PAT with repo write permissions.
- If you need to mirror only specific branches, adjust the workflow `on.push.branches` list.

## Local One-Off Mirror

```bash
git remote add github git@github.com:pderuiter/terraform-provider-haproxy-dataplane.git
git push --prune github "refs/heads/*:refs/heads/*"
git push --prune github "refs/tags/*:refs/tags/*"
```
