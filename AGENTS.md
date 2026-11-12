# Mame Zefu

Rails app (Postgres) for recipes, categories, and users. Check the `Gemfile` for dependency versions.

## Architecture
- Recipe import: `RecipesController#web_result` -> `Recipes::Import` (`lib/recipes/import.rb`) -> per-host importer under `lib/recipes/import/`, selected via `Recipes::Import::RECIPE_CLASSES`, with a RecipeScrapers fallback.
- `Recipes::Import::Base` maps importer `recipe_*` getters into `Recipe` fields.
- RecipeScrapers shells out to `bin/scrape` (Python, deps in `requirements.txt`) via `Open3.capture3`; use `system` with `File::NULL` only for status-only checks.
- `Recipes::Archive` (`lib/recipes/archive.rb`) reads/writes a zip of `recipes.json` plus images.
- Recipe images use ActiveStorage; `Recipe` attaches remote images via Down and normalizes line endings.
- Authorization uses Pundit (`app/policies`); controllers skip it explicitly when needed. Admin UI is Administrate under `/admin`.

## Commands
Use the `bin/docker/` scripts rather than ad-hoc `docker compose exec`:
- `bin/docker/dev`: start Rails and Postgres.
- `bin/docker/rspec [path_or_filter]`: run specs (`RAILS_ENV=test`; manages Postgres automatically).
- `bin/docker/rubocop [paths...]`: run RuboCop. Run it on every Ruby file you touch before finishing.
- `bin/docker/erb_lint [paths...]`, `bin/docker/prettier [args...]`: lint ERB and formatting.
- `bin/docker/lint`: RuboCop, ERB lint, and Prettier together.

## Testing
- Aim for 100% SimpleCov line coverage on Ruby files.
- Specs use RSpec with shallow `context 'when ...'` blocks, one primary assertion per example, and verifying doubles.
- Existing assertions describe current behavior; update them when behavior intentionally changes, but never weaken them just to pass.

## Documentation
- Use the GitHub wiki for project documentation; do not add documentation to `README.md`.
- The wiki is a separate Git repository. If it cannot be updated, report the documentation that remains to be published.

## Agents
Task-specific guidance lives in `.github/agents/` (application and test implementation).
