# TASK 2: Base44 Entity Schemas for Signal v2.0

**Created:** 2026-02-17  
**Purpose:** Define caching entities for Phase 1 (research agent outputs) and Phase 2 (Layer 2 synthesis outputs)

---

## Overview

Signal v2.0 uses a two-phase pipeline per zip code:

1. **Phase 1 — Research Agents:** 5 Perplexity-powered agents each produce structured research output for a zip code
2. **Phase 2 — Layer 2 Synthesis:** Claude synthesizes the 5 agent outputs into a signal classification with scoring intelligence

Two Base44 entities cache these outputs, linked by `run_id`:

```
ZipResearchCache (Phase 1)  ←—[run_id]—→  ZipSynthesisCache (Phase 2)
```

---

## Entity 1: ZipResearchCache

**Purpose:** Stores the 5 individual research agent outputs per zip code run. This is the raw Phase 1 data before synthesis.

### Fields

| # | Field Name | Type | Required | Description | Validation |
|---|-----------|------|----------|-------------|------------|
| 1 | `zip_code` | String | ✅ | 5-digit US zip code | Pattern: `^\d{5}$` |
| 2 | `city` | String | ✅ | City name | — |
| 3 | `county` | String | ✅ | County name | — |
| 4 | `state` | String | ✅ | State name or abbreviation | — |
| 5 | `run_id` | String | ✅ | Unique identifier for this research run | Format: `{zip}_{timestamp}` or UUID. **Indexed, unique.** |
| 6 | `run_timestamp` | DateTime | ✅ | When this research run started | Auto-set on creation |
| 7 | `agent_1_output` | JSON | ❌ | **Distress & Motivation Analyst** output — foreclosures, tax delinquency, vacancy, code violations, eviction trends | Valid JSON object |
| 8 | `agent_2_output` | JSON | ❌ | **Ownership & Transfer Pattern Analyst** output — ownership duration, absentee rates, estate/probate transfers, corporate ownership, turnover velocity | Valid JSON object |
| 9 | `agent_3_output` | JSON | ❌ | **Demographic & Economic Pressure Analyst** output — income shifts, population migration, age demographics, employment changes, affordability stress | Valid JSON object |
| 10 | `agent_4_output` | JSON | ❌ | **Property & Equity Profile Analyst** output — property age, equity accumulation, assessed vs market values, property types, tax burden, entity ownership patterns | Valid JSON object |
| 11 | `agent_5_output` | JSON | ❌ | **Market Dynamics & Momentum Analyst** output — market direction, zoning changes, employer activity, infrastructure, days on market, price trends | Valid JSON object |
| 12 | `status` | String | ✅ | Processing status of this run | Enum: `pending`, `running`, `completed`, `partial`, `failed` |
| 13 | `perplexity_cost_estimate` | Number | ❌ | Estimated cost of the 5 Perplexity API calls in USD | ≥ 0 |

### Indexes

- **Unique:** `run_id`
- **Query:** `zip_code`, `state`, `status`

### Notes

- Agent outputs are optional because agents run in parallel — a `partial` status means some succeeded while others failed.
- Each agent output JSON should follow a consistent structure (to be defined in agent prompt engineering), but the schema is flexible to allow iteration.
- `status` values:
  - `pending` — run created, agents not yet dispatched
  - `running` — agents dispatched, awaiting results
  - `completed` — all 5 agents returned successfully
  - `partial` — some agents returned, others failed
  - `failed` — critical failure, no usable output

---

## Entity 2: ZipSynthesisCache

**Purpose:** Stores the Layer 2 analyst synthesis output — the combined intelligence produced by Claude from the 5 research agent outputs.

### Fields

| # | Field Name | Type | Required | Description | Validation |
|---|-----------|------|----------|-------------|------------|
| 1 | `zip_code` | String | ✅ | 5-digit US zip code | Pattern: `^\d{5}$` |
| 2 | `city` | String | ✅ | City name | — |
| 3 | `county` | String | ✅ | County name | — |
| 4 | `state` | String | ✅ | State name or abbreviation | — |
| 5 | `exit_strategy` | String | ✅ | The exit strategy this synthesis was produced for | e.g., `Fix & Flip`, `Wholesale`, `Buy & Hold`, `Creative Finance` |
| 6 | `run_id` | String | ✅ | References `ZipResearchCache.run_id` — links to the Phase 1 data this synthesis was built from | Must match an existing ZipResearchCache.run_id |
| 7 | `run_timestamp` | DateTime | ✅ | When this synthesis was produced | Auto-set on creation |
| 8 | `signal_classification` | String | ✅ | Binary signal classification | Enum: `HIGH`, `LOW` |
| 9 | `confidence` | Number | ✅ | Confidence score for the classification | Range: 0.0–1.0 |
| 10 | `dominant_profiles` | JSON | ✅ | Array of dominant seller profiles identified | JSON array of strings, e.g., `["heirs", "absentee", "corporate"]` |
| 11 | `observed_combinations` | JSON | ✅ | Signal combinations actually present in this zip with evidence | JSON array of objects: `[{"name": "...", "prevalence": "...", "evidence": "..."}]` |
| 12 | `median_value` | Number | ✅ | Median home value in this zip | > 0 |
| 13 | `lat` | Number | ✅ | Latitude for map pin placement | Range: -90 to 90 |
| 14 | `lng` | Number | ✅ | Longitude for map pin placement | Range: -180 to 180 |
| 15 | `insight` | String (Long Text) | ✅ | Human-readable summary of the zip's signal profile | — |
| 16 | `reasoning` | String (Long Text) | ✅ | Detailed reasoning behind the classification | — |
| 17 | `full_output` | JSON | ❌ | Complete raw Layer 2 output JSON (for debugging/reprocessing) | Valid JSON object |
| 18 | `claude_cost_estimate` | Number | ❌ | Estimated cost of the Claude synthesis call in USD | ≥ 0 |

### Indexes

- **Composite unique:** `zip_code` + `exit_strategy` (one synthesis per zip per strategy)
- **Query:** `zip_code`, `state`, `exit_strategy`, `signal_classification`
- **Foreign key:** `run_id` → `ZipResearchCache.run_id`

### Cache Key

The effective cache key is `{zip_code}_{exit_strategy}`. The same zip can have different synthesis outputs for different exit strategies (e.g., a zip might be HIGH for Fix & Flip but LOW for Wholesale).

---

## Entity Relationship

```
┌─────────────────────┐         ┌──────────────────────┐
│  ZipResearchCache   │         │  ZipSynthesisCache   │
│  (Phase 1)          │         │  (Phase 2)           │
├─────────────────────┤         ├──────────────────────┤
│  run_id (PK/unique) │◄────────│  run_id (FK)         │
│  zip_code           │         │  zip_code            │
│  agent_1..5_output  │         │  exit_strategy       │
│  status             │         │  signal_classification│
│  ...                │         │  confidence          │
└─────────────────────┘         │  dominant_profiles   │
                                │  ...                 │
                                └──────────────────────┘

Relationship: One ZipResearchCache → Many ZipSynthesisCache
(Same research data can be synthesized for multiple exit strategies)
```

---

## Step-by-Step: Creating These Entities in Base44

### Prerequisites

- Access to the **SigV2 Base44 environment** (app.base44.com)
- Admin or developer permissions on the project

### Option A: Using Base44 AI (Recommended)

Base44's AI entity builder can create entities from natural language prompts.

#### Step 1: Create ZipResearchCache

Navigate to the Base44 project → Entities → click **"+ New Entity"** or open the AI assistant.

**Prompt to paste:**

```
Create an entity called "ZipResearchCache" with these fields:

- zip_code: text, required, indexed — 5-digit US zip code
- city: text, required
- county: text, required
- state: text, required, indexed
- run_id: text, required, unique index — unique identifier for this research run
- run_timestamp: datetime, required
- agent_1_output: JSON, optional — Distress & Motivation Analyst output
- agent_2_output: JSON, optional — Ownership & Transfer Pattern Analyst output
- agent_3_output: JSON, optional — Demographic & Economic Pressure Analyst output
- agent_4_output: JSON, optional — Property & Equity Profile Analyst output
- agent_5_output: JSON, optional — Market Dynamics & Momentum Analyst output
- status: text, required — enum values: pending, running, completed, partial, failed
- perplexity_cost_estimate: number, optional — estimated API cost in USD

Purpose: Cache for Phase 1 research agent outputs per zip code run.
```

#### Step 2: Create ZipSynthesisCache

**Prompt to paste:**

```
Create an entity called "ZipSynthesisCache" with these fields:

- zip_code: text, required, indexed — 5-digit US zip code
- city: text, required
- county: text, required
- state: text, required, indexed
- exit_strategy: text, required, indexed — e.g. "Fix & Flip", "Wholesale"
- run_id: text, required — foreign key referencing ZipResearchCache.run_id
- run_timestamp: datetime, required
- signal_classification: text, required — enum values: HIGH, LOW
- confidence: number, required — decimal 0.0 to 1.0
- dominant_profiles: JSON, required — array of seller profile strings
- observed_combinations: JSON, required — array of signal combination objects
- median_value: number, required — median home value
- lat: number, required — latitude
- lng: number, required — longitude
- insight: long text, required — human-readable summary
- reasoning: long text, required — detailed classification reasoning
- full_output: JSON, optional — complete raw Layer 2 output
- claude_cost_estimate: number, optional — estimated API cost in USD

Add a composite unique constraint on zip_code + exit_strategy.

Purpose: Cache for Phase 2 Layer 2 synthesis outputs per zip code and exit strategy.
```

#### Step 3: Verify

After creation:
1. Open each entity in the Base44 entity viewer
2. Confirm all fields exist with correct types
3. Verify indexes are set (unique on `run_id` for ZipResearchCache, composite unique on `zip_code` + `exit_strategy` for ZipSynthesisCache)
4. Test by manually creating one record in each entity

### Option B: Using the Entity Builder UI

If the AI assistant doesn't create fields correctly, use the manual entity builder:

1. **Entities → + New Entity → Name it**
2. **Add fields one by one** using the field type dropdowns
3. For JSON fields: select "JSON" or "Object" type (Base44 may call it differently — check available types)
4. For long text: select "Long Text" or "Text Area" type
5. For enums: use a text field and enforce values in application logic (Base44 may support enum as a type)
6. Set required/optional per field
7. Add indexes via the entity settings

### Step 4: Create Test Data

After entities exist, test with sample data:

```json
// ZipResearchCache test record
{
  "zip_code": "63365",
  "city": "New Melle",
  "county": "St. Charles County",
  "state": "Missouri",
  "run_id": "63365_20260217_001",
  "run_timestamp": "2026-02-17T10:00:00Z",
  "agent_1_output": {"foreclosure_rate": "1.2%", "tax_delinquency": "3.5%"},
  "agent_2_output": {"absentee_rate": "12%", "avg_ownership_years": 14},
  "agent_3_output": {"population_trend": "growing", "median_income": 78000},
  "agent_4_output": {"median_equity_pct": 0.65, "avg_property_age": 25},
  "agent_5_output": {"dom_trend": "decreasing", "price_trend": "increasing"},
  "status": "completed",
  "perplexity_cost_estimate": 0.50
}
```

```json
// ZipSynthesisCache test record
{
  "zip_code": "63365",
  "city": "New Melle",
  "county": "St. Charles County",
  "state": "Missouri",
  "exit_strategy": "Fix & Flip",
  "run_id": "63365_20260217_001",
  "run_timestamp": "2026-02-17T10:05:00Z",
  "signal_classification": "HIGH",
  "confidence": 0.85,
  "dominant_profiles": ["heirs", "absentee", "distressed"],
  "observed_combinations": [
    {"name": "Death + Absentee", "prevalence": "high", "evidence": "12% absentee rate with aging ownership"},
    {"name": "Tax Delinquency + Low Equity", "prevalence": "medium", "evidence": "3.5% delinquency in older properties"}
  ],
  "median_value": 285000,
  "lat": 38.7123,
  "lng": -90.8845,
  "insight": "Strong motivated seller signals driven by aging ownership and absentee patterns in a growing suburban market.",
  "reasoning": "High absentee rate (12%) combined with long ownership duration (14yr avg) and moderate tax delinquency (3.5%) creates multi-layered distress signals. Growing population and decreasing DOM indicate a market where distressed properties can be acquired and flipped profitably.",
  "full_output": {},
  "claude_cost_estimate": 0.15
}
```

---

## Base44-Specific Notes

1. **JSON fields:** Base44 supports JSON/Object field types. Store complex nested data (agent outputs, arrays) as JSON. No need to flatten into separate fields.

2. **Indexing:** Base44 supports field-level indexing. Mark `zip_code`, `state`, `exit_strategy`, `run_id`, and `signal_classification` as indexed for query performance.

3. **Unique constraints:** If Base44 doesn't support composite unique constraints natively, enforce `zip_code + exit_strategy` uniqueness in application logic (check-before-write in the save function).

4. **Long text fields:** `insight` and `reasoning` may be lengthy. Use Base44's long text / text area field type rather than standard text (which may have length limits).

5. **Auto-timestamps:** Base44 entities typically auto-create `created_at` and `updated_at` fields. Use `run_timestamp` as the application-level timestamp; rely on Base44's auto fields for record-level tracking.

6. **TTL / Expiration:** These schemas don't include TTL fields. If cache expiration is needed, add an `expires_at` DateTime field and check it in retrieval functions. For v2.0 initial build, 30-day TTL is planned (see TASK2-PLAN.md).

7. **Entity naming:** Base44 may auto-pluralize or format entity names. Use `ZipResearchCache` and `ZipSynthesisCache` as-is; adjust if the platform requires different conventions.

---

## Relationship to Other Entities (Future)

These two entities will eventually connect to the broader Signal v2.0 data model:

- **ZipScoringFunctions** (Phase 2 / Layer 3 cache) — compiled scoring functions per zip + exit strategy, references `ZipSynthesisCache`
- **ZipProcessingLog** — audit trail for all processing attempts, cost tracking
- **PropertyList** — client-uploaded property lists that reference researched zips

These are defined in TASK2-PLAN.md and will be built after the core cache entities are validated.
