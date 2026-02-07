# VCS Mirroring (GitHub + Gitea)

This repository is designed to be mirrored to both GitHub and Gitea.

## Option A: Dual-Remote Push (Local)

```bash
git remote add github git@github.com:ORG/terraform-provider-haproxy-dataplane.git
git remote add gitea git@gitea.example.com:ORG/terraform-provider-haproxy-dataplane.git

git push github main --tags
git push gitea main --tags
```

## Option B: GitHub Actions Mirror to Gitea

1. Create a deploy key or bot user on Gitea with write access to the repo.
2. Store the private key in GitHub as `GITEA_SSH_KEY` and the host in `GITEA_HOST`.
3. Add a workflow step to push to Gitea on `main` and tags.

Sample snippet:

```yaml
- name: Mirror to Gitea
  if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
  run: |
    mkdir -p ~/.ssh
    echo "$GITEA_SSH_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    ssh-keyscan -t rsa $GITEA_HOST >> ~/.ssh/known_hosts
    git remote add gitea git@$GITEA_HOST:ORG/terraform-provider-haproxy-dataplane.git
    git push gitea HEAD:main --tags
  env:
    GITEA_SSH_KEY: ${{ secrets.GITEA_SSH_KEY }}
    GITEA_HOST: ${{ secrets.GITEA_HOST }}
```
