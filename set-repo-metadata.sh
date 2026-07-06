#!/usr/bin/env bash
# Sets description + topics on every Diabloansh repo.
# Usage:
#   export GH_TOKEN=ghp_xxx   # token with `repo` scope
#   bash set-repo-metadata.sh
# Falls back to `gh api` if GH_TOKEN is unset and gh is authenticated.
set -euo pipefail

OWNER="Diabloansh"

# repo | description | comma-separated topics
read -r -d '' ROWS <<'EOF' || true
Khaata_PersonalFinance_App|Privacy-first personal-finance copilot: turns messy bank/UPI PDFs into a grounded, queryable ledger with a function-calling LLM agent where every number traces back to its transactions. Runs locally.|llm,rag,ai-agent,personal-finance,ollama,function-calling,fintech,docker,python
CapstoneProject_MisinformationProject|DistilBERT multi-label classifier that detects the psychological manipulation mechanisms in misinformation headlines (ELM + cognitive biases). Macro-F1 73%, ROC-AUC 91%.|nlp,transformers,distilbert,misinformation,multi-label-classification,pytorch,machine-learning,psychology
YelpWrapped|A 'Spotify Wrapped' for your Yelp history: a Neo4j graph of users, businesses and reviews surfacing taste clusters, sentiment trends and influence scoring via a Next.js UI.|neo4j,graph-database,nextjs,cypher,data-visualization,sentiment-analysis,pagerank
SpeedReader_BrowserExtension|Manifest V3 browser extension that speed-reads any webpage with RSVP and Optimal Recognition Point highlighting, inside an isolated Shadow-DOM overlay.|browser-extension,manifest-v3,chrome-extension,javascript,rsvp,speed-reading,productivity
Game_PianoTiles|iOS rhythm game in Swift and SpriteKit: JSON beatmap-driven gameplay, audio-clock-synced tiles, three-level progression, combos and visual polish.|swift,spritekit,ios,game-development,rhythm-game,ios-game
CollaborativeEditor|Real-time collaborative text editor with Django and Django Channels: simultaneous editing over WebSockets, version history, sharing and rich-text formatting.|django,django-channels,websockets,collaborative-editing,real-time,python
WebscrapingScript|E-commerce product scraper using Scrapy and Playwright to extract metadata, imagery and variants from JavaScript-heavy storefronts into one clean schema.|web-scraping,scrapy,playwright,python,etl,ecommerce,data-engineering
HR_EmployeePromotion_Prediction|Random Forest built from scratch in NumPy to predict employee promotions across 54k records, with class-imbalance handling and F1 optimization.|machine-learning,random-forest,numpy,from-scratch,classification,imbalanced-data,jupyter-notebook
NYC_Taxi_PredictionModel|End-to-end ML pipeline predicting NYC taxi trip duration over ~1.4M rides: EDA, feature engineering, deep neural nets and ensemble models with hyperparameter tuning.|machine-learning,regression,deep-learning,feature-engineering,ensemble-learning,jupyter-notebook
ImageSegmentation_Birds|Two-stage computer-vision pipeline: Segment Anything (SAM) for segmentation plus a custom CNN/ResNet50 classifier to identify 25 bird species in one image.|computer-vision,image-segmentation,tensorflow,cnn,resnet,deep-learning
EOF

# JSON-escape a string (quotes + backslashes).
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

api() { # api METHOD PATH JSON_BODY
  local method="$1" path="$2" body="$3"
  if [ -n "${GH_TOKEN:-}" ]; then
    curl -sS -X "$method" \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com$path" -d "$body" >/dev/null
  else
    printf '%s' "$body" | gh api -X "$method" "$path" --input - >/dev/null
  fi
}

while IFS='|' read -r repo desc topics; do
  [ -z "$repo" ] && continue
  echo "→ $repo"
  # description
  api PATCH "/repos/$OWNER/$repo" "{\"description\":\"$(esc "$desc")\"}"
  # topics (array)
  local_json='{"names":['
  IFS=',' read -ra arr <<< "$topics"
  for i in "${!arr[@]}"; do
    [ "$i" -gt 0 ] && local_json+=','
    local_json+="\"${arr[$i]}\""
  done
  local_json+=']}'
  api PUT "/repos/$OWNER/$repo/topics" "$local_json"
  echo "  ✓ description + ${#arr[@]} topics"
done <<< "$ROWS"

echo "Done."
