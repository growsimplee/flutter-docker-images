#!/usr/bin/env bash
set -euo pipefail

# Adds a new Flutter version image scaffold and CI job.
# - Prompts for Flutter version (e.g., 3.29.0)
# - Creates folder flutter-<version>/ with Dockerfile (copied from latest existing) and versions file set to 0
# - Updates .circleci/config.yml to add a build job and branch filter
# - Creates and switches to git branch build-flutter-<version> and commits changes

RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; RESET="\033[0m"

repo_root_dir() {
  # Resolve repo root as the directory containing this script's parent
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "$(cd "$script_dir/.." && pwd)"
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo -e "${RED}Error:${RESET} Required file not found: $path" >&2
    exit 1
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo -e "${RED}Error:${RESET} Required command not found: $1" >&2
    exit 1
  fi
}

git_create_or_switch_branch() {
  local branch="$1"
  if git rev-parse --verify "$branch" >/dev/null 2>&1; then
    git checkout "$branch" >/dev/null
    echo -e "${YELLOW}Switched:${RESET} existing branch '$branch'"
  else
    git checkout -b "$branch" >/dev/null
    echo -e "${GREEN}Created:${RESET} new branch '$branch'"
  fi
}

prompt_version() {
  local v
  read -r -p "Enter Flutter version (e.g., 3.29.0): " v
  if [[ ! "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Invalid version format.${RESET} Expected semantic version like 3.29.0" >&2
    exit 1
  fi
  echo "$v"
}

latest_source_folder() {
  # Picks the highest semantic version folder matching flutter-<semver>
  # macOS compatible: avoid GNU-specific find flags
  local candidates
  IFS=$'\n' read -rd '' -a candidates < <(ls -1d flutter-* 2>/dev/null | sed 's#^./##' || true)
  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo ""; return
  fi
  local best="" best_v=""
  for f in "${candidates[@]}"; do
    if [[ -d "$f" && -f "$f/Dockerfile" && "$f" =~ ^flutter-([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
      local v
      v="${BASH_REMATCH[1]}"
      if [[ -z "$best_v" ]] || [[ $(printf '%s\n%s\n' "$best_v" "$v" | sort -V | tail -n1) == "$v" ]]; then
        best_v="$v"; best="$f"
      fi
    fi
  done
  echo "$best"
}

update_flutter_version_in_dockerfile() {
  local file="$1" version="$2"
  # Portable in-place edit for BSD sed
  if sed --version >/dev/null 2>&1; then
    sed -i -e "s/^ENV FLUTTER_VERSION=.*/ENV FLUTTER_VERSION=$version/" "$file"
  else
    sed -i '' -e "s/^ENV FLUTTER_VERSION=.*/ENV FLUTTER_VERSION=$version/" "$file"
  fi
}

append_ci_job() {
  local config_file="$1" version="$2" dash_version
  dash_version="${version//./-}"

  # Check if job for this version already exists
  if grep -q "only: build-flutter-$version" "$config_file"; then
    echo -e "${YELLOW}Skipping CI config update:${RESET} Job for $version already present."
    return
  fi

  # Ensure workflows section exists
  if ! grep -q "^workflows:" "$config_file"; then
    echo -e "${RED}Error:${RESET} workflows section not found in $config_file" >&2
    exit 1
  fi

  # Append a new job entry under workflows.build.jobs. Appending at EOF maintains the same context in YAML.
  {
    echo "      - build-flutter:"
    echo "          name: build-flutter-$dash_version"
    echo "          flutter_folder: flutter-$version"
    echo "          filters:"
    echo "            branches:"
    echo "              only: build-flutter-$version"
  } >> "$config_file"
  echo -e "${GREEN}Updated:${RESET} Appended CI job for flutter-$version to $config_file"
}

main() {
  require_cmd git
  require_cmd sed

  local root
  root="$(repo_root_dir)"
  cd "$root"

  local version
  version="${1:-}"
  if [[ -z "$version" ]]; then
    version="$(prompt_version)"
  fi

  local new_folder="flutter-$version"
  local config_file=".circleci/config.yml"

  # Create/switch to branch first as requested
  local branch="build-flutter-$version"
  git_create_or_switch_branch "$branch"

  require_file "$config_file"

  # Pick source folder to copy Dockerfile from
  local src_folder
  src_folder="$(latest_source_folder)"
  if [[ -z "$src_folder" ]]; then
    echo -e "${RED}Error:${RESET} No existing flutter-* folder found to copy Dockerfile from." >&2
    echo "Please add at least one existing version first." >&2
    exit 1
  fi

  if [[ ! -f "$src_folder/Dockerfile" ]]; then
    echo -e "${RED}Error:${RESET} Dockerfile not found in $src_folder" >&2
    exit 1
  fi

  # Create or reuse target folder
  if [[ -d "$new_folder" ]]; then
    if [[ -f "$new_folder/Dockerfile" ]]; then
      echo -e "${RED}Error:${RESET} Target folder already exists with a Dockerfile: $new_folder" >&2
      exit 1
    fi
  else
    mkdir -p "$new_folder"
    echo -e "${GREEN}Created:${RESET} $new_folder"
  fi

  cp "$src_folder/Dockerfile" "$new_folder/Dockerfile"
  update_flutter_version_in_dockerfile "$new_folder/Dockerfile" "$version"
  echo -e "${GREEN}Prepared:${RESET} $new_folder/Dockerfile (FLUTTER_VERSION=$version)"

  # Create versions file with 0
  echo 0 > "$new_folder/versions"
  echo -e "${GREEN}Prepared:${RESET} $new_folder/versions (0)"

  # Update CI config
  append_ci_job "$config_file" "$version"

  git add "$new_folder" "$config_file"
  git commit -m "Add flutter-$version image and CI job"
  echo -e "${GREEN}Committed:${RESET} changes on branch '$branch'"

  echo
  echo -e "${GREEN}Done!${RESET} Next steps:"
  echo "- Review $new_folder/Dockerfile and adjust Android SDK packages if needed."
  echo "- Optionally push the branch: git push -u origin $branch"
}

main "$@"


