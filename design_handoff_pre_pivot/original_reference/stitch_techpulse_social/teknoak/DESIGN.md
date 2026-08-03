---
name: TeknoAkış
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#d0bcff'
  on-secondary: '#3c0091'
  secondary-container: '#571bc1'
  on-secondary-container: '#c4abff'
  tertiary: '#d8ffe7'
  on-tertiary: '#003824'
  tertiary-container: '#65f2b5'
  on-tertiary-container: '#006d4a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#d0bcff'
  on-secondary-fixed: '#23005c'
  on-secondary-fixed-variant: '#5516be'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  mono-label:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.05em
  mono-code:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: '1.5'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The design system for this high-end tech social network is built on a "Hyper-Technical Minimalism" aesthetic. It targets a sophisticated audience of developers, AI researchers, and tech enthusiasts who value precision, information density, and high-performance interfaces. 

The style merges **Minimalism** with **Developer-Centric Modernism**, utilizing sharp layouts, high-contrast accents, and subtle technical embellishments (like micro-grids and data-heavy metadata). The emotional response should be one of focused intelligence, professional reliability, and cutting-edge innovation. The UI prioritizes content clarity and technical utility over decorative flourishes, ensuring that complex data—like code snippets or model parameters—remains the primary focus.

## Colors
The palette is optimized for a **Default Dark** environment to reduce eye strain during long-form technical reading. 

- **Primary (Tech Blue):** Used for primary actions, active states, and highlighting key technical metrics. 
- **Secondary (Controlled Purple):** Used for secondary interactions and categorization, such as AI-specific labels or research tags.
- **Background & Surface:** A deep "Navy Black" foundation ensures maximum contrast for the vibrant primary and secondary colors. Surfaces use a slightly lighter "Anthracite" to create subtle depth without relying on heavy shadows.
- **Semantic Accents:** Success Green for GitHub stars and stable builds; Trend Orange for trending discussions; Critical Red for breaking news or high-priority alerts.

The **Light Mode** variant flips these values, using a cool-gray background (`#f8fafc`) with primary and secondary colors maintaining their hue but adjusted for legibility against light surfaces.

## Typography
The typography system balances modern sans-serif readability with technical monospaced precision.

- **Headlines:** Uses **Geist** for a clean, geometric, and developer-friendly feel. Bold weights are preferred to establish clear hierarchy.
- **Body:** Uses **Inter** at a minimum of 16px to ensure accessibility and high legibility for long-form technical posts and research summaries.
- **Technical Details:** **JetBrains Mono** is reserved for all metadata, code snippets, version numbers, and system status labels. 

On mobile devices, headline sizes scale down to preserve screen real estate while maintaining weight to keep the brand's bold character. All text uses high-contrast colors (Pure White `#ffffff` on Dark, Near Black `#0f172a` on Light).

## Layout & Spacing
This design system employs a **Fluid Grid** model optimized for mobile-first consumption.

- **Mobile:** A 4-column grid with 16px margins. Components typically span the full width.
- **Tablet/Desktop:** A 12-column grid with 24px gutters. Content is centered with a max-width of 1200px.
- **Spacing Rhythm:** Based on a 4px baseline. Use 16px (`md`) for standard padding within cards and 24px (`lg`) for vertical spacing between different content blocks. 
- **Density:** High density is encouraged for technical data. Use `sm` (8px) for grouping related metadata chips.

## Elevation & Depth
The design system avoids heavy shadows, instead using **Tonal Layers** and **Low-Contrast Outlines** to define hierarchy.

- **Surfaces:** Depth is created by moving from the background (`#0c0e12`) to a surface (`#1a1c20`).
- **Outlines:** Cards and inputs use a subtle 1px border (`#2d3139`) to define their boundaries.
- **Active State:** When a card or element is focused, the border transitions to the Primary Tech Blue with a very subtle 4px outer glow (0% to 20% opacity).
- **Glassmorphism:** Reserved exclusively for top navigation bars and floating action buttons, using a 12px backdrop-blur and 60% opacity of the surface color to maintain context of the scroll position.

## Shapes
To maintain a technical and "engineered" look, the design system uses **Soft (Level 1)** roundedness. 

- **Standard Elements:** 0.25rem (4px) radius for buttons, input fields, and small tags.
- **Containers/Cards:** 0.75rem (12px) radius for a modern feel that isn't overly organic.
- **Interactive Indicators:** Strict square corners may be used for decorative technical accents (like the edge of a code block) to emphasize the "terminal" aesthetic.

## Components

### Technical Cards
Cards are the primary container for content and must follow specific metadata patterns:
- **GitHub Cards:** Display repo name in `headline-md`, followed by a row of `mono-label` chips for Stars (Success Green), Language, and License. Include a small "sparkline" visualization for activity if available.
- **AI Model Cards:** High-density layout. Primary label for Model Type (e.g., "LLM", "Diffusion"), secondary label for Provider (e.g., "HuggingFace", "OpenAI"). Use a monospaced "Diff" indicator to show version updates.
- **Research Cards:** Focus on the "Abstract" using `body-sm`. Top-right corner reserved for a "Peer Reviewed" or "Pre-print" tag in `mono-label`.

### Buttons & Inputs
- **Primary Button:** Solid Tech Blue background with black text for maximum contrast. 
- **Ghost Button:** Tech Blue outline with `mono-label` text for secondary technical actions.
- **Inputs:** Dark grey background with a 1px border. On focus, the border turns Tech Blue. Use `mono-code` for the input text.

### Feedback & Status
- **Chips:** Small, rectangular with 4px radius. Use primary/secondary colors for categories and semantic colors (Green/Orange/Red) for status.
- **Lists:** Clean, border-bottom separated items. Use chevron-right icons for navigation, styled in Tech Blue.
- **Code Blocks:** Deep black background (`#000000`), JetBrains Mono font, and syntax highlighting following a "Midnight" theme.