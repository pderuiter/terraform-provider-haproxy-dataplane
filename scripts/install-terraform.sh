#!/usr/bin/env bash
# Install a pinned Terraform CLI into $TF_INSTALL_DIR (default .cache/bin),
# verified against HashiCorp's SHA256SUMS. Prints the binary path.
#
#   TF_VERSION=1.17.1 scripts/install-terraform.sh
set -euo pipefail

: "${TF_VERSION:?set TF_VERSION, e.g. 1.17.1}"
TF_INSTALL_DIR="${TF_INSTALL_DIR:-.cache/bin}"
TF_DOWNLOAD_BASE="${TF_DOWNLOAD_BASE:-https://releases.hashicorp.com/terraform}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) echo "unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

dest="${TF_INSTALL_DIR}/terraform-${TF_VERSION}"
if [ ! -x "${dest}" ]; then
  mkdir -p "${TF_INSTALL_DIR}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  zip="terraform_${TF_VERSION}_${os}_${arch}.zip"
  curl -fsSL -o "${tmp}/${zip}" "${TF_DOWNLOAD_BASE}/${TF_VERSION}/${zip}"
  curl -fsSL -o "${tmp}/SHA256SUMS" "${TF_DOWNLOAD_BASE}/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
  want=$(grep " ${zip}\$" "${tmp}/SHA256SUMS" | awk '{print $1}')
  if command -v sha256sum >/dev/null; then
    got=$(sha256sum "${tmp}/${zip}" | awk '{print $1}')
  else
    got=$(shasum -a 256 "${tmp}/${zip}" | awk '{print $1}')
  fi
  if [ -z "${want}" ] || [ "${want}" != "${got}" ]; then
    echo "checksum mismatch for ${zip}" >&2
    exit 1
  fi
  unzip -q -o "${tmp}/${zip}" terraform -d "${tmp}"
  mv "${tmp}/terraform" "${dest}"
  chmod +x "${dest}"
fi
ln -sf "terraform-${TF_VERSION}" "${TF_INSTALL_DIR}/terraform"
echo "$(cd "${TF_INSTALL_DIR}" && pwd)/terraform-${TF_VERSION}"
