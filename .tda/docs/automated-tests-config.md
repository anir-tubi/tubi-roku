# automated-tests-config

## Purpose

Contains the UI element definitions used by the automated test suite to locate and interact with SceneGraph nodes on Roku devices. This is the single source of truth for all element keypaths and XPath selectors used across all automated tests.

## Structure

- `elements.ts` - A large TypeScript file (~130KB) exporting a typed `elements` object containing hundreds of element definitions. Each element has:
  - `keyPath` - A `#`-delimited path through the SceneGraph node tree (e.g., `#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen`)
  - `xpath` (optional) - An XPath selector as an alternative locator strategy
  - `id` (optional) - A reference key
  - `base` (optional) - Base type from `roku-test-automation`

## Architecture

- **Centralized Element Registry**: All UI element locators are defined in a single file to ensure consistency across tests. Tests import elements by key name and use `testUtils.getNodeForElement('elementName')` to query the Roku device.
- **Type-Safe Element Map**: Uses a TypeScript `typeCheckElements` helper function to enforce that all element definitions conform to the `Element` interface while preserving specific key types for autocomplete.
- **KeyPath Convention**: KeyPaths use `#` prefix to denote node IDs in the SceneGraph hierarchy (e.g., `#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup`).

## Key Concepts

- **`Element`** type: `{ id?: ElementKey; base?: BaseType; keyPath: string; xpath?: string }` — the core type for all element definitions.
- **`ElementKey`**: Union type of all element keys in the `elements` object, used for type-safe lookups.
- **`ElementOrElementId`**: Type alias `Element | ElementKey` allowing tests to pass either a full element object or just the key string.
- **Nested Node Limitation**: SceneGraph node objects returned from RTA do not have child nodes populated — every nested element must have its own keypath entry in this file. You cannot chain `.findNode()` or access nested properties on returned nodes.

## Dependencies

**Internal:**

- Used by `js/automated-tests/test-utils.ts` and `js/automated-tests/test-helpers.ts`
- Used by all test files in `js/automated-tests/tests/`
- Referenced by `ai-automation/lib/prompt-builder.js` for AI test generation context

**External:**

- `roku-test-automation` - Provides the `BaseType` type import

## Working with this Code

### Common Tasks

- **Add a new element**: Add a new entry to the `elements` object with a descriptive key name and the SceneGraph keypath. Optionally add an `xpath` for alternative lookup.
- **Find the keypath for an element**: Use Roku's developer tools (RALE or VSCode Roku Device View) to inspect the SceneGraph tree and trace the node hierarchy.

### Things to Watch Out For

- This file is very large (~130KB). When adding elements, ensure the key name is descriptive and follows the existing naming conventions.
- KeyPaths must exactly match the SceneGraph node hierarchy — a single typo will cause test failures.
- When screens are restructured, all keypaths referencing nodes in that screen must be updated.
- The file contains a managed section comment about auto-replacement from JSON; elements added outside that section are safe from script overwrites.
