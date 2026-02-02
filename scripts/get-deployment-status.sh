#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------
# DEPLOYMENT STATUS SCRIPT
# Shows current deployment status across all environments
# Usage: ./get-deployment-status.sh [module]
# ---------------------------------------------------------------------------------------------------------------------

MANIFEST_FILE="deployments/tracking/deployment-manifest.json"
MODULE=$1

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Manifest file not found: $MANIFEST_FILE"
  exit 1
fi

echo "=============================================="
echo "       DEPLOYMENT STATUS REPORT"
echo "=============================================="
echo "Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""

print_module_status() {
  local module=$1

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Module: $module"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  for env in dev it qas prod; do
    status=$(jq -r ".deployments[\"$module\"][\"$env\"].status // \"not_deployed\"" "$MANIFEST_FILE")
    version=$(jq -r ".deployments[\"$module\"][\"$env\"].version // \"N/A\"" "$MANIFEST_FILE")
    deployed_at=$(jq -r ".deployments[\"$module\"][\"$env\"].deployedAt // \"N/A\"" "$MANIFEST_FILE")
    deployed_by=$(jq -r ".deployments[\"$module\"][\"$env\"].deployedBy // \"N/A\"" "$MANIFEST_FILE")

    # Status emoji
    case $status in
      deployed)
        emoji="✅"
        ;;
      not_deployed)
        emoji="⏳"
        ;;
      failed)
        emoji="❌"
        ;;
      *)
        emoji="❓"
        ;;
    esac

    printf "  %-6s %s %-15s | v%-12s | %s\n" "$env" "$emoji" "$status" "$version" "$deployed_at"
  done
  echo ""
}

if [ -n "$MODULE" ]; then
  print_module_status "$MODULE"
else
  for module in databricks-workspace databricks-config; do
    print_module_status "$module"
  done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Promotion Path: dev → it → qas → prod"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
