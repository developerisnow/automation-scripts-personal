#!/usr/bin/env bash
# 🤖 Git Claude Commit Script
# ===========================
# Commits .claude folders and CLAUDE* files across multiple repositories

# 🎯 Target directories
CLAUDE_DIRS=(
    "$HOME/.claude"
    "$HOME/.config/claude"
    "$HOME/__Repositories/Hypetrain/.claude"
    "$HOME/__Repositories/Hypetrain/repositories/hypetrain-backend/.claude"
    "$HOME/__Repositories/Hypetrain/repositories/hypetrain-garden/.claude"
    "$HOME/__Repositories/Hypetrain/repositories/hypetrain-docs/.claude"
)

# 🎨 Colors for ADHD-friendly output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🤖 Starting Claude files commit across repositories...${NC}\n"

committed_count=0
skipped_count=0

for dir in "${CLAUDE_DIRS[@]}"; do
    echo -e "${BLUE}📁 Checking: ${dir}${NC}"
    
    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}⚠️  Directory doesn't exist, skipping...${NC}\n"
        ((skipped_count++))
        continue
    fi
    
    # Get the repository root (go up until we find .git)
    repo_root="$dir"
    while [[ "$repo_root" != "/" && ! -d "$repo_root/.git" ]]; do
        repo_root="$(dirname "$repo_root")"
    done
    
    # Check if we found a git repository
    if [[ ! -d "$repo_root/.git" ]]; then
        echo -e "${YELLOW}⚠️  Not in a git repository, skipping...${NC}\n"
        ((skipped_count++))
        continue
    fi
    
    echo -e "${GREEN}✅ Found git repo at: ${repo_root}${NC}"
    
    # Change to repository root
    cd "$repo_root" || continue
    
    # Add Claude files (both .claude dirs and CLAUDE* files)
    echo -e "${PURPLE}📝 Adding Claude files...${NC}"
    
    # Calculate relative path from repo root to target directory
    rel_path="${dir#$repo_root}"
    rel_path="${rel_path#/}"  # Remove leading slash if present
    
    # Add files with different strategies based on directory structure
    if [[ -n "$rel_path" ]]; then
        # Target directory is a subdirectory of repo root
        git add "$rel_path" 2>/dev/null || true
        git add "$rel_path"/.claude 2>/dev/null || true
        git add "$rel_path"/CLAUDE* 2>/dev/null || true
    else
        # Target directory IS the repo root
        git add .claude 2>/dev/null || true
        git add CLAUDE* 2>/dev/null || true
        git add . 2>/dev/null || true  # Add everything in claude config repo
    fi
    
    # Check if anything was actually staged
    if ! git diff --cached --quiet; then
        # Commit with message
        echo -e "${GREEN}💾 Committing changes...${NC}"
        git commit -m "chore(claude): bulk changes" --no-verify
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Successfully committed in: ${repo_root}${NC}\n"
            ((committed_count++))
        else
            echo -e "${RED}❌ Commit failed in: ${repo_root}${NC}\n"
        fi
    else
        echo -e "${YELLOW}📝 No changes to commit, skipping...${NC}\n"
        ((skipped_count++))
    fi
done

# 📊 Summary
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Successfully committed: ${committed_count} repositories${NC}"
echo -e "${YELLOW}⏭️  Skipped: ${skipped_count} locations${NC}"
echo -e "${PURPLE}🎉 Claude commit operation completed!${NC}"
