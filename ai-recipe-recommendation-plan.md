# AI-Driven User-Tailored Recipe Recommendations

Date: 2026-03-15

## 1. Product goals

- Learn from post-cook feedback (rating + notes) and improve future recommendations.
- Recommend both:
  - Existing user-owned recipes.
  - Newly discovered recipes imported from the web.
- Optimize for pantry usage, especially soon-to-expire items.
- Use automated backend processing for heavy work.
- Keep AI usage conservative, low-cost, and durable over time.

## 2. Non-goals for v1

- No chat assistant loop for every recommendation request.
- No expensive real-time LLM ranking at request time.
- No full vector database dependency for initial release.

## 3. Important domain distinction

The existing recipe notes field should not be treated as the primary learning signal for recommendations.

Current intended use of recipe notes:

- Supplemental recipe knowledge.
- Tips, caveats, substitutions, or reminders that improve the recipe itself.
- Information that should remain attached to the recipe record.

Recommended use of user feedback instead:

- Intentional post-cook reflection captured as a separate interaction.
- A clear answer to questions like:
  - Did the user enjoy it?
  - Would they make it again?
  - What worked or did not work for them personally?
  - Was it too much effort, too salty, too bland, too expensive, too slow, or otherwise mismatched?

This separation matters because recipe notes are effectively recipe metadata, while recommendation learning needs user-outcome data.

Recommended rule:

- Keep recipe.notes for recipe-improving annotations.
- Introduce dedicated post-cook feedback records for recommendation learning.

## 4. Recommended architecture

### 4.1 Core flow

1. User cooks a recipe and leaves feedback.
2. Feedback is stored as an immutable event.
3. Background jobs extract structured signals from note text (AI only once per changed note).
4. User taste profile is updated from events.
5. Candidate recipes are built from two pools:
   - Local recipes.
   - Web-discovered candidates.
6. Deterministic scorer ranks recipes (fast and explainable).
7. Final recommendations are stored and served quickly.

### 4.2 Why this works here

- Existing feedback fields already exist on recipes.
- Existing import pipeline can support web discovery ingestion.
- Existing ActiveJob setup supports background processing.
- Existing AI extraction pattern can be reused for note parsing style.

### 4.3 Updated recommendation about existing recipe fields

The current recipe-level fields can still be useful, but they should play different roles:

- recipe.notes:
  - Preserve as recipe support content.
  - Consider relabeling in the UI to "Recipe tips" or "Cookbook notes" to reduce ambiguity.
- recipe.rating:
  - Can remain as a lightweight convenience field showing a current summary opinion.
  - Should not be the only historical learning signal.

Recommended implementation pattern:

- Keep recipe.notes and recipe.rating on recipes for editing and quick display.
- Add recipe_feedback_events as the durable recommendation-learning source.
- Optionally derive the displayed recipe.rating from the latest feedback event or a rolling aggregate later.

## 5. Data model draft

Add these tables in phases.

### 5.1 Feedback events

Table: recipe_feedback_events

- id
- user_id (FK, required, indexed)
- recipe_id (FK, required, indexed)
- cooked_at (datetime, required)
- rating (integer, optional)
- note_text (text, optional)
- overall_outcome (string, optional) # loved, liked, neutral, disliked
- would_make_again (boolean, optional)
- would_change_anything (boolean, optional)
- feedback_context (string, optional) # weeknight, guests, meal_prep, special_occasion
- prep_time_actual_minutes (integer, optional)
- cook_time_actual_minutes (integer, optional)
- used_pantry_items (jsonb, default: [])
- missing_ingredients (jsonb, default: [])
- created_at, updated_at

Indexes:

- [user_id, cooked_at]
- [user_id, recipe_id, cooked_at]

Purpose:

- Immutable source of learning truth.
- Preserves historical feedback even if recipe fields change later.
- Keeps recommendation inputs separate from recipe-maintenance notes.

Suggested UX for v1 feedback form:

- Rating
- Would make again?
- What did you think?
- What would you change next time?
- Optional actual prep/cook time

The free-text fields can be combined into note_text for storage initially, but they should come from an intentional post-cook flow rather than the recipe edit form.

### 5.2 AI note insights (deduped)

Table: feedback_note_insights

- id
- user_id (FK, required, indexed)
- recipe_feedback_event_id (FK, required, unique)
- note_sha256 (string, required, indexed)
- model_name (string, required)
- prompt_version (string, required)
- sentiment_score (decimal(4,3), optional)
- likes (jsonb, default: [])
- dislikes (jsonb, default: [])
- substitutions (jsonb, default: [])
- effort_signal (string, optional)  # easy, medium, hard
- extracted_payload (jsonb, default: {})
- created_at, updated_at

Purpose:

- Query AI exactly once per note hash + prompt version.
- Structured tags become deterministic ranking inputs.

### 5.3 User taste profile (materialized memory)

Table: user_taste_profiles

- id
- user_id (FK, required, unique)
- profile_version (integer, required, default: 1)
- preference_weights (jsonb, default: {})
- ingredient_affinities (jsonb, default: {})
- ingredient_avoidances (jsonb, default: {})
- category_affinities (jsonb, default: {})
- time_preference (jsonb, default: {})
- novelty_preference (decimal(4,3), default: 0.200)
- confidence (decimal(4,3), default: 0.000)
- last_recomputed_at (datetime)
- created_at, updated_at

Purpose:

- Durable long-term memory of user preferences.
- Fast retrieval at scoring time.

### 5.4 Pantry inventory

Table: pantry_items

- id
- user_id (FK, required, indexed)
- name (string, required)
- normalized_name (string, required, indexed)
- quantity (decimal(10,3), optional)
- unit (string, optional)
- purchased_on (date, optional)
- expires_on (date, optional, indexed)
- perishability_score (integer, default: 3) # 1 low .. 5 high
- created_at, updated_at

Table: pantry_item_usages

- id
- pantry_item_id (FK, required, indexed)
- recipe_id (FK, optional)
- recipe_candidate_id (FK, optional)
- match_strength (decimal(4,3), default: 0.000)
- created_at, updated_at

Purpose:

- Enable waste-reduction aware recommendations.

### 5.5 Web candidates and recommendation snapshots

Table: recipe_candidates

- id
- user_id (FK, required, indexed)
- source_url (string, required)
- title (string, required)
- domain (string, required, indexed)
- status (string, required, default: discovered) # discovered, imported, rejected
- normalized_ingredients (jsonb, default: [])
- normalized_categories (jsonb, default: [])
- prep_minutes (integer, optional)
- cook_minutes (integer, optional)
- total_minutes (integer, optional)
- quality_score (decimal(5,4), default: 0.0000)
- imported_recipe_id (FK to recipes, optional)
- discovered_at (datetime, required)
- created_at, updated_at

Unique index:

- [user_id, source_url]

Table: user_recipe_recommendations

- id
- user_id (FK, required, indexed)
- recommendable_type (string, required) # Recipe or RecipeCandidate
- recommendable_id (bigint, required)
- score_total (decimal(6,4), required)
- score_breakdown (jsonb, default: {})
- reason_codes (jsonb, default: [])
- generated_at (datetime, required)
- created_at, updated_at

Indexes:

- [user_id, generated_at]
- [user_id, recommendable_type, recommendable_id, generated_at]

Purpose:

- Persist ranked output for stable UI and experimentation.

## 6. Migration draft (recommended filenames)

1. db/migrate/20260315090000_create_recipe_feedback_events.rb
2. db/migrate/20260315090500_create_feedback_note_insights.rb
3. db/migrate/20260315091000_create_user_taste_profiles.rb
4. db/migrate/20260315091500_create_pantry_items.rb
5. db/migrate/20260315092000_create_recipe_candidates.rb
6. db/migrate/20260315092500_create_user_recipe_recommendations.rb
7. db/migrate/20260315093000_create_pantry_item_usages.rb

## 7. Class and service map draft

### 7.1 Models

- app/models/recipe_feedback_event.rb
- app/models/feedback_note_insight.rb
- app/models/user_taste_profile.rb
- app/models/pantry_item.rb
- app/models/recipe_candidate.rb
- app/models/user_recipe_recommendation.rb
- app/models/pantry_item_usage.rb

### 7.2 Recommendation services

- app/services/recommendations/feedback_ingestor.rb
- app/services/recommendations/note_insight_extractor.rb
- app/services/recommendations/profile_updater.rb
- app/services/recommendations/candidate_discovery.rb
- app/services/recommendations/pantry_matcher.rb
- app/services/recommendations/scorer.rb
- app/services/recommendations/generator.rb

Optional UI-oriented services later:

- app/services/recommendations/feedback_prompt_builder.rb
- app/services/recommendations/reason_presenter.rb

Responsibilities:

- FeedbackIngestor: writes event records from user actions.
- NoteInsightExtractor: AI call + strict schema parse + persistence.
- ProfileUpdater: updates user_taste_profile from events and insights.
- CandidateDiscovery: schedules external discovery and lightweight candidate creation.
- PantryMatcher: computes pantry-fit and urgency boosts.
- Scorer: deterministic weighted score with explainable breakdown.
- Generator: orchestrates pool assembly + scoring + snapshot persistence.

### 7.3 Jobs

- app/jobs/recommendations/feedback_ingest_job.rb
- app/jobs/recommendations/note_insight_job.rb
- app/jobs/recommendations/profile_refresh_job.rb
- app/jobs/recommendations/candidate_discovery_job.rb
- app/jobs/recommendations/recommendation_refresh_job.rb

Suggested trigger policy:

- After feedback submission:
  - enqueue FeedbackIngestJob
  - enqueue NoteInsightJob only if note_text present and changed
  - enqueue ProfileRefreshJob
  - enqueue RecommendationRefreshJob
- Daily scheduled:
  - enqueue CandidateDiscoveryJob
  - enqueue RecommendationRefreshJob for active users

## 8. Feedback UX recommendation

Do not rely on the recipe edit screen alone for recommendation learning.

Recommended UI split:

- Recipe editing UI:
  - Edit ingredients, directions, source, image, categories.
  - Maintain recipe-specific notes/tips.
- Post-cook feedback UI:
  - A lightweight "How did it go?" interaction after cooking.
  - Writes recipe_feedback_events.
  - Designed to capture preference and outcome, not recipe authoring.

Examples of intentional feedback prompts:

- "Would you make this again?"
- "What did you like most?"
- "What would you change next time?"
- "Was this worth the effort for a weeknight?"
- "Did you already have most of the ingredients?"

These questions produce much better recommendation signals than a generic notes box.

### 8.1 Concrete post-cook flow (v1)

Entry points:

- From recipe show page: "I cooked this" button.
- Optional reminder card on homepage for recently viewed/favorited recipes.

Flow:

1. User clicks "I cooked this".
2. Open a short form (modal or dedicated page).
3. Save a new recipe_feedback_event.
4. Show confirmation with "See updated recommendations".

Step form fields (single screen for v1):

- Outcome:
  - overall_outcome: loved, liked, neutral, disliked
- Rating:
  - rating (1..5)
- Repeat intent:
  - would_make_again (yes/no)
- Free text:
  - "What did you like?"
  - "What would you change?"
  - Stored as a composed note_text string initially.
- Effort and context (optional):
  - prep_time_actual_minutes
  - cook_time_actual_minutes
  - feedback_context (weeknight, guests, meal_prep, special_occasion)
- Pantry signals (optional):
  - used_pantry_items[]
  - missing_ingredients[]

Validation suggestions:

- Require at least one of: rating, overall_outcome, would_make_again, note_text.
- Enforce rating range and bounded text size.
- Store cooked_at default as current time unless user edits it.

### 8.2 Controller and endpoint draft (Rails)

Routes:

- GET /recipes/:recipe_id/feedback/new
- POST /recipes/:recipe_id/feedback
- GET /recommendations

Controller proposal:

- app/controllers/recipe_feedback_events_controller.rb
  - new
  - create

Strong params proposal:

- :cooked_at
- :rating
- :overall_outcome
- :would_make_again
- :feedback_context
- :prep_time_actual_minutes
- :cook_time_actual_minutes
- :liked_text
- :change_text
- used_pantry_items: []
- missing_ingredients: []

Composition rule for note_text (v1):

- note_text = [liked_text, change_text].compact_blank.join("\n\n")

Create action behavior:

1. Build feedback event for current_user + recipe.
2. Persist immutable event row.
3. Enqueue:
  - Recommendations::FeedbackIngestJob
  - Recommendations::NoteInsightJob (if note_text present and not trivial)
  - Recommendations::ProfileRefreshJob
  - Recommendations::RecommendationRefreshJob
4. Redirect back with success toast.

Authorization:

- Only allow feedback on recipes the user can view.
- Scope all feedback reads/writes to current_user.

## 9. Conservative AI usage strategy

### 9.1 Hard rules

- Never call AI in request-time ranking.
- AI only parses free-text notes into structured signals.
- Use note_sha256 + prompt_version dedupe key.
- Skip AI if note length below threshold (for example < 15 chars).
- Use low-cost model and max token cap.
- Store raw extracted payload for audit/debug.

### 9.2 Prompting approach

- Strict JSON schema output only.
- No open-ended generation.
- Keep prompt short and stable.
- Version prompts to support safe evolution.

### 9.3 Failure behavior

- If AI fails: keep event, mark insight as unavailable, continue deterministic pipeline.
- Retry with exponential backoff but cap attempts.

## 10. Initial deterministic scoring formula

score_total =

- 0.35 * taste_match
- 0.25 * pantry_fit
- 0.15 * expiry_urgency
- 0.10 * novelty_bonus
- 0.10 * recency_penalty_inverse
- 0.05 * effort_match

Range normalize each signal to [0, 1].

Definitions:

- taste_match: overlap between recipe signals and profile affinities.
- pantry_fit: ingredient overlap with pantry items.
- expiry_urgency: boost if soon-to-expire ingredients are used.
- novelty_bonus: encourages occasional diversity.
- recency_penalty_inverse: reduces repeated recent recipes.
- effort_match: fit to preferred prep/cook time and complexity.

Persist full score_breakdown for explainability.

## 11. API/UI integration points

### 9.1 Feedback capture

- Add explicit post-cook feedback form endpoint (can reuse recipe page flow).
- Keep recipe.rating and recipe.notes as convenience, but also write immutable feedback events.

### 9.2 Recommendation endpoint

- Add a recommendations index endpoint that reads latest user_recipe_recommendations.
- Return reason codes and score breakdown snippets for trust.

### 9.3 Pantry endpoint

- CRUD endpoints for pantry_items.
- Optional quick actions: mark used, adjust quantity, extend expiry.

## 12. Rollout plan

### Phase 1 (no AI)

- Implement feedback events.
- Implement taste profile from ratings and favorites only.
- Implement deterministic recommendations from local recipes.

### Phase 2 (limited AI)

- Add note insight extraction jobs with strict schema.
- Blend insights into taste profile and scoring.

### Phase 3 (web blend)

- Add candidate discovery and candidate ranking.
- Import only top-ranked candidates to full recipes.

### Phase 4 (pantry optimization)

- Add pantry models and expiry-aware boosts.
- Add waste reduction metric reporting.

## 13. Testing strategy (RSpec)

- Unit specs for each service score component.
- Job specs for retry/failure behavior.
- Request specs for feedback and recommendations endpoints.
- Integration specs for event -> profile -> recommendations pipeline.
- No-network tests for AI extraction (stub client output).
- Add fixtures covering edge notes: empty, ambiguous, strongly positive/negative.

## 14. Observability and controls

- Add per-user/day AI call counters.
- Add metrics:
  - recommendation_click_rate
  - cook_conversion_rate
  - pantry_waste_reduction_rate
  - ai_cost_per_active_user
- Add Flipper flags for each phase:
  - recommendations_v1
  - recommendations_ai_note_insights
  - recommendations_web_discovery
  - recommendations_pantry

## 15. Practical first implementation checklist

1. Add feedback event + taste profile tables and models.
2. Implement feedback ingestion service + job and wire from controller update/create flows.
3. Implement deterministic scorer for local recipes only.
4. Persist recommendation snapshots and expose index endpoint.
5. Add note insight AI parsing job with dedupe and strict schema.
6. Add recipe candidate discovery pipeline.
7. Add pantry tables and scoring boost.

## 16. Notes on cost discipline

- The recommendation engine should still operate if AI is disabled.
- AI should enrich, not control, ranking.
- Long-term memory should be database state (events + profiles + outcomes), not transient cache.
- Recompute profile periodically from event history to avoid drift.

## 17. Next Steps For Actual Code Implementation

### 17.1 Implementation order (recommended)

1. Create schema for feedback events and taste profile.
2. Add feedback controller + routes + form UI.
3. Add background jobs and no-op services first (plumbing only).
4. Implement deterministic local-recipe scoring and recommendation persistence.
5. Add AI note insight extraction with strict dedupe.
6. Add candidate discovery and pantry enhancements.

### 17.2 File-by-file starting draft

- config/routes.rb
  - Add nested feedback routes under recipes.
  - Add recommendations index route.
- app/controllers/recipe_feedback_events_controller.rb
  - Implement new/create.
- app/views/recipe_feedback_events/new.html.erb
  - Implement intentional post-cook feedback form.
- db/migrate/*_create_recipe_feedback_events.rb
  - Add event table and indexes.
- db/migrate/*_create_user_taste_profiles.rb
  - Add durable profile memory table.
- app/models/recipe_feedback_event.rb
  - Validations and belongs_to associations.
- app/models/user_taste_profile.rb
  - belongs_to :user and profile helpers.
- app/jobs/recommendations/feedback_ingest_job.rb
  - Wire event -> profile update pipeline.
- app/jobs/recommendations/recommendation_refresh_job.rb
  - Regenerate snapshots asynchronously.
- app/services/recommendations/profile_updater.rb
  - Convert events into profile weights.
- app/services/recommendations/scorer.rb
  - Deterministic scoring with explainable breakdown.
- app/services/recommendations/generator.rb
  - Build candidate pool and persist user_recipe_recommendations.

### 17.3 Minimum acceptance criteria for first merge

- User can submit post-cook feedback independently of recipe editing.
- recipe.notes remains unchanged in purpose and labeling.
- A feedback submission triggers async jobs without blocking UI.
- Recommendation records are generated and viewable for the current user.
- System works with AI disabled.

### 17.4 Immediate follow-up PR after first merge

- Add Feedback Note Insight table + extractor service + job.
- Add note hash dedupe and prompt versioning.
- Add specs for AI failure fallback behavior.

## 18. Future Enhancements

### Phase 5 (planner and practical constraints)

- Add weekly meal planner generation from recommendations.
- Add shopping list and reminder workflow.
- Add cost and budget-aware planning signals.
- Add seasonality and alternative ingredient support.
- Optimize plans for ingredient remainder usage and reduced food waste.

### Phase 6 (recipe adaptation)

- Add serving-size adaptation for ingredients and instructions.
- Add practical recipe modification assistance based on user constraints/preferences.
- Feed adaptation outcomes back into recommendation learning over time.
