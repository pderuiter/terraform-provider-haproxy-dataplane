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

emit_required_assignments() {
  local req_file="$1"
  local mode="$2"
  local has_spec=0

  while IFS= read -r attr; do
    [[ -z "$attr" ]] && continue
    case "$attr" in
      name)
        if [[ "$mode" == "direct" ]]; then
          echo "  name = \"example_${slug}\""
        else
          echo "  name = local.${slug}_name"
        fi
        ;;
      parent_name)
        if [[ "$mode" == "direct" ]]; then
          echo "  parent_name = \"example_parent\""
        else
          echo "  parent_name = var.parent_name"
        fi
        ;;
      spec)
        has_spec=1
        ;;
      runtime_id)
        if [[ "$mode" == "direct" ]]; then
          echo "  runtime_id = \"example_runtime\""
        else
          echo "  runtime_id = var.runtime_id"
        fi
        ;;
      *)
        if [[ "$mode" == "direct" ]]; then
          echo "  ${attr} = \"example\""
        else
          echo "  ${attr} = var.${attr}"
        fi
        ;;
    esac
  done < <(extract_required_attrs "$req_file")

  if [[ "$has_spec" -eq 1 ]]; then
    echo ""
    echo "  # Replace with required fields for this object in your environment."
    echo "  spec = {}"
  fi
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
    emit_required_assignments "$req_file" "direct"
    echo "}"
  } > "$out"
}

write_resource_operational_example() {
  local slug="$1"
  local out="$2"
  local req_file="$3"

  {
    echo "locals {"
    echo "  ${slug}_name = \"managed_${slug}\""
    echo "}"
    echo ""

    if extract_required_attrs "$req_file" | grep -qx "parent_name"; then
      echo "variable \"parent_name\" {"
      echo "  description = \"Parent object name, for example a frontend or backend name.\""
      echo "  type        = string"
      echo "}"
      echo ""
    fi

    if extract_required_attrs "$req_file" | grep -qx "runtime_id"; then
      echo "variable \"runtime_id\" {"
      echo "  description = \"Runtime API object id, if required by this endpoint.\""
      echo "  type        = string"
      echo "}"
      echo ""
    fi

    while IFS= read -r attr; do
      [[ -z "$attr" ]] && continue
      case "$attr" in
        name|parent_name|runtime_id|spec) ;;
        *)
          echo "variable \"${attr}\" {"
          echo "  type = string"
          echo "}"
          echo ""
          ;;
      esac
    done < <(extract_required_attrs "$req_file")

    echo "resource \"haproxy-dataplane_${slug}\" \"managed\" {"
    emit_required_assignments "$req_file" "operational"
    echo "}"
    echo ""
    echo "output \"${slug}_id\" {"
    echo "  value = haproxy-dataplane_${slug}.managed.id"
    echo "}"
  } > "$out"
}

write_data_source_example() {
  local slug="$1"
  local out="$2"
  local req_file="$3"

  {
    echo "data \"haproxy-dataplane_${slug}\" \"example\" {"
    emit_required_assignments "$req_file" "direct"
    echo "}"
  } > "$out"
}

write_data_source_consumption_example() {
  local slug="$1"
  local out="$2"
  local req_file="$3"

  {
    echo "locals {"
    echo "  ${slug}_lookup_name = \"existing_${slug}\""
    echo "}"
    echo ""

    if extract_required_attrs "$req_file" | grep -qx "parent_name"; then
      echo "variable \"parent_name\" {"
      echo "  type = string"
      echo "}"
      echo ""
    fi

    if extract_required_attrs "$req_file" | grep -qx "runtime_id"; then
      echo "variable \"runtime_id\" {"
      echo "  type = string"
      echo "}"
      echo ""
    fi

    while IFS= read -r attr; do
      [[ -z "$attr" ]] && continue
      case "$attr" in
        name|parent_name|runtime_id|spec) ;;
        *)
          echo "variable \"${attr}\" {"
          echo "  type = string"
          echo "}"
          echo ""
          ;;
      esac
    done < <(extract_required_attrs "$req_file")

    echo "data \"haproxy-dataplane_${slug}\" \"selected\" {"
    emit_required_assignments "$req_file" "operational"
    echo "}"
    echo ""
    echo "output \"${slug}_id\" {"
    echo "  value = data.haproxy-dataplane_${slug}.selected.id"
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

### Minimal declaration

Use this pattern when you want a concise resource declaration with only required fields.

{{tffile "examples/resources/${slug}/example_1.tf"}}

### Operational module pattern

Use this pattern when exposing a reusable module interface for teams. It adds variables, a stable naming pattern, and an output.

{{tffile "examples/resources/${slug}/example_2.tf"}}

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
  ex2="$exdir/example_2.tf"
  if [[ ! -f "$ex2" ]]; then
    write_resource_operational_example "$slug" "$ex2" "$doc"
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

### Direct lookup

Use this pattern for a straightforward read of an existing object.

{{tffile "examples/data-sources/${slug}/example_1.tf"}}

### Lookup with module outputs

Use this pattern when a module consumes existing HAProxy objects and exports their identifiers.

{{tffile "examples/data-sources/${slug}/example_2.tf"}}

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
  ex2="$exdir/example_2.tf"
  if [[ ! -f "$ex2" ]]; then
    write_data_source_consumption_example "$slug" "$ex2" "$doc"
  fi
done

terraform fmt -recursive examples >/dev/null
