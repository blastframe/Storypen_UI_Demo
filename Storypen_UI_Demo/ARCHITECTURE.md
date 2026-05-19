# StoryPen — iOS Architecture

## Pattern: MVVM + Layered Decomposition

```
StoryPen/
├── App/
│   ├── StoryPenApp.swift          @main entry point
│   └── ContentView.swift          Root view — injects tint, hosts ProjectShellView
│
├── Theme/
│   ├── AppTheme.swift             All design tokens (colors, fonts, MTLClearColor)
│   └── Color+Hex.swift            Color(hex:) initialiser
│
├── Models/                        Pure value types — no SwiftUI imports
│   └── Project.swift              Project, Layer, Tool structs + DemoData
│
├── ViewModels/                    @Observable reference types — own all mutable state
│   ├── ProjectGridViewModel.swift  Navigation state, project list, open/close logic
│   └── ProjectEditorViewModel.swift Layout constants + all editor interaction state
│
└── Views/
    ├── Projects/                  Grid / home screen
    │   ├── ProjectShellView.swift      Navigation shell, transition animations
    │   ├── ProjectGridView.swift       Header + MasonryLayout scroll grid
    │   └── ProjectThumbnailCard.swift  Card with waveform + metadata footer
    │
    ├── ProjectEditor/             Editor workspace
    │   ├── ProjectEditorView.swift       Top-level VStack layout, GeometryReader
    │   ├── ProjectEditorHeaderView.swift Breadcrumb, properties toggle
    │   ├── PlaybackControlsRow.swift     Transport controls, play/pause
    │   ├── CanvasWorkspaceRow.swift      Canvas + floating toolbar + properties panel
    │   ├── MetalCanvasView.swift         UIViewRepresentable MTKView stub
    │   ├── FloatingToolbarView.swift     Draggable tool palette
    │   ├── PropertiesPanelView.swift     Brush sliders, canvas toggles
    │   └── LayerStackView.swift          Layer list with selection state
    │
    └── Shared/                    Reusable primitives
        ├── MasonryLayout.swift    Pure Layout — shortest-column-first algorithm
        ├── Draggers.swift         HorizontalDragger + VerticalDragger
        └── CheckerboardView.swift Canvas transparency indicator

```

## Key Design Decisions

### State flows down, events flow up
- `ProjectGridViewModel` (grid navigation) and `ProjectEditorViewModel` (editor state)
  are `@Observable` classes — passed as `@Bindable` into views that need to write back.
- Views that only read receive the VM as a plain `let`.
- No `@EnvironmentObject` — ownership is explicit via init injection.

### Models are dumb value types
- `Project`, `Layer`, `Tool` are plain structs with no SwiftUI or Combine imports.
- All mutation lives in the ViewModel layer.

### Theme is a caseless enum
- `AppTheme` is a caseless enum — it cannot be instantiated, making it a true namespace.
- Every color, font, and spacing constant lives here; no magic literals in views.

### Thumbnail cards — no icons, no gradients
Per the Darkroom design system:
- SF Symbol icons removed from grid cards — they added visual noise with no information value.
- Gradients eliminated entirely (violate the zero-gradient rule).
- Cards display a deterministic procedural sine-wave waveform drawn with `Canvas`,
  seeded from `project.id.hashValue` so each card looks distinct but stable across redraws.
- Transparency checkerboard at 14% opacity indicates "no rendered frame yet."

### Slider value readout
`PropertiesPanelView` now shows a live `##%` readout beside each slider —
small quality-of-life improvement with zero visual overhead.

### Layer visibility icon
`LayerRowView` now uses `eye.slash` when `isVisible == false`, matching
professional tool conventions (Blender, After Effects, Figma).
