# TASK 1 v2 CHANGELOG

**Date:** 2026-02-17  
**Files Modified:** 8 files

---

## Issue 1: Correct Webhook Payload ✅

**File:** `test-payload.json`

Simplified to match the exact expected structure. Removed `buy_box_criteria` sub-fields (property_types, price_min, price_max) that weren't part of the canonical payload. Now uses empty `{}` for buy_box_criteria as specified.

---

## Issue 2: Production Webhook Activation ✅ (Documented)

**Problem:** n8n webhook-triggered workflows return 404 until the workflow is set to **Active**. Publishing/importing a workflow does NOT activate it.

**Fix:** In the n8n UI, open the workflow and toggle the **Active** switch (top-right corner). This registers the webhook endpoint with n8n's routing layer. Without this toggle, the production webhook URL will always return 404.

**Note:** The test webhook URL (available during manual executions) works without activation, but the production URL requires it.

---

## Issue 3: Strategy-Blind Layer 1 (Architecture Fix) ✅

**File:** `n8n-workflows/task1-v2-fixed.json` — Extract Input node

**Before:** Extract Input output a flat object with all fields (zip_code, city, county, state, exit_strategy, buy_box_criteria). All 5 agents could access strategy fields.

**After:** Extract Input now outputs TWO separate objects:
- `geo_context`: `{zip_code, city, county, state}` → referenced by all 5 agents
- `strategy_context`: `{exit_strategy, buy_box_criteria}` → referenced ONLY by Build Layer 2 Prompt

**All 5 agent HTTP Request nodes** updated to reference `$('Extract Input').item.json.geo_context.zip_code` (etc.) instead of `$('Extract Input').item.json.zip_code`.

**Build Layer 2 Prompt** updated to pull `strategy_context` for exit_strategy and buy_box_criteria, while using `geo_context` for geographic fields.

---

## Issue 4: Reworked All 5 Agent Prompts ✅

**Files:** All 5 files in `research-agents/` + corresponding prompts in workflow JSON

**Before:** Rigid fill-in-the-blank templates with specific "DATA POINTS TO RESEARCH" checklists demanding exact fields (e.g., "Percentage of homes over 40 years old", "ARM concentration as percentage"). Failed on small/rural ZIPs where granular data doesn't exist.

**After:** Investigative research directives following the v1 Signal Scoring model:
1. **Removed** rigid checklists with specific field expectations
2. **Added** open-ended investigative directives: "Research the housing stock in this area. Find what's available about age, types, conditions, density."
3. **Added** data scarcity handling: "If zip-level data isn't available, use county-level data and note the aggregation level"
4. **Added** `data_coverage` field to every agent's output schema
5. **Made JSON fields flexible** — all fields accept null, and narrative descriptions are encouraged when numbers aren't available
6. **Maintained** strategy-blind constraint in all agents
7. **Maintained** JSON output format requirement

---

## Issue 5: Density Calculation Sanity Checks ✅

**File:** Agent 1 prompt (both markdown and workflow JSON)

Added explicit sanity-check instructions to the Housing Density section:

> "SANITY CHECK: Before reporting any density figure, verify it against known benchmarks. Rural areas typically have well under 1 unit per acre. Suburban areas run 2-8 units per acre. Urban areas are 10-50 units per acre. Only the densest cities (Manhattan) exceed 100 units per acre. If your calculated number does not match the area type, recalculate or note the uncertainty."

---

## Layer 2 Prompt Updates ✅

Added to Build Layer 2 Prompt:
- `data_quality_notes` field in output schema for noting data scarcity
- Instruction: "If most data is county-level for a small/rural zip, lower your confidence score accordingly"
- Now pulls `strategy_context` (not flat fields) for exit_strategy and buy_box_criteria

---

## Files Created/Updated

| File | Action |
|------|--------|
| `n8n-workflows/task1-v2-fixed.json` | Created (updated workflow) |
| `research-agents/AGENT-1-PROPERTY-STOCK.md` | Updated |
| `research-agents/AGENT-2-FINANCIAL-EQUITY.md` | Updated |
| `research-agents/AGENT-3-DISTRESS-LEGAL.md` | Updated |
| `research-agents/AGENT-4-OWNERSHIP-OCCUPANCY.md` | Updated |
| `research-agents/AGENT-5-MARKET-DYNAMICS.md` | Updated |
| `test-payload.json` | Updated |
| `TASK1-V2-CHANGELOG.md` | Created |
