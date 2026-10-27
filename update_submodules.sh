#!/usr/bin/env bash

# Script to checkout target branch and pull updates for all submodules.
# Continues processing on errors and reports a final summary of succeeded and failed submodules.

BRANCH="${1:-main}"
ROOT_DIR="$(pwd)"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESSFUL=()
FAILED=()
FAILED_REASONS=()
DELETED_BRANCHES=()

# Find submodules
if [ -f .gitmodules ]; then
    SUBMODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
else
    echo -e "${RED}Error: No .gitmodules file found in current directory.${NC}"
    exit 1
fi

if [ -z "$SUBMODULES" ]; then
    echo "No submodules found."
    exit 0
fi

echo "=================================================="
echo "Updating all submodules to branch: '$BRANCH'"
echo "=================================================="

# Ensure submodules are initialized
git submodule update --init --recursive 2>/dev/null || true

for sm_path in $SUBMODULES; do
    echo ""
    echo "--------------------------------------------------"
    echo "Processing submodule: $sm_path"
    echo "--------------------------------------------------"

    if [ ! -d "$sm_path" ]; then
        echo -e "${RED}Error: Directory '$sm_path' does not exist.${NC}"
        FAILED+=("$sm_path")
        FAILED_REASONS+=("Directory does not exist")
        continue
    fi

    cd "$ROOT_DIR/$sm_path" || {
        FAILED+=("$sm_path")
        FAILED_REASONS+=("Could not navigate into directory")
        continue
    }

    # Check for uncommitted changes beforehand
    DIRTY=0
    if [ -n "$(git status --porcelain)" ]; then
        DIRTY=1
        echo -e "${YELLOW}Notice: Uncommitted changes detected in '$sm_path'.${NC}"
    fi

    # Fetch and prune remote tracking branches
    git fetch --prune origin 2>/dev/null || git fetch --prune 2>/dev/null || true

    # Attempt to checkout target branch
    CHECKOUT_OUT=$(git checkout "$BRANCH" 2>&1)
    CHECKOUT_RES=$?
    
    if [ $CHECKOUT_RES -ne 0 ]; then
        echo -e "${RED}Checkout failed for '$sm_path':${NC}"
        echo "$CHECKOUT_OUT"
        
        REASON="Checkout failed"
        if [ $DIRTY -eq 1 ]; then
            REASON="Checkout failed due to uncommitted local changes"
        fi
        
        FAILED+=("$sm_path")
        FAILED_REASONS+=("$REASON")
        cd "$ROOT_DIR"
        continue
    fi

    # Attempt to pull latest changes
    PULL_OUT=$(git pull origin "$BRANCH" 2>&1)
    PULL_RES=$?
    if [ $PULL_RES -ne 0 ]; then
        PULL_OUT=$(git pull 2>&1)
        PULL_RES=$?
    fi

    if [ $PULL_RES -ne 0 ]; then
        echo -e "${RED}Pull failed for '$sm_path':${NC}"
        echo "$PULL_OUT"

        REASON="Pull failed"
        if [ $DIRTY -eq 1 ]; then
            REASON="Pull failed due to uncommitted local changes / merge conflicts"
        fi

        FAILED+=("$sm_path")
        FAILED_REASONS+=("$REASON")
        cd "$ROOT_DIR"
        continue
    fi

    echo "$PULL_OUT"

    # Delete local branches that were deleted on the remote
    GONE_BRANCHES=$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$2 == "[gone]" { print $1 }')
    if [ -n "$GONE_BRANCHES" ]; then
        echo -e "${YELLOW}Cleaning up branches deleted on remote in '$sm_path':${NC}"
        for gone_branch in $GONE_BRANCHES; do
            if [ "$gone_branch" != "$BRANCH" ]; then
                DEL_OUT=$(git branch -D "$gone_branch" 2>&1)
                if [ $? -eq 0 ]; then
                    echo -e "  ${GREEN}✔ Deleted local branch:${NC} $gone_branch"
                    DELETED_BRANCHES+=("$sm_path: $gone_branch")
                else
                    echo -e "  ${RED}✖ Failed to delete local branch '$gone_branch':${NC} $DEL_OUT"
                fi
            fi
        done
    fi

    echo -e "${GREEN}✓ Successfully updated '$sm_path'${NC}"
    SUCCESSFUL+=("$sm_path")

    cd "$ROOT_DIR"
done

echo ""
echo "=================================================="
echo "SUMMARY REPORT"
echo "=================================================="

if [ ${#SUCCESSFUL[@]} -gt 0 ]; then
    echo -e "${GREEN}Succeeded (${#SUCCESSFUL[@]}):${NC}"
    for sm in "${SUCCESSFUL[@]}"; do
        echo -e "  ${GREEN}✔${NC} $sm"
    done
fi

if [ ${#DELETED_BRANCHES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Cleaned up branches (${#DELETED_BRANCHES[@]}):${NC}"
    for db in "${DELETED_BRANCHES[@]}"; do
        echo -e "  ${YELLOW}🗑${NC} $db"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${RED}Failed (${#FAILED[@]}):${NC}"
    for i in "${!FAILED[@]}"; do
        echo -e "  ${RED}✖${NC} ${FAILED[$i]} -> Reason: ${FAILED_REASONS[$i]}"
    done
    echo "=================================================="
    exit 1
else
    echo "=================================================="
    echo -e "${GREEN}All submodules updated successfully!${NC}"
    exit 0
fi
