# WatchNoteTaker Design System v1.0

> Brand identity, app icon, color system, typography, and full UX design for every screen state.
>
> Source: `obsidian_vault/assets/watchnotetaker-design-system.pdf` (March 2026)

---

## 01 — App Icon

### The Mark

A soundwave transforming into a pen stroke — capturing the moment voice becomes text. The amber glow signifies the always-ready recording state. Rounded superellipse follows Apple's icon grid.

Sizes: 1024x1024, 180x180, 80x80, 60x60, 40x40

### Icon Anatomy

- **Slate bars (left)** — Represent raw voice/sound input. Cooler color, lower opacity = unprocessed thought.
- **Gradient transition (center)** — The color shift from slate to amber visualizes the AI transcription moment.
- **Amber bars + pen nib (right)** — Processed text output. The pen nib with its sparkle represents the written note.
- **Text lines (bottom)** — Subtle horizontal lines hint at the Markdown output landing in Obsidian.
- **Background glow** — Radial amber softness at center creates depth and warmth without being loud.

---

## 02 — Color Palette ("Ink & Amber")

Deep navy grounds the interface with gravitas. Amber provides warmth and signals action — the recording indicator, the Action Button, the moment of capture.

| Name          | Hex       | Usage                                    |
|---------------|-----------|------------------------------------------|
| **Ink**       | `#0D1B2A` | Primary background, deepest layer        |
| **Ink Mid**   | `#1B2D45` | Cards, elevated surfaces, input fields   |
| **Slate**     | `#415A77` | Tertiary text, disabled states, dividers |
| **Slate Light** | `#778DA9` | Secondary text, labels, hints          |
| **Amber**     | `#E8A838` | Primary action, accent, CTA buttons      |
| **Amber Glow** | `#F0C060` | Highlights, glow effects, hover states |
| **Recording** | `#E85454` | Recording state, stop button, REC badge  |
| **Success**   | `#4CAF82` | Saved state, checkmarks, confirmations   |
| **Paper**     | `#F0EDE6` | Light surface (future light mode/preview) |

---

## 03 — Typography ("Type System")

Three fonts, clear roles. DM Serif Display for presence, DM Sans for readability at all sizes, JetBrains Mono for timestamps and technical details.

| Role      | Font              | Size/Weight      | Line Height | Usage                              |
|-----------|-------------------|------------------|-------------|------------------------------------|
| **Display** | DM Serif Display | 42px             | 1.2         | Hero text: "Speak it. It's saved." |
| **Heading** | DM Sans 600     | 24px / semibold  | 1.3         | Section titles, screen headers     |
| **Body**    | DM Sans 300     | 16px / light     | 1.7         | Descriptions, transcript text      |
| **Mono**    | JetBrains Mono  | 14px             | —           | Timestamps, filenames, code        |

---

## 04 — Core User Flow ("Four Steps, No Friction")

The entire capture loop in under 15 seconds. No menus, no navigation, no decisions.

```
1. Press      → Action Button
2. Speak      → See live text
3. Process    → On-device AI
4. Saved      → In your vault
```

---

## 05 — Watch UX ("Every Screen State")

Minimal information, maximum glanceability. The watch shows only what you need at each moment — nothing more.

### IDLE State
- **Background**: Ink (#0D1B2A), full bleed
- **Title**: "WatchNote" — bold serif (DM Serif Display), white, centered
- **Icon**: SF Symbol `waveform`, Slate Light color, below title
- **Instruction**: "Press Action Button" / "to record" — Slate Light, small text
- **Indicator**: Small amber dot at very bottom center (ready indicator)

### RECORDING State
- **Background**: Ink (#0D1B2A), full bleed
- **Top bar left**: Red dot (8px) + "REC" in Recording red, monospaced bold
- **Top bar right**: Timer "0:12" in white, monospaced
- **Center**: 9 animated amber waveform bars, varying heights
- **Below waveform**: Live transcript text — white, 11px, left-aligned, scrollable (max ~60px height)
- **Bottom**: "Press to stop" — Slate Light, small text

### PROCESSING State
- **Background**: Ink (#0D1B2A), full bleed
- **Center**: Circular progress ring — amber stroke, 3px width, 36px diameter, rotating
- **Below ring**: "Transcribing..." — amber, 13px, medium weight
- **Below text**: Existing transcript — white at 0.7 opacity, 11px, scrollable

### SAVED State
- **Background**: Ink (#0D1B2A), full bleed
- **Center**: Green circle outline (3px stroke, 40px) with checkmark icon inside — Success green
- **Below circle**: "Saved to vault" — Success green, 13px, medium weight
- **Filename**: "watch_2026-03-26.md" — Slate Light, monospaced, 10px
- **Preview**: Quoted transcript excerpt — Slate Light, 10px, centered

---

## 06 — iPhone UX ("Full Screen Capture")

The iPhone app mirrors the watch's simplicity at a larger scale. Real-time transcription fills the screen as you speak. Settings live behind a single gear icon.

**No tab bar. Single full-screen capture experience.**

### READY State
- **Background**: Ink (#0D1B2A), full bleed, edge to edge
- **Top right**: Gear icon (`gearshape`) — Slate Light, 18px. Taps opens Settings sheet.
- **Center-upper**: "WatchNoteTaker" — bold serif (DM Serif Display), white, ~28px
- **Below title**: "Speak it. It's saved." — Slate Light, 15px
- **Lower area**: Idle waveform visualization — 20 vertical bars in Slate at 0.4 opacity, heights taper from center outward
- **Button**: Large amber circle (68px fill) inside outer ring (80px, amber at 0.4 opacity, 3px stroke). Mic icon (`mic.fill`) in Ink color centered inside.
- **Below button**: "Tap to record" — Slate Light, 13px
- **Counter**: "3 notes today" — Slate, monospaced, 12px

### RECORDING State
- **Background**: Ink (#0D1B2A), full bleed
- **Top bar left**: Red dot (10px) + "REC" — Recording red, monospaced bold, 13px
- **Top bar right**: Timer "00:47" — white, monospaced, 13px
- **Center**: Large animated waveform — 20 amber bars, 4px wide, heights animate randomly between 15%-100% of 60px
- **Below waveform**: Live transcript text — white, 17px, left-aligned. Latest/streaming words in lighter opacity (visual cue for real-time processing). Scrollable, max 300px height.
- **Button**: Red stop button — outer ring (80px, Recording at 0.4 opacity, 3px stroke) with rounded square (28px, 6px corner radius) filled Recording red inside.
- **Below button**: "Tap to stop" — Slate Light, 13px

### PROCESSING State (after stop)
- **Background**: Ink, full bleed
- **Center**: ProgressView spinner, 1.5x scale, amber tint
- **Below**: "Transcribing..." — amber, 17px, medium weight
- **Transcript**: Existing text in Ink Mid card (rounded rect, 12px radius), white at 0.7 opacity

### SAVED State (briefly shown after save)
- **Center**: Green circle outline (60px, 3px stroke) with checkmark — Success green
- **Below**: "Saved to vault" — Success green, 17px, semibold
- **Card**: Transcript in Ink Mid rounded rect, white at 0.7 opacity, scrollable

---

## 07 — Settings Screen

Accessed via gear icon on main screen. Presented as a sheet with NavigationStack.

- **Background**: Ink (#0D1B2A)
- **Navigation**: "← Back" in amber (left) + "Settings" title (white, bold)
- **Card style**: Each row is Ink Mid (#1B2D45) background, 16px horizontal/vertical padding
- **Section headers**: Monospaced, Slate color, 11px, semibold, 2pt letter-spacing, ALL CAPS

### Sections

**VAULT**
| Row | Left | Right |
|-----|------|-------|
| Obsidian Vault | Label (white) + path (Slate Light, mono) | Chevron (Slate) |
| Save Folder | Label (white) + "00_inbox/" (amber, mono) | — |

**TRANSCRIPTION**
| Row | Left | Right |
|-----|------|-------|
| Language | "Language" (white) | "Auto ›" (Slate Light) — Picker |
| AI Model | "AI Model" (white) | "large-v3 ›" (Slate Light, mono) |

**BEHAVIOR**
| Row | Left | Right |
|-----|------|-------|
| Action Button | "Action Button" (white) | Green toggle (Success color) |

**STORAGE**
| Row | Left | Right |
|-----|------|-------|
| Info | "Model: 580 MB · Notes: 2.1 MB" (Slate Light, 13px) | — |

---

## 08 — Obsidian Output ("The Note Format")

Each day's captures consolidate into a single file with clear timestamps. No inbox explosion — just one clean daily log.

**Filename**: `watch_2026-03-26.md`

```markdown
# Watch Notes — 2026-03-26

## 09:14

I need to remember to check the API rate limits before deploying the update.

## 11:32

The meeting with the design team went well. We agreed on the new color palette.

## 14:07

Quick thought about the sync module — we should use a queue-based approach.

#meeting #design
```

---

## 09 — UI Components ("Building Blocks")

Reusable elements across Watch and iPhone interfaces. Every component carries the same visual DNA.

### Buttons
| Button | Appearance |
|--------|------------|
| **Record** | Amber filled circle (68px) inside amber ring (80px), mic icon in Ink |
| **Recording** | Red dot prefix, "Recording" label in Recording red |
| **Saved** | Checkmark prefix, "Saved" label in Success green |
| **Settings** | Gear icon in Slate Light |

### Status Indicators
| State | Color | Element |
|-------|-------|---------|
| Idle | Slate Light | Small text label |
| Rec | Recording red | Red dot + "REC" label, monospaced |
| Saved | Success green | Checkmark + label |

### Live Waveform
- Vertical bars, amber colored
- 9 bars (watch) or 20 bars (iPhone)
- Heights animate randomly between 15%–100%
- Bar width: 3px (watch), 4px (iPhone)
- Spacing: 3px (watch), 4px (iPhone)

### Timestamp
- Format: `## 09:14` — amber, monospaced (JetBrains Mono)
- Filename: `watch_2026-03-26.md` — Slate Light, monospaced

---

## 10 — Design Tokens ("Spacing & Radius")

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | 4px | Tight internal padding |
| `--space-sm` | 8px | Compact elements |
| `--space-md` | 16px | Standard spacing |
| `--space-lg` | 24px | Section gaps |
| `--space-xl` | 40px | Major sections |
| `--radius-sm` | 8px | Badges, chips |
| `--radius-md` | 12px | Cards, inputs |
| `--radius-lg` | 20px | Panels, modals |
| `--radius-xl` | 28px | Buttons, pills |

---

*Speak it. It's saved.*
*WatchNoteTaker Design System v1.0 — March 2026*
