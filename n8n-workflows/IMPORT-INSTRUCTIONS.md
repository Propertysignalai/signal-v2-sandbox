# N8N WORKFLOW IMPORT INSTRUCTIONS

## Task 1: Single-Zip Phase 1 Workflow

**File:** `task1-single-zip-phase1.json`

---

## METHOD 1: Manual Import (Recommended for First Time)

1. **Open n8n sandbox:** https://propertysignalai.app.n8n.cloud
2. **Click:** "+ Add workflow" or "Import from File"
3. **Select:** `task1-single-zip-phase1.json`
4. **Replace API Key Placeholders:**
   - Find all instances of `PERPLEXITY_API_KEY`
   - Replace with actual Perplexity API key
   - Find all instances of `ANTHROPIC_API_KEY`
   - Replace with actual Anthropic API key
5. **Save workflow**
6. **Activate webhook** (click "Test workflow" or "Activate")

---

## METHOD 2: Programmatic Import (via n8n REST API)

If you have n8n API credentials:

```bash
# Set your n8n API key
N8N_API_KEY="your-n8n-api-key"
N8N_BASE_URL="https://propertysignalai.app.n8n.cloud/api/v1"

# Load workflow JSON and replace API keys
WORKFLOW_JSON=$(cat task1-single-zip-phase1.json | \
  sed "s/PERPLEXITY_API_KEY/$PERPLEXITY_KEY/g" | \
  sed "s/ANTHROPIC_API_KEY/$ANTHROPIC_KEY/g")

# Import workflow
curl -X POST "$N8N_BASE_URL/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$WORKFLOW_JSON"
```

---

## WORKFLOW STRUCTURE

**Nodes:**
1. **Webhook Start** - POST /single-zip-phase1
2. **Extract Input** - Parses webhook payload
3. **Agent 1-5** - 5 parallel Perplexity calls (strategy-blind research)
4. **Build Layer 2 Prompt** - Collects all 5 responses + builds Claude prompt
5. **Layer 2: Analyst Synthesis** - Claude call (mosaic theory synthesis)
6. **Parse Layer 2 Output** - Cleans and returns structured JSON

**Expected Input (webhook POST body):**
```json
{
  "zip_code": "63365",
  "city": "New Melle",
  "county": "St. Charles County",
  "state": "Missouri",
  "exit_strategy": "Fix & Flip",
  "buy_box_criteria": {
    "property_types": ["SFR"],
    "price_min": 100000,
    "price_max": 500000
  }
}
```

**Expected Output (Layer 2 JSON):**
```json
{
  "zip_code": "63365",
  "city": "New Melle",
  "county": "St. Charles County",
  "state": "Missouri",
  "exit_strategy": "Fix & Flip",
  "signal_classification": "HIGH",
  "confidence": 0.85,
  "dominant_profiles": ["heirs", "absentee_out_of_state", "equity_rich"],
  "observed_combinations": [
    {
      "name": "Death + Absentee + High Equity",
      "prevalence": "high",
      "evidence": "Probate filings up 30%, out-of-state absentee 38%, free & clear 62%",
      "signal_strength": "strong",
      "relevance_to_strategy": "Heirs inheriting paid-off properties remotely are highly motivated to sell quickly."
    }
  ],
  "median_value": 285000,
  "lat": 38.7123,
  "lng": -90.8845,
  "insight": "Strong Fix & Flip signal driven by heirs inheriting paid-off properties out-of-state.",
  "reasoning": "Pattern 1: Death + Absentee + Equity (STRONG) - Agent 3 reported 45 probate filings..."
}
```

---

## TESTING

Once imported and API keys replaced:

**Test webhook URL:** https://propertysignalai.app.n8n.cloud/webhook/single-zip-phase1

**Test curl command:**
```bash
curl -X POST https://propertysignalai.app.n8n.cloud/webhook/single-zip-phase1 \
  -H "Content-Type: application/json" \
  -d '{
    "zip_code": "63365",
    "city": "New Melle",
    "county": "St. Charles County",
    "state": "Missouri",
    "exit_strategy": "Fix & Flip",
    "buy_box_criteria": {}
  }'
```

**Expected execution time:** ~60-90 seconds (5 Perplexity calls + 1 Claude call)

**Expected API cost per run:** ~$2-4
- Perplexity: 5 calls × ~$0.10-0.20 = $0.50-1.00
- Claude Opus: 1 call × ~$1.50-3.00 = $1.50-3.00

---

## TROUBLESHOOTING

**Issue: Webhook not found**
- Solution: Activate workflow in n8n UI

**Issue: API key errors**
- Solution: Verify API keys replaced correctly (no "APIINSERT" placeholders remaining)

**Issue: Perplexity rate limits**
- Solution: Add retry logic or sequential execution (currently parallel)

**Issue: Claude output not parsing**
- Solution: Check "Parse Layer 2 Output" node for markdown fence cleaning logic

---

## NEXT STEPS AFTER SUCCESSFUL IMPORT

1. Test with zip 63365 + Fix & Flip strategy
2. Verify all 5 agent responses return data
3. Verify Layer 2 output matches schema
4. Document token counts and execution time
5. Report results for Task 1 completion
