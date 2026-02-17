# TASK 2: EXECUTION SCRIPT - BASE44 ENTITIES

**Status:** Ready to build  
**Time:** 2-3 hours  
**Cost:** $0 (Base44 AI credits)

---

## 🏗️ BUILD SEQUENCE

### ENTITY 1: ZipResearch (Phase 1 Cache)

**Prompt for Base44 AI:**

```
Create entity called "ZipResearch" with these fields:

Text fields:
- zip_code (indexed, required)
- city (required)
- county (required)
- state (indexed, required)
- exit_strategy (indexed, required)
- cache_key (unique, required) - computed as zip_code + "_" + exit_strategy
- insight (text, long)
- reasoning (text, long)
- phase_1_error (text, optional)

Number fields:
- confidence (decimal, 0.0 to 1.0)
- median_value (number)
- lat (decimal)
- lng (decimal)

Enum fields:
- signal_classification (values: HIGH, LOW)
- phase_1_status (values: pending, processing, completed, failed)

Array fields:
- dominant_profiles (array of strings)

JSON fields:
- observed_combinations (JSON array)

DateTime fields:
- phase_1_started_at
- phase_1_completed_at
- expires_at (for TTL)
- last_accessed_at
- created_at (auto)
- updated_at (auto)

Indexes:
- Unique on: cache_key
- Query on: zip_code, state, exit_strategy, phase_1_status

Purpose: Stores Layer 2 analyst outputs (mosaic synthesis results) per zip + exit strategy combination. TTL default 30 days.
```

---

### ENTITY 2: ZipScoringFunctions (Phase 2 Cache)

**Prompt for Base44 AI:**

```
Create entity called "ZipScoringFunctions" with these fields:

Text fields:
- cache_key (unique, required, foreign key to ZipResearch.cache_key)
- zip_code (indexed, required)
- exit_strategy (indexed, required)
- compiled_functions_json (text, long) - complete function code as JSON
- function_version (text)
- phase_2_error (text, optional)

JSON fields:
- positive_criteria (JSON array)
- negative_criteria (JSON array)
- combination_patterns (JSON object)
- noise_filters (JSON array)
- temporal_patterns (JSON object)
- special_bonuses (JSON array)

Enum fields:
- phase_2_status (values: not_started, processing, completed, failed)

DateTime fields:
- phase_2_started_at
- phase_2_completed_at
- expires_at (for TTL)
- last_accessed_at
- created_at (auto)
- updated_at (auto)

Indexes:
- Unique on: cache_key
- Query on: zip_code, exit_strategy, phase_2_status

Purpose: Stores Layer 3 compiled scoring functions per zip + exit strategy. Independent TTL from Phase 1 (default 30 days).
```

---

### ENTITY 3: ZipProcessingLog (Audit Trail)

**Prompt for Base44 AI:**

```
Create entity called "ZipProcessingLog" with these fields:

Text fields:
- zip_code (indexed, required)
- exit_strategy (required)
- error_message (text, optional)

Enum fields:
- phase (values: phase_1, phase_2)
- status (values: started, completed, failed)

Number fields:
- duration_seconds (decimal)
- estimated_cost (decimal)

JSON fields:
- api_calls (JSON object with perplexity_count, claude_count)

DateTime fields:
- started_at (indexed)
- completed_at
- created_at (auto)

Indexes:
- Query on: zip_code, phase, status, started_at

Purpose: Audit trail for all processing attempts. Used for cost tracking, debugging, performance monitoring.
```

---

## 🔧 FUNCTIONS TO CREATE

### Function 1: savePhase1Output

**Prompt for Base44 AI:**

```
Create function "savePhase1Output" that:

Input parameters:
- zip_code (string)
- city (string)
- county (string)
- state (string)
- exit_strategy (string)
- layer_2_output (object with signal_classification, confidence, dominant_profiles, observed_combinations, median_value, lat, lng, insight, reasoning)
- ttl_days (number, default 30)

Logic:
1. Compute cache_key as ${zip_code}_${exit_strategy}
2. Check if ZipResearch record exists with this cache_key
3. If exists: Update all fields + reset expires_at to now + ttl_days
4. If not exists: Create new record with all fields
5. Set phase_1_status = 'completed'
6. Set phase_1_completed_at = now
7. Return: saved ZipResearch record

Purpose: Save Layer 2 analyst output to cache
```

---

### Function 2: getPhase1Output

**Prompt for Base44 AI:**

```
Create function "getPhase1Output" that:

Input parameters:
- zip_code (string)
- exit_strategy (string)

Logic:
1. Compute cache_key as ${zip_code}_${exit_strategy}
2. Query ZipResearch by cache_key
3. Check if record exists
4. If exists: Check if expires_at > now (not expired)
5. If expired: Return null
6. If valid: Update last_accessed_at = now
7. Return: ZipResearch record or null

Purpose: Retrieve cached Layer 2 output
```

---

### Function 3: savePhase2Output

**Prompt for Base44 AI:**

```
Create function "savePhase2Output" that:

Input parameters:
- cache_key (string)
- compiled_patterns (object with positive_criteria, negative_criteria, combination_patterns, noise_filters, temporal_patterns, special_bonuses)
- compiled_functions_json (string)
- function_version (string, default "1.0")
- ttl_days (number, default 30)

Logic:
1. Check if ZipScoringFunctions record exists with this cache_key
2. If exists: Update all fields + reset expires_at
3. If not exists: Create new record
4. Extract zip_code and exit_strategy from cache_key (split by "_")
5. Set phase_2_status = 'completed'
6. Set phase_2_completed_at = now
7. Return: saved ZipScoringFunctions record

Purpose: Save Layer 3 compiled functions to cache
```

---

### Function 4: getPhase2Output

**Prompt for Base44 AI:**

```
Create function "getPhase2Output" that:

Input parameters:
- zip_code (string)
- exit_strategy (string)

Logic:
1. Compute cache_key as ${zip_code}_${exit_strategy}
2. Query ZipScoringFunctions by cache_key
3. Check if record exists
4. If exists: Check if expires_at > now
5. If expired: Return null
6. If valid: Update last_accessed_at = now
7. Return: ZipScoringFunctions record or null

Purpose: Retrieve cached scoring functions
```

---

### Function 5: logProcessing

**Prompt for Base44 AI:**

```
Create function "logProcessing" that:

Input parameters:
- zip_code (string)
- exit_strategy (string)
- phase (enum: phase_1, phase_2)
- status (enum: started, completed, failed)
- api_calls (object, optional)
- estimated_cost (number, optional)
- error_message (string, optional)
- duration_seconds (number, optional)

Logic:
1. Create new ZipProcessingLog record with all parameters
2. Set started_at = now if status = 'started'
3. Set completed_at = now if status = 'completed' or 'failed'
4. Return: log entry ID

Purpose: Log processing attempt for audit trail
```

---

### Function 6: getZipsByExitStrategy

**Prompt for Base44 AI:**

```
Create function "getZipsByExitStrategy" that:

Input parameters:
- exit_strategy (string)
- status (enum: completed, optional filter)
- limit (number, default 50)

Logic:
1. Query ZipResearch filtered by exit_strategy
2. If status provided: Also filter by phase_1_status
3. Order by created_at desc
4. Limit results to specified limit
5. Return: array of ZipResearch records

Purpose: List all researched zips for a given exit strategy
```

---

## 🧪 TESTING CHECKLIST

After building all entities + functions, test:

### Test 1: Save and Retrieve Phase 1
```javascript
// Test in Base44 function tester
await savePhase1Output({
  zip_code: "63365",
  city: "New Melle",
  county: "St. Charles County",
  state: "Missouri",
  exit_strategy: "Fix & Flip",
  layer_2_output: {
    signal_classification: "HIGH",
    confidence: 0.85,
    dominant_profiles: ["heirs", "absentee"],
    observed_combinations: [{"name": "Death + Absentee", "prevalence": "high"}],
    median_value: 285000,
    lat: 38.7123,
    lng: -90.8845,
    insight: "Test insight",
    reasoning: "Test reasoning"
  }
})

// Retrieve
await getPhase1Output({ zip_code: "63365", exit_strategy: "Fix & Flip" })
// Expected: Returns saved data
```

### Test 2: Cache Miss
```javascript
await getPhase1Output({ zip_code: "63365", exit_strategy: "Wholesale" })
// Expected: Returns null (no cache for this combo)
```

### Test 3: Multiple Exit Strategies
```javascript
// Save same zip with different strategy
await savePhase1Output({
  zip_code: "63365",
  exit_strategy: "Wholesale",
  layer_2_output: { signal_classification: "LOW", confidence: 0.45, /* ... */ }
})

// Verify both cached independently
await getPhase1Output({ zip_code: "63365", exit_strategy: "Fix & Flip" })
// Expected: Returns Fix & Flip data

await getPhase1Output({ zip_code: "63365", exit_strategy: "Wholesale" })
// Expected: Returns Wholesale data
```

### Test 4: Logging
```javascript
await logProcessing({
  zip_code: "63365",
  exit_strategy: "Fix & Flip",
  phase: "phase_1",
  status: "completed",
  api_calls: { perplexity_count: 5, claude_count: 1 },
  estimated_cost: 2.50
})
// Expected: Creates log entry
```

---

## 📊 SUCCESS CRITERIA

**From Playbook:**
- ✅ Entities created with proper schemas
- ✅ Functions for save/retrieve by cache key
- ✅ Manual test: Save and retrieve sample data for zip 63365
- ✅ Verify cache key lookup works
- ✅ Report: Entity schemas, test results, screenshots

---

## 📁 DELIVERABLES

After completion:
1. 3 Base44 entities created
2. 6 Base44 functions created
3. Test results documented
4. Entity schemas exported to JSON (if possible)
5. Screenshots of Base44 entities + functions
6. Commit to GitHub

---

**Ready to execute when Base44 tab attached**  
**ETA:** 2-3 hours from start
