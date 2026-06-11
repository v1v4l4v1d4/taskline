# Dependency Graph Click Events Dev Notes

Task: `78d47b4c-102d-413e-b937-26969742021d`

## Implementation

- Updated `web/src/components/GraphView.tsx`.
- Added a short pending-open timer for graph node single-clicks.
- Kept single-click responsible for opening the task editor only.
- Added `onNodeDoubleClick` and moved task-chain selection/highlighting there.
- Cancelled pending single-click opens when double-clicking a node, clicking an
  edge, clicking the pane, or unmounting the graph view.
- Left edge selection and dependency deletion behavior unchanged.

## Tests Added Or Updated

- Updated the React Flow test mock to forward `onNodeDoubleClick`.
- Changed the chain-highlight test to use `user.dblClick`.
- Added coverage that double-click highlighting does not open the task editor.
- Changed the single-click editor test to assert the graph node is not selected.

## TDD Evidence

- Red run: `mise exec -- pnpm --dir web test src/components/GraphView.test.tsx`
  failed because double-click still opened the editor and single-click still
  selected the node.
- Green run: `mise exec -- pnpm --dir web test src/components/GraphView.test.tsx`
  passed with `8` tests.

## Divergence

No API, persistence, server, or CLI changes were needed. The change stayed inside
the dependency graph UI and its component tests.
