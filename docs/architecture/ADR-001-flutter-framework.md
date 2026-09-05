# ADR-001: Flutter as Mobile Framework

## Status
**Accepted** — 2026-09-05

## Context
We need a cross-platform mobile framework for Pomniter that supports:
- Android and iOS simultaneously
- Custom pixel-level UI (neo-brutal design system)
- On-device ML inference (ONNX Runtime integration)
- Smallest possible APK size
- Desktop expansion in future phases

Candidates evaluated:
1. **Flutter** (Dart) — Custom rendering engine, single codebase
2. **React Native** (TypeScript) — Native components, JS bridge
3. **Kotlin Multiplatform** (Kotlin) — Shared logic, native UI per platform

## Decision
We chose **Flutter** for the following reasons:

### 1. Neo-Brutal UI Requires Pixel-Level Control
Flutter draws every pixel itself using Skia/Impeller, giving us complete control over thick borders, hard shadows, and custom shapes that define neo-brutalism. React Native delegates rendering to platform-native components, making custom design systems harder to maintain consistently.

### 2. APK Size Optimization
Flutter's tree-shaking removes unused code aggressively. A minimal Flutter app compiles to ~5MB, and with deferred component loading we can keep the base APK under 15MB.

### 3. Developer Proficiency
The project maintainer (Nikunj Maheshwari) is proficient in Dart, eliminating the learning curve.

### 4. ONNX Runtime Compatibility
Flutter has mature plugins for ONNX Runtime Mobile, essential for on-device OCR and embedding generation.

### 5. Desktop Expansion
Flutter compiles to Windows, macOS, and Linux natively — enabling a future desktop client from the same codebase.

## Consequences
- **Positive**: Unified codebase, consistent UI, strong performance, smaller APK
- **Negative**: Dart ecosystem is smaller than JavaScript's; need to learn Flutter-specific patterns
- **Mitigation**: Backend services use TypeScript/Python where ecosystem breadth matters
