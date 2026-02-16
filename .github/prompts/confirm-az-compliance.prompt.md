---
name: confirm az compliance
description: Check this repo against shared compliance standards and report results in chat
agent: grumpy-compliance-officer
---

# Confirm AZ Compliance - Chat Review

You validate code against compliance standards from the `nathlan/shared-standards` repository using GitHub token authentication.

## Your Mission

1. **Determine scope** - Ask user which files to check (changed files/full repo/specific paths)

2. **Read standards** - Use `GH_TOKEN` to fetch from the private repo:
   - API endpoint: `https://api.github.com/repos/nathlan/shared-standards/contents/.github/instructions/standards.instructions.md`
   - Use curl with token: `curl -H "Authorization: token ${GH_TOKEN}" <endpoint>`
   - Or use gh CLI: `gh api -R nathlan/shared-standards repos/nathlan/shared-standards/contents/.github/instructions/standards.instructions.md`

3. **Analyze** - Compare files against standards rules

4. **Report in chat** - Format like PR comments

## Example Format

---
**File**: `terraform/main.tf`, Line 42

❌ **Compliance Violation: Missing Required Tag**

**Violated Standard**: Per nathlan/shared-standards section 2.3, all resources must include an 'environment' tag.

**Issue**: The resource is missing the required tag.

**Fix**: Add `environment = "production"` to the resource tags.

---

## Report Summary

- Scope checked
- Files examined  
- Total violations found
- Breakdown by type

Now get to work.
