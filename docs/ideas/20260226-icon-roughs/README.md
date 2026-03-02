# 2026-02-26 Icon Roughs (Minimal)

## Adopted concept
- `Pulse Mic` (Concept 1)

## Files
- `pulse-mic-minimal.svg`
  - 1024 master rough for app icon direction
- `pulse-mic-minimal-32.svg`
  - Simplified preview for small-size readability checks
- `pulse-mic-minimal-16.svg`
  - Ultra-simplified preview for tiny-size checks
- `pulse-mic-template-18.svg`
  - Monochrome menu bar template rough (18x18)

## Design rules
- Keep only essential shapes: background, mic body, one pulse cue
- Remove decorative details at smaller sizes
- Prefer strong silhouette contrast over gradients in tiny variants

## Usage intent
- App icon direction: `pulse-mic-minimal.svg`
- Pixel-fit tuning references: `pulse-mic-minimal-32.svg`, `pulse-mic-minimal-16.svg`
- Menu bar template base: `pulse-mic-template-18.svg`

## Next refinement checklist
1. Validate appearance on light/dark menu bar contexts
2. Export PNG set and `icns` from 1024 master
3. Integrate menu bar template into app resources

## Implementation notes
- Generation script: `scripts/release/generate-icons.sh`
- Current environment note: Codex sandbox では `iconutil` が `Invalid Iconset` になる場合があり、昇格実行では `AppIcon.icns` 生成に成功した。
