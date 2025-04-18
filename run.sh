#!/usr/bin/env bash
set -e

GROUP="$1"     # ex: core, devops, storage...
ACTION="$2"    # ex: start, stop, tags
SERVICE="$3"

if [[ -z "$GROUP" || -z "$ACTION" ]]; then
  echo "Usage: $0 <group> <action> [service]"
  echo "Example: $0 core start"
  echo "Actions: start, stop, tags"
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Aborting."; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${DIR}/scripts/${GROUP}"

if [ ! -d "$SCRIPTS_DIR" ]; then
  echo "Unknown group: ${GROUP}"
  exit 1
fi

echo "Running '${ACTION}' on group '${GROUP}'..."

for script in "$SCRIPTS_DIR"/*.sh; do
  if [[ -n "$SERVICE" && "$SERVICE" != "$(basename "$script")" ]]; then
    continue
  fi

  if [ "$ACTION" == "tags" ]; then
    image="$(awk -F'=' '!/^#/ && /CONTAINER_IMAGE=/ { print $2 }' "$script" | sed -e 's#docker.io/##' -e 's/"//g')"
    if [ -z "$image" ]; then continue ; fi
    if [ "$(echo "$image" | grep -c '/')" -eq 0 ]; then
      image="library/${image}"
    fi
    echo "Getting tags for image ${image}"

    curl -s "https://registry.hub.docker.com/v2/repositories/${image}/tags?page_size=100" \
      | jq -r '.results[].name' \
      | grep -E "^v?[0-9\.]+$|^latest$" \
      | sort -V \
      | tail -n 10

    continue
  fi

  if [ -x "$script" ]; then
    echo "Executing $(basename "$script")..."

    "$script" "$ACTION"
  fi
done
