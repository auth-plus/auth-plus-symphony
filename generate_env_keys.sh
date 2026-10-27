#!/usr/bin/env bash

# Script to generate .env.keys for each submodule from the root .env file
# or environment variables.

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${ROOT_DIR}/.env}"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================================="
echo "Generating .env.keys for all submodules"
echo "=================================================="

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Root env file not found at '$ENV_FILE'.${NC}"
    echo "Please create a .env file with the format:"
    echo "  AUTHENTICATION_DOTENV_PRIVATE_KEY=<key>"
    echo "  BILLING_DOTENV_PRIVATE_KEY=<key>"
    echo "  CLIENT_DOTENV_PRIVATE_KEY=<key>"
    echo "  MONETIZATION_DOTENV_PRIVATE_KEY=<key>"
    echo "  NOTIFICATION_DOTENV_PRIVATE_KEY=<key>"
    exit 1
fi

# Load variables from env file into an associative array
declare -A ENV_VARS

while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading/trailing whitespace
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # Match KEY=VALUE
    if [[ "$line" =~ ^([A-Za-z0-9_]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        
        # Remove surrounding quotes if present
        val="${val%\"}"
        val="${val#\"}"
        val="${val%\'}"
        val="${val#\'}"
        
        ENV_VARS["$key"]="$val"
    fi
done < "$ENV_FILE"

# Find submodules
SUBMODULES=""
if [ -f "${ROOT_DIR}/.gitmodules" ]; then
    SUBMODULES=$(git config --file "${ROOT_DIR}/.gitmodules" --get-regexp path | awk '{ print $2 }')
fi

# Fallback to discovering subdirectories if .gitmodules is missing or empty
if [ -z "$SUBMODULES" ]; then
    SUBMODULES=$(find "${ROOT_DIR}" -maxdepth 1 -mindepth 1 -type d -name "auth-plus-*" -exec basename {} \;)
fi

if [ -z "$SUBMODULES" ]; then
    echo -e "${YELLOW}No submodules found to process.${NC}"
    exit 0
fi

SUCCESSFUL=()
WARNINGS=()
FAILED=()

for sm_path in $SUBMODULES; do
    sm_dir="${ROOT_DIR}/${sm_path}"
    sm_name="$(basename "$sm_path")"
    
    echo ""
    echo "--------------------------------------------------"
    echo "Processing submodule: $sm_name"
    echo "--------------------------------------------------"

    if [ ! -d "$sm_dir" ]; then
        echo -e "${RED}Directory '$sm_dir' does not exist.${NC}"
        FAILED+=("$sm_name (Directory not found)")
        continue
    fi

    # Derive possible prefixes:
    # 1. Short name without "auth-plus-" prefix, e.g. "authentication" -> "AUTHENTICATION"
    # 2. Full name with underscores, e.g. "auth-plus-authentication" -> "AUTH_PLUS_AUTHENTICATION"
    short_name="${sm_name#auth-plus-}"
    short_name="${short_name#auth_plus_}"
    
    PREFIX_SHORT="$(echo "$short_name" | tr '[:lower:]-' '[:upper:]_')"
    PREFIX_FULL="$(echo "$sm_name" | tr '[:lower:]-' '[:upper:]_')"

    # Reset associative array for this submodule
    unset TARGET_KEYS
    declare -A TARGET_KEYS=()
    
    # Search in ENV_VARS array and also in inherited environment variables
    # Priority: ENV_FILE takes precedence, followed by process environment
    ALL_KEY_NAMES=()
    for k in "${!ENV_VARS[@]}"; do
        ALL_KEY_NAMES+=("$k")
    done
    
    # Also check exported shell variables
    while IFS= read -r env_var; do
        var_name="${env_var%%=*}"
        ALL_KEY_NAMES+=("$var_name")
    done < <(env)

    # De-duplicate key names
    UNIQUE_KEYS=($(printf "%s\n" "${ALL_KEY_NAMES[@]}" | sort -u))

    for k in "${UNIQUE_KEYS[@]}"; do
        val="${ENV_VARS[$k]:-${!k}}"
        [ -z "$val" ] && continue

        # Check if key starts with PREFIX_SHORT or PREFIX_FULL followed by DOTENV_PRIVATE_KEY
        target_name=""
        if [[ "$k" =~ ^${PREFIX_SHORT}_(DOTENV_PRIVATE_KEY(_[A-Za-z0-9_]+)?)$ ]]; then
            target_name="${BASH_REMATCH[1]}"
        elif [[ "$k" =~ ^${PREFIX_FULL}_(DOTENV_PRIVATE_KEY(_[A-Za-z0-9_]+)?)$ ]]; then
            target_name="${BASH_REMATCH[1]}"
        fi

        if [ -n "$target_name" ]; then
            TARGET_KEYS["$target_name"]="$val"
        fi
    done

    if [ ${#TARGET_KEYS[@]} -eq 0 ]; then
        echo -e "${YELLOW}Warning: No private keys found for '$sm_name' (expected ${PREFIX_SHORT}_DOTENV_PRIVATE_KEY).${NC}"
        WARNINGS+=("$sm_name (No matching keys in $ENV_FILE)")
        continue
    fi

    keys_file="${sm_dir}/.env.keys"
    
    # Generate .env.keys content
    tmp_file="$(mktemp)"
    first_block=1
    
    # Handle DOTENV_PRIVATE_KEY (root/default .env) first if present
    if [ -n "${TARGET_KEYS["DOTENV_PRIVATE_KEY"]:-}" ]; then
        echo "# .env" >> "$tmp_file"
        echo "DOTENV_PRIVATE_KEY=${TARGET_KEYS["DOTENV_PRIVATE_KEY"]}" >> "$tmp_file"
        unset 'TARGET_KEYS["DOTENV_PRIVATE_KEY"]'
        first_block=0
    fi

    # Handle remaining environment-specific keys (e.g. DOTENV_PRIVATE_KEY_PRODUCTION)
    for target_key in $(printf "%s\n" "${!TARGET_KEYS[@]}" | sort); do
        val="${TARGET_KEYS[$target_key]}"
        env_suffix="${target_key#DOTENV_PRIVATE_KEY_}"
        env_name="$(echo "$env_suffix" | tr '[:upper:]' '[:lower:]')"
        
        if [ $first_block -eq 0 ]; then
            echo "" >> "$tmp_file"
        fi
        echo "# .env.${env_name}" >> "$tmp_file"
        echo "${target_key}=${val}" >> "$tmp_file"
        first_block=0
    done

    mv "$tmp_file" "$keys_file"
    chmod 600 "$keys_file" 2>/dev/null || chmod 644 "$keys_file"

    echo -e "${GREEN}Created: $keys_file${NC}"
    SUCCESSFUL+=("$sm_name")
done

echo ""
echo "=================================================="
echo "Summary"
echo "=================================================="
if [ ${#SUCCESSFUL[@]} -gt 0 ]; then
    echo -e "${GREEN}Successfully generated .env.keys for (${#SUCCESSFUL[@]}):${NC}"
    for sm in "${SUCCESSFUL[@]}"; do
        echo -e "  ${GREEN}✓${NC} $sm"
    done
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Skipped submodules (${#WARNINGS[@]}):${NC}"
    for sm in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}!${NC} $sm"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed submodules (${#FAILED[@]}):${NC}"
    for sm in "${FAILED[@]}"; do
        echo -e "  ${RED}✗${NC} $sm"
    done
    exit 1
fi

echo ""
echo -e "${GREEN}All done!${NC}"

