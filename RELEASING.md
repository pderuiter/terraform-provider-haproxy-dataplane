# Releasing

Releases are fully automated: merge to `main`, and the pipeline tags, builds,
signs, stores and publishes. Everything is built and signed on our own GitLab
runners. Nexus holds the copy of record; GitHub only receives a copy of those
exact files, because the Terraform Registry ingests GitHub releases.

```
MR merged to main
  └─ main pipeline: tests ─┬─ mirror:github   main → github.com/pderuiter/terraform-provider-haproxy-dataplane
                           └─ release:tag     vX.Y.Z from Conventional Commits (ci-cd-toolkit)
tag pipeline (vX.Y.Z)
  └─ tests ── build:release   GoReleaser (build only): zips, SHA256SUMS, manifest
               ├─ sign:gpg     SHA256SUMS.sig (Registry key, from Vault)
               └─ sign:cosign  *.sigstore.json (estate cosign key, Vault transit)
             publish:nexus     → nexus.bsdserver.nl/repository/terraform-providers/pderuiter/haproxy-dataplane/<version>/
             publish:github    fetch from Nexus, verify checksums + signature, mirror tag,
                               draft release + assets → publish (Registry ingests it), GitLab release
             verify:registry   terraform init from registry.terraform.io (signature checked)
```

The GitHub release is created as a draft and only published once every asset
is uploaded, so the Registry never ingests a partial release.

## Versions

Semantic Versioning, computed by the toolkit's `release:tag` from the commits
since the last tag:

| Commits contain                                   | Bump  |
|---------------------------------------------------|-------|
| `type!:` / `type(scope)!:` or `BREAKING CHANGE:`  | major |
| `feat:` / `feat(scope):`                          | minor |
| anything else                                     | patch |

Breaking changes for a provider: removing or renaming a resource, data source
or attribute; making an optional attribute required; changing a default;
anything that makes an existing configuration plan a replacement. While on
0.x these still get a `!` so the changelog says so. Add upgrade notes to
`CHANGELOG.md` in the same MR.

Deprecate before removing: mark the attribute `DeprecationMessage` in one minor
release, remove it in the next major.

### Manual or pre-release tags

The release jobs accept any `vX.Y.Z` or `vX.Y.Z-pre` tag pushed by a maintainer
(protected tags). Pre-releases become GitHub pre-releases; users only get them
by pinning the exact version.

## Published versions are immutable

The Registry stores each version's checksums and users lock them in
`.terraform.lock.hcl`. Never delete and re-push a tag or edit a GitHub release's
assets. The Nexus repository is `ALLOW_ONCE`, `publish:nexus` fails when a
stored file differs from a rebuild, `publish:github` refuses to overwrite a tag
that GitHub has at another commit and never edits a published release. A
broken release gets fixed by the next patch version.

If a release must be pulled: delete the version in the Registry (provider
settings → versions); leave the tag.

## Secrets and access

| What                       | Where                                                 |
|----------------------------|-------------------------------------------------------|
| GPG signing key            | Vault `secret/wbyc/prd/infra/terraform-registry/gpg`: `private_key` (ASCII-armoured), `passphrase`, `public_key` (reference copy; CI checks against the committed `.asc`, not this) |
| GitHub token               | Vault `secret/wbyc/prd/infra/github/pderuiter`: `token` (shared by every provider repository; adopted by terragrunt-live prd/security/vault-management) |
| Nexus upload               | Vault `secret/prod/nexus/ci-publish` (service account `ci-publish`, managed by prd/infra/nexus-security) |
| cosign                     | Vault transit key `cosign-estate` (never leaves Vault) |
| Vault login                | JWT role `gitlab-ci-terraform-registry` (`RELEASE_VAULT_ROLE`), bound to this project's protected refs |
| Tag push                   | group access token `PROJECT_ACCESS_TOKEN` on wbyc/infra/iac/terraform |

The shared `gitlab-ci` Vault policy explicitly denies
`secret/wbyc/prd/infra/terraform-registry/*` and `secret/wbyc/prd/infra/github/*`:
only the release role can read the signing key and the GitHub token, and only
from protected refs of the provider projects.

The GitHub token is a fine-grained PAT of `pderuiter` limited to the provider
repositories (`terraform-provider-listmonk`, `terraform-provider-haproxy-dataplane`)
with *Contents: read and write* (push, releases) and *Metadata: read*. A new
provider is added to that token's repository list, not given its own token.
GitHub Actions are not used: the repository has no workflows.

The signing key must be RSA or DSA (Registry requirement) and its public half
registered at registry.terraform.io → pderuiter → Settings → Signing Keys. The
current key is `10A2F1058821D55C61E45C7EE97C02FEE2F51B23` (RSA 4096,
sign-only, expires 2029-11-12). It was generated straight into Vault with a
random passphrase and exists nowhere else. Its public half is committed as
`scripts/terraform-registry-signing-key.asc`, and `sign:gpg` refuses any other
key. The earlier namespace key `39C79E837DDFE751922F831CE991293E4A761E2B`
signed this provider's releases up to v0.1.20 (see History) and stays
registered for them, but its passphrase is lost, so nothing new can be signed
with it.

### Rotating the GPG key

1. Generate an RSA 4096 key, add the public key to the Registry namespace
   **before** the first release signed with it (keep the old key listed: old
   versions stay signed with it).
2. Replace `scripts/terraform-registry-signing-key.asc` with the new public
   key (MR) and the fields in Vault.
3. The next release is signed with the new key; `verify:registry` confirms the
   Registry accepts it. The key expires 2029-11-12: rotate (or extend the
   expiry and re-register) well before.

## One-time setup (done when the project was created)

1. GitHub: public repo `pderuiter/terraform-provider-haproxy-dataplane`, no branch
   protection that blocks the mirror; issues on, PRs answered with a pointer to
   GitLab.
2. Registry: registry.terraform.io → Publish → Provider → that repo. The
   Registry then picks up every published GitHub release.
3. GitLab: project under wbyc/infra/iac/terraform (inherits
   `PROJECT_ACCESS_TOKEN`), `main` and `v*` tags protected.
4. Nexus: raw repository `terraform-providers` (ALLOW_ONCE) and the
   `ci-publish` upload grant, in terragrunt-live prd/infra/nexus-repositories
   and prd/infra/nexus-security.
5. Vault: secrets above; policy and JWT role in terragrunt-live
   prd/security/vault-terraform-policy and prd/security/vault-jwt-auth (this
   project is 104 in the role's `project_id`).
6. gitlab-config: 104 in `signing_project_ids` (Maintainer-only merge to
   `main`, renovate-bot Maintainer).

## When the Registry does not show a release

`verify:registry` fails after 15 minutes. Check, in order: the GitHub release
has all assets (`_SHA256SUMS`, `.sig`, `_manifest.json`, zips); then
**Resync** on the provider's Registry settings page. A signature error in
the Registry means the key in Vault is not one registered for the namespace.

## History

Before this pipeline, releases were built by GitHub Actions on the GitHub
repository, from tags created and mirrored by Gitea Actions (last run
2026-02-08); GoReleaser signed them there with key `39C79E83...`. The last release made that way, and the latest on the
Registry, is v0.1.20. v0.1.21 exists only as a GitLab tag: it was never
mirrored to GitHub, so it has no release, and it is not rebuilt (tags are
immutable). The first release built by this pipeline is the next one after
v0.1.21, signed with the current key. Old GitHub releases are left as they are.
