# Cursor Task: Apply Any New Analytics Instrumentation Doc

Use this task when you receive a **new analytics instrumentation doc** (any product/feature). It keeps test structure consistent and ensures all events and surfaces are covered.

---

## When to use

- A new or updated analytics doc (Google Doc, spec, requirements) for any area (video tiles, search, playback, etc.).
- You need to add, reorder, or update analytics tests to match the doc.

**If a feature-specific spec exists** (e.g. `js/automated-tests/docs/video-tiles-analytics-test-spec.md`), @ that file **in addition to** this task so area-specific conventions and past feedback are applied.

---

## Prerequisites

- **Analytics doc:** Paste, link, or describe (questions, events, surfaces/pages).
- **Target test file:** Identify or create (e.g. `tests/analytics/video-tiles-analytics.ts`, or other files in `tests/analytics/`). If an area spec exists in `js/automated-tests/docs/`, follow it.

---

## Task: Apply new analytics doc to tests

### Phase 1: Understand the doc

1. **Extract from the doc (use the doc’s lists, not the question text alone):**
   - **Questions** in document order.
   - **Events per question:** Read the doc’s explicit event list for each question; do not infer from question wording (e.g. “land on page” → still check for NavigateToPageEvent if the doc lists it).
   - **Surfaces/pages per question:** Read the doc’s explicit list (e.g. Movies, TV Shows, Espanol); do not assume from question text.

2. **Decide scope:**
   - One existing test file to update, or a new file.
   - If new file: follow existing analytics test patterns (describe block, proxy). **Use the analytics framework:** import from `js/automated-tests/tests/analytics/analytics-framework.ts` (re-exports `analytics-validator` + shared constants, assertion helpers, proto-derived CONTENT_MODE, ANALYTICS_EVENT_KEYS). See header in that file for "How to add new analytics tests" and **PROTO SOURCE** (protos repo: e.g. Documents/protos — tubi/analytics/client.proto, events.proto, tubi/common/constants.proto).

### Phase 2: Align tests with the doc

3. **Questions list at top of file**
   - Add or replace a **QUESTIONS (document order)** block with the exact question text from the doc, numbered in document order.

4. **Test order**
   - Order tests to match the doc (e.g. exposure first, then navigation/landing, then feature lifecycle). Reorder existing tests; add new ones in the right place.

5. **One question → one or more tests**
   - For each question: capture and assert every event from the doc’s list; cover every surface/page from the doc’s list. Do not infer from question text alone.

### Phase 3: Conventions (apply everywhere)

6. **Event shape**
   - Use **single-level** component/page structures—no double-nesting (e.g. `category_component: { category_slug, ... }` not `category_component: { category_component: { ... } }`).
   - **component_interaction / left_side_nav:** Use single-level `left_side_nav_component: { left_nav_section }`. Do **not** use `componentOneof.left_side_nav_component.left_side_nav_component`. Do **not** assume a fixed "from" page (e.g. home_page)—the user may have been on Movies, TV Shows, etc. when they opened left nav; validate left_side_nav_component and user_interaction without hardcoding the page context. Match `analytics/verification/componentInteraction.ts`.
   - **navigate_to_page:** Payload uses top-level **dest_*** (not `dest_pageOneof.*`). **Which dest_* is present depends on from→to**—do not assume a fixed set (e.g. only dest_home_page/dest_for_you_page). Tie the event to the action (e.g. `left_side_nav_component`); require *some* dest_* object when validating. Match `analytics/verification/navigateToPage.ts`.
   - **page_load:** **Which page type is present depends on where we landed**—do not assume a fixed set (e.g. only home_page/for_you_page). Validate that page_load has *some* proper page (e.g. a key that is a page type with an object value), using the doc and actual payload shape. Use **getPageValidator()** when you need to validate a specific page structure.
   - **General:** For any oneof-style field (dest, page type, etc.), read the doc and payload; validate that a proper value exists without hardcoding a fixed list of types.

7. **Exposure**
   - If the doc talks about “exposure” for experiments, prefer validating **abproxy** `log_custom_exposure` (URL contains `log_custom_exposure`, payload has `exposures[]` with `experimentName`, `group`) unless the doc explicitly requires analytics-pipeline exposure events.

8. **Per-test doc blocks**
   - Each test has a short block: **Q:** (question from doc), **A:** (user action), **Tracking:** (which events we assert). Update when the doc or events change.

9. **Group/section comments**
   - Use clear section comments (e.g. `// ─── Group: Left nav & page landing ───`) so test order and doc sections are easy to match.

10. **Detail screen: use detailScreen, not vodDetailScreen**
   - **Do not** use `vodDetailScreen` in analytics tests—it is part of an experiment. Use `detailScreen` when waiting for or asserting the title/details screen (e.g. `waitForCurrentScreenToEqual('detailScreen', timeout)`).

11. **Proto alignment (single source of truth)**
   - Constants and page/event shapes align with the **protos repo** (e.g. Documents/protos): `tubi/analytics/client.proto`, `tubi/analytics/events.proto`, `tubi/common/constants.proto`. Use framework constants (CONTENT_MODE, VALID_CONTENT_MODES, LEFT_NAV_SECTIONS, ANALYTICS_EVENT_KEYS, etc.) from `js/automated-tests/tests/analytics/analytics-framework.ts`; when adding new shared constants, derive from protos and add to the framework so other tests/screens can reuse.

### Phase 4: Verify and document

12. **Run tests** for the updated file and fix failures.
13. **Update area spec** (if one exists) when questions or conventions change.

---

## Quick prompt for Cursor

Generic (any analytics doc):

*"Apply this analytics doc to the tests: [paste or link]. Use the task @.cursor/tasks/apply-analytics-doc.md. Create or update the right test file under js/automated-tests/tests/analytics/ (or tests/ for non-analytics)."*

With an area spec (e.g. video tiles):

*"Apply this analytics doc: [paste or link]. Use @.cursor/tasks/apply-analytics-doc.md and follow @js/automated-tests/docs/video-tiles-analytics-test-spec.md for video-tiles conventions."*

---

## Checklist (any analytics doc)

- [ ] Questions extracted in document order; tests ordered to match
- [ ] For each question: doc’s event list and surfaces/pages list used (not inferred from question text); all events asserted, all surfaces covered
- [ ] Single-level event shape (no double-nesting; left_side_nav_component single-level per componentInteraction.ts)
- [ ] **No fixed-set assumptions:** dest_* and page type depend on from→to / where we landed; validate “some proper dest/page” or use doc/payload, not only home_page/for_you_page or dest_home_page/dest_for_you_page
- [ ] **Framework:** Import from `js/automated-tests/tests/analytics/analytics-framework.ts` (validators, getPageValidator, expectContentModeProper, expectContentTileHasVideoOrSeriesId, CONTENT_MODE / VALID_CONTENT_MODES, ANALYTICS_EVENT_KEYS, etc.) for reuse across events/screens
- [ ] **Proto alignment:** Use framework constants derived from protos; when adding new shared enums/constants, align with tubi/analytics and tubi/common/constants and add to framework
- [ ] pageOneof / getPageValidator used where applicable (for specific structure; don’t assume which page/dest type)
- [ ] Exposure via log_custom_exposure where doc refers to experiment exposure
- [ ] detailScreen used (not vodDetailScreen) for analytics tests
- [ ] Per-test Q / A / Tracking doc blocks and section comments in place
- [ ] Tests run and passing
