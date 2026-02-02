#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------
# VERSION BUMP SCRIPT
# Usage: ./bump-version.sh <module> <major|minor|patch> [message]
# Example: ./bump-version.sh workspace minor "Added private endpoint support"
# ---------------------------------------------------------------------------------------------------------------------

set -e

MODULE=$1
BUMP_TYPE=$2
MESSAGE=$3

if [ -z "$MODULE" ] || [ -z "$BUMP_TYPE" ]; then
  echo "Usage: $0 <workspace|configuration> <major|minor|patch> [message]"
  exit 1
fi

case $MODULE in
  workspace)
    VERSION_FILE="terraform-modules/azure/databricks/workspace/version.json"
    ;;
  configuration)
    VERSION_FILE="terraform-modules/azure/databricks/configuration/version.json"
    ;;
  *)
    echo "Unknown module: $MODULE"
    echo "Valid modules: workspace, configuration"
    exit 1
    ;;
esac

if [ ! -f "$VERSION_FILE" ]; then
  echo "Version file not found: $VERSION_FILE"
  exit 1
fi

# Extract current version
CURRENT_VERSION=$(jq -r '.version' "$VERSION_FILE")
echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Unknown bump type: $BUMP_TYPE"
    echo "Valid types: major, minor, patch"
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Update version.json
DATE=$(date +%Y-%m-%d)
CHANGES="${MESSAGE:-No description provided}"

# Create updated version file
jq --arg version "$NEW_VERSION" \
   --arg date "$DATE" \
   --arg changes "$CHANGES" \
   '.version = $version | .changelog[$version] = {"date": $date, "changes": [$changes]}' \
   "$VERSION_FILE" > "$VERSION_FILE.tmp" && mv "$VERSION_FILE.tmp" "$VERSION_FILE"

echo "Updated $VERSION_FILE"
echo ""
echo "New changelog entry:"
jq ".changelog[\"$NEW_VERSION\"]" "$VERSION_FILE"

echo ""
echo "Next steps:"
echo "  1. Review changes in $VERSION_FILE"
echo "  2. git add $VERSION_FILE"
echo "  3. git commit -m 'Bump $MODULE version to $NEW_VERSION'"
echo "  4. git tag -a 'databricks-$MODULE/v$NEW_VERSION' -m 'Release $NEW_VERSION'"
