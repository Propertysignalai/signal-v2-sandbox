# TASK 2: BASE44 SCHEMA + STORAGE - EXECUTION PLAN

**Estimated Time:** 2-4 hours  
**Testing Cost:** $0 (no API calls)  
**Status:** Ready to build

---

## 📋 REQUIREMENTS (From Playbook)

1. Create Base44 entities for storing Phase 1 and Phase 2 outputs
2. Define schema for per-zip research cache (Layer 2 outputs)
3. Define schema for per-zip scoring function cache (Layer 3 outputs)
4. Include cache key structure (zip + exit strategy), TTL fields, status tracking
5. Functions for saving and retrieving cached data by zip + exit strategy

---

## 🏗️ ENTITY SCHEMAS TO CREATE

### Entity 1: ZipResearch (Phase 1 Cache)

**Purpose:** Stores Layer 2 analyst outputs per zip + exit strategy combination

**Fields:**
```json
{
  "zip_code": "string (indexed)",
  "city": "string",
  "county": "string",
  "state": "string (indexed)",
  "exit_strategy": "string (indexed)",
  "cache_key": "string (unique, computed: zip_code + '_' + exit_strategy)",
  
  "signal_classification": "enum: HIGH, LOW",
  "confidence": "number (0.0-1.0)",
  "dominant_profiles": "array<string>",
  "observed_combinations": "json (array of combination objects)",
  "median_value": "number",
  "lat": "number",
  "lng": "number",
  "insight": "text",
  "reasoning": "text",
  
  "phase_1_status": "enum: pending, processing, completed, failed",
  "phase_1_started_at": "datetime",
  "phase_1_completed_at": "datetime",
  "phase_1_error": "text (optional)",
  
  "created_at": "datetime (auto)",
  "expires_at": "datetime (TTL)",
  "last_accessed_at": "datetime"
}
```

**Indexes:**
- Unique: cache_key
- Query: zip_code, state, exit_strategy, phase_1_status

**TTL:** 30 days default (configurable)

---

### Entity 2: ZipScoringFunctions (Phase 2 Cache)

**Purpose:** Stores Layer 3 compiled scoring functions per zip + exit strategy

**Fields:**
```json
{
  "cache_key": "string (foreign key to ZipResearch.cache_key)",
  "zip_code": "string (indexed)",
  "exit_strategy": "string (indexed)",
  
  "positive_criteria": "json (array)",
  "negative_criteria": "json (array)",
  "combination_patterns": "json (object with 2/3/4+ factor arrays)",
  "noise_filters": "json (array)",
  "temporal_patterns": "json (object with high/medium arrays)",
  "special_bonuses": "json (array)",
  
  "compiled_functions_json": "text (complete function code as JSON)",
  "function_version": "string",
  
  "phase_2_status": "enum: not_started, processing, completed, failed",
  "phase_2_started_at": "datetime",
  "phase_2_completed_at": "datetime",
  "phase_2_error": "text (optional)",
  
  "created_at": "datetime (auto)",
  "expires_at": "datetime (TTL)",
  "last_accessed_at": "datetime"
}
```

**Indexes:**
- Unique: cache_key
- Query: zip_code, exit_strategy, phase_2_status

**TTL:** 30 days default (independent from Phase 1)

---

### Entity 3: ZipProcessingLog (Audit Trail)

**Purpose:** Tracks all processing attempts for debugging + cost tracking

**Fields:**
```json
{
  "zip_code": "string (indexed)",
  "exit_strategy": "string",
  "phase": "enum: phase_1, phase_2",
  "status": "enum: started, completed, failed",
  "started_at": "datetime",
  "completed_at": "datetime",
  "duration_seconds": "number",
  "error_message": "text (optional)",
  "api_calls": "json (object with perplexity_count, claude_count)",
  "estimated_cost": "number"
}
```

**Indexes:**
- Query: zip_code, phase, status, started_at

**Purpose:** Cost tracking, debugging, performance monitoring

---

## 🔧 BASE44 FUNCTIONS TO CREATE

### Function 1: savePhase1Output
**Purpose:** Save Layer 2 analyst output to ZipResearch entity

**Input:**
```json
{
  "zip_code": "63365",
  "city": "New Melle",
  "county": "St. Charles County",
  "state": "Missouri",
  "exit_strategy": "Fix & Flip",
  "layer_2_output": { /* full Layer 2 JSON */ },
  "ttl_days": 30
}
```

**Logic:**
1. Compute cache_key: `${zip_code}_${exit_strategy}`
2. Check if record exists
3. If exists: update + reset expires_at
4. If new: create with all fields
5. Set phase_1_status = 'completed'
6. Return: saved record

---

### Function 2: getPhase1Output
**Purpose:** Retrieve cached Layer 2 output by zip + exit strategy

**Input:**
```json
{
  "zip_code": "63365",
  "exit_strategy": "Fix & Flip"
}
```

**Logic:**
1. Compute cache_key
2. Query ZipResearch by cache_key
3. Check expires_at (if expired, return null)
4. Update last_accessed_at
5. Return: Layer 2 output or null

---

### Function 3: savePhase2Output
**Purpose:** Save Layer 3 compiled functions to ZipScoringFunctions entity

**Input:**
```json
{
  "cache_key": "63365_Fix & Flip",
  "compiled_patterns": { /* positive, negative, combinations, noise, etc. */ },
  "compiled_functions_json": "{ /* full function code */ }",
  "ttl_days": 30
}
```

**Logic:**
1. Check if record exists for cache_key
2. If exists: update + reset expires_at
3. If new: create with all fields
4. Set phase_2_status = 'completed'
5. Return: saved record

---

### Function 4: getPhase2Output
**Purpose:** Retrieve cached scoring functions by zip + exit strategy

**Input:**
```json
{
  "zip_code": "63365",
  "exit_strategy": "Fix & Flip"
}
```

**Logic:**
1. Compute cache_key
2. Query ZipScoringFunctions by cache_key
3. Check expires_at (if expired, return null)
4. Update last_accessed_at
5. Return: compiled functions or null

---

### Function 5: logProcessing
**Purpose:** Log processing attempt to ZipProcessingLog

**Input:**
```json
{
  "zip_code": "63365",
  "exit_strategy": "Fix & Flip",
  "phase": "phase_1",
  "status": "started",
  "api_calls": { "perplexity_count": 5, "claude_count": 1 },
  "estimated_cost": 2.50,
  "error_message": null
}
```

**Logic:**
1. Create log entry
2. If status = 'started': record start time
3. If status = 'completed' or 'failed': record end time, calculate duration
4. Return: log entry ID

---

### Function 6: getZipsByExitStrategy
**Purpose:** List all researched zips for a given exit strategy

**Input:**
```json
{
  "exit_strategy": "Fix & Flip",
  "status": "completed",
  "limit": 50
}
```

**Logic:**
1. Query ZipResearch filtered by exit_strategy + phase_1_status
2. Order by created_at desc
3. Return: array of zip records

---

## 🧪 TESTING PLAN

### Test 1: Save and Retrieve Phase 1
```javascript
// Save
savePhase1Output({
  zip_code: "63365",
  exit_strategy: "Fix & Flip",
  layer_2_output: { signal_classification: "HIGH", confidence: 0.85, /* ... */ }
})

// Retrieve
getPhase1Output({ zip_code: "63365", exit_strategy: "Fix & Flip" })
// Expected: Returns saved output

// Retrieve with wrong key
getPhase1Output({ zip_code: "63365", exit_strategy: "Wholesale" })
// Expected: Returns null (cache miss)
```

### Test 2: Cache Expiration
```javascript
// Save with short TTL
savePhase1Output({ ..., ttl_days: 0.00001 }) // ~1 second

// Wait 2 seconds
setTimeout(() => {
  getPhase1Output({ ... })
  // Expected: Returns null (expired)
}, 2000)
```

### Test 3: Multiple Exit Strategies
```javascript
// Save same zip with 2 different strategies
savePhase1Output({ zip_code: "63365", exit_strategy: "Fix & Flip", ... })
savePhase1Output({ zip_code: "63365", exit_strategy: "Wholesale", ... })

// Retrieve both
getPhase1Output({ zip_code: "63365", exit_strategy: "Fix & Flip" })
getPhase1Output({ zip_code: "63365", exit_strategy: "Wholesale" })
// Expected: Both return independently cached results
```

---

## 📊 SUCCESS CRITERIA (From Playbook)

**Deliverable:** Base44 entities with proper schemas ✅
- ZipResearch (Phase 1 cache)
- ZipScoringFunctions (Phase 2 cache)
- ZipProcessingLog (audit trail)

**Deliverable:** Functions for save/retrieve by cache key ✅
- savePhase1Output, getPhase1Output
- savePhase2Output, getPhase2Output
- logProcessing, getZipsByExitStrategy

**Test:** Manually save and retrieve sample Layer 2 output for zip 63365 ✅
- Verify lookup by cache key works
- Verify TTL expiration works
- Verify independent caching per exit strategy

**Report:** ✅
- Entity schemas documented
- Sample data stored and retrieved
- Any Base44 limitations encountered

---

## 🚀 EXECUTION STEPS (Morning Session)

1. **Open Base44 SigV2 environment**
2. **Create Entity 1: ZipResearch**
   - Use Base44 AI: "Create entity ZipResearch with fields: [paste schema]"
   - Verify indexes created
3. **Create Entity 2: ZipScoringFunctions**
   - Use Base44 AI: "Create entity ZipScoringFunctions with fields: [paste schema]"
   - Verify foreign key to ZipResearch.cache_key
4. **Create Entity 3: ZipProcessingLog**
   - Use Base44 AI: "Create entity ZipProcessingLog for audit trail"
5. **Create Function 1-6**
   - Use Base44 AI for each function
   - Test each function after creation
6. **Run Test Suite**
   - Execute all 3 test scenarios
   - Document results
7. **Screenshot entities + test results**
8. **Commit schemas to GitHub**

**Estimated Time:** 2-3 hours (entities + functions + testing)

---

## 💰 COST ESTIMATE

**Building:** $0 (Base44 AI credits, resets monthly)  
**Testing:** $0 (no external API calls)  
**Total:** $0

---

## 📁 DELIVERABLES

1. 3 Base44 entities created
2. 6 Base44 functions created
3. Test results documented
4. Entity schemas exported to JSON
5. Screenshots of Base44 UI
6. GitHub commit with schemas

---

**Status:** Plan complete, ready to execute in morning session  
**Next:** Morning report will include Task 2 completion + Task 1 status
