#!/usr/bin/env bash
set -euo pipefail

mkdir -p templates/resources templates/data-sources examples/resources examples/data-sources

# Keep rich hand-written templates for these pages.
KEEP_RESOURCE_TEMPLATES="backend backend_server frontend frontend_bind"
KEEP_DATA_SOURCE_TEMPLATES="backend frontend version"

has_word() {
  local needle="$1"
  shift
  for w in "$@"; do
    if [[ "$w" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

extract_required_attrs() {
  local file="$1"
  awk '
    /## Schema/ {inschema=1; next}
    inschema && /^### Required/ {inreq=1; next}
    inreq && /^### / {inreq=0}
    inreq && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/`.*/, "", line)
      print line
    }
  ' "$file"
}

write_resource_example() {
  local slug="$1"
  local out="$2"
  local req_file="$3"

  if [[ -f "examples/resources/${slug}/resource.tf" && ! -f "$out" ]]; then
    cp "examples/resources/${slug}/resource.tf" "$out"
    return
  fi

  {
    echo "resource \"haproxy-dataplane_${slug}\" \"example\" {"
    local has_spec=0
    while IFS= read -r attr; do
      [[ -z "$attr" ]] && continue
      case "$attr" in
        name)
          echo "  name = \"example_${slug}\""
          ;;
        parent_name)
          echo "  parent_name = \"example_parent\""
          ;;
        spec)
          has_spec=1
          ;;
        runtime_id)
          echo "  runtime_id = \"example_runtime\""
          ;;
        *)
          echo "  ${attr} = \"example\""
          ;;
      esac
    done < <(extract_required_attrs "$req_file")

    if [[ "$has_spec" -eq 1 ]]; then
      echo ""
      echo "  # Replace with required fields for this object in your environment."
      echo "  spec = {}"
    fi

    echo "}"
  } > "$out"
}

write_data_source_example() {
  local slug="$1"
  local out="$2"
  local req_file="$3"

  {
    echo "data \"haproxy-dataplane_${slug}\" \"example\" {"
    while IFS= read -r attr; do
      [[ -z "$attr" ]] && continue
      case "$attr" in
        name)
          echo "  name = \"example_${slug}\""
          ;;
        parent_name)
          echo "  parent_name = \"example_parent\""
          ;;
        runtime_id)
          echo "  runtime_id = \"example_runtime\""
          ;;
        *)
          echo "  ${attr} = \"example\""
          ;;
      esac
    done < <(extract_required_attrs "$req_file")
    echo "}"
  } > "$out"
}

for doc in docs/resources/*.md; do
  slug="$(basename "$doc" .md)"

  if ! has_word "$slug" $KEEP_RESOURCE_TEMPLATES; then
    tmpl="templates/resources/${slug}.md.tmpl"
    if [[ -f "$tmpl" ]]; then
      rm -f "$tmpl"
    fi
    if [[ ! -f "$tmpl" ]]; then
      cat > "$tmpl" <<EOT
---
page_title: "haproxy-dataplane_${slug} Resource - HAProxy Data Plane"
subcategory: "Configuration"
description: |-
  Manages HAProxy ${slug//_/ } configuration.
---

# haproxy-dataplane_${slug} (Resource)

Use this resource to manage the ${slug} object in HAProxy Data Plane API.

## Example Usage

This baseline example shows the minimum Terraform shape for this resource.
Use it as a starting point and adjust the required fields to match your HAProxy configuration model.

{{tffile "examples/resources/${slug}/example_1.tf"}}

{{ .SchemaMarkdown | trimspace }}
EOT
    fi
  fi

  exdir="examples/resources/${slug}"
  mkdir -p "$exdir"
  ex1="$exdir/example_1.tf"
  if [[ ! -f "$ex1" ]]; then
    write_resource_example "$slug" "$ex1" "$doc"
  fi
done

for doc in docs/data-sources/*.md; do
  slug="$(basename "$doc" .md)"

  if ! has_word "$slug" $KEEP_DATA_SOURCE_TEMPLATES; then
    tmpl="templates/data-sources/${slug}.md.tmpl"
    if [[ -f "$tmpl" ]]; then
      rm -f "$tmpl"
    fi
    if [[ ! -f "$tmpl" ]]; then
      cat > "$tmpl" <<EOT
---
page_title: "haproxy-dataplane_${slug} Data Source - HAProxy Data Plane"
subcategory: "Configuration"
description: |-
  Reads HAProxy ${slug//_/ } configuration.
---

# haproxy-dataplane_${slug} (Data Source)

Use this data source to read existing ${slug} configuration from HAProxy.

## Example Usage

This baseline example shows the required arguments for looking up this object.

{{tffile "examples/data-sources/${slug}/example_1.tf"}}

{{ .SchemaMarkdown | trimspace }}
EOT
    fi
  fi

  exdir="examples/data-sources/${slug}"
  mkdir -p "$exdir"
  ex1="$exdir/example_1.tf"
  if [[ ! -f "$ex1" ]]; then
    write_data_source_example "$slug" "$ex1" "$doc"
  fi
done

terraform fmt -recursive examples >/dev/null
