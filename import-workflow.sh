#!/bin/bash

N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1YjVkN2E4NC0yZDQ1LTRkZDAtYjMyZS03NTQ4OTllMTY1NWIiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNWU4ODcwNTgtM2U0OC00OTg4LWE1MTQtMmY0OGNjYTlhMmUyIiwiaWF0IjoxNzcxMzE4NzMzfQ.auYA2SkWRuRWNcJhOzDlUJFrHp7AR4tqedAaDrjdQvY"
N8N_BASE_URL="https://propertysignalai.app.n8n.cloud/api/v1"

# Load workflow JSON
WORKFLOW_JSON=$(cat n8n-workflows/task1-single-zip-phase1.json)

# Import workflow
curl -X POST "$N8N_BASE_URL/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$WORKFLOW_JSON" \
  -v

