# Mobile overflow + iOS zoom issue

## Problem
- On iPhone SE (375 x 667), some pages require horizontal scrolling.
- It appears worse on the recipe show page.
- After using form fields, the UI seems more zoomed in (iOS input zoom behavior).

## Root causes found
- `flex-nowrap` on the recipe show page forces single-line layout, which can overflow on small screens.
- iOS auto-zooms inputs with font sizes under 16px, making the page appear zoomed in after interacting with form fields.

## Changes made
### 1) Allow wrapping on the recipe show layout
File: app/views/recipes/_recipe.html.erb

Before:
- `h1` used `flex-nowrap` and the title could not wrap.
- Metadata and category rows used `flex-nowrap` and `w-100` (not a Tailwind class), making them more prone to overflow.

After:
- `h1` uses `flex-wrap` with `gap-x-2 gap-y-2`.
- The title uses `break-words flex-1 min-w-0` to wrap long names.
- Source link container uses `sm:ml-auto` so it only pushes right on larger screens.
- Metadata rows use `flex-wrap` and `w-full` instead of `flex-nowrap` and `w-100`.
- Category chips row uses `flex-wrap`.

Patch summary (manual reapply):
- Change `h1` class from `flex flex-row flex-nowrap gap-x-1` to `flex flex-wrap items-center gap-x-2 gap-y-2`.
- Add `break-words flex-1 min-w-0` to the recipe title `<strong>`.
- Change `ml-auto` to `sm:ml-auto` for the source link container.
- Replace `w-100` with `w-full` and remove `flex-nowrap` in metadata rows.
- Change category row from `flex-nowrap` to `flex-wrap`.

### 2) Prevent iOS input zoom on small screens
File: app/assets/stylesheets/application.css

Added inside `@media (max-width: 640px)`:

```
input,
textarea,
.ts-control {
  font-size: 16px;
}
```

This avoids iOS auto-zoom on focus and reduces the perceived zooming in after form interaction.

## Related files checked
- app/views/layouts/application.html.erb
- app/views/recipes/index.html.erb
- app/views/recipes/_form.html.erb
- app/views/layouts/_navigation.html.erb
- app/assets/stylesheets/application.css
- app/assets/stylesheets/application.tailwind.css

## Follow-up if issue persists
- Inspect for long unbroken strings, wide images, or elements with `flex-nowrap` on small screens.
- Use devtools “highlight overflow” to identify the offending element.
