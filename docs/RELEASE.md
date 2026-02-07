# Release and Registry

## GitHub Releases

Tag releases with `vX.Y.Z` and push to GitHub. The `release` workflow runs GoReleaser to build the provider artifacts and publish a GitHub Release with checksums.

## Terraform Registry

To publish to the Terraform Registry:

1. Ensure the repository is public on GitHub.
2. Create a GitHub Release with tag `vX.Y.Z` (the workflow does this automatically).
3. Follow the Terraform Registry publisher onboarding for provider verification.

This provider uses standard Terraform provider packaging (zipped binaries + checksums).
