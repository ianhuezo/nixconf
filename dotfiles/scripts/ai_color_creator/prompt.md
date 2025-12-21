# Wallpaper-to-System Theme Generator (Base16 for Kitty/Neovim/Qt)

Extract a **cohesive color scheme** from the wallpaper for terminal, editor, and desktop UI. Prioritize mood authenticity over conventional color assignments.

## Philosophy
**Anti-Pattern**: Forcing Red/Green/Blue/Yellow into monochromatic images.
**Goal**: If the wallpaper is sepia-orange, your palette should be sepia-orange. No outliers.

---

## Analysis Phase

**1. Identify the Mood**
- Visual style: Painterly? Neon? Muted? Noir? Pastel?
- Hue range: Full spectrum (rare) or 2-4 color families (common)?
- Saturation: Bold (80-100%) or soft/dusty (30-50%)?
- Brightness: High-key (light) or low-key (dark)?

**2. Determine Variant**
- Dark wallpaper → `"variant": "dark"`, base00 = deep atmospheric tone
- Light wallpaper → `"variant": "light"`, base00 = warm/cool white

**3. K-Means Color Reference (Use as Inspiration, Not Prescription)**
The following 32 colors were extracted from the wallpaper via k-means clustering, shown as HEX = HSL (percentage):

(Note: We extract 32 clusters instead of 16 to better capture minority accent colors that might otherwise be absorbed into dominant tones. Look for interesting low-percentage colors!)

**KMEANS_COLORS_PLACEHOLDER**

**Understanding HSL values**:
- **Hue (0-360°)**: The color angle - blues ~210-240°, purples ~270-300°, reds ~0°/360°, greens ~120°, yellows ~60°
- **Saturation (0-100%)**: Color intensity - low saturation = grayish/muted, high = vivid
- **Lightness (0-100%)**: Brightness - 0% = black, 50% = pure color, 100% = white

**IMPORTANT**: These are *statistical samples*, not your final palette. Use them as:
- **Mood validators**: High % colors confirm the dominant atmosphere (backgrounds should align with their hue/lightness)
- **Saturation guidance**: Notice if the image is muted (low S%) or vibrant (high S%) and match that energy
- **Accent inspiration**: Low % colors (<5%) reveal subtle details worth amplifying - boost their saturation if needed!
- **Creative freedom**: If you see potential colors the image *could* support (warmer highlights, cooler shadows), add them! The kmeans data is mechanical - your job is artistic.

**Example**: If kmeans shows mostly hsl(220, 15%, 12%) but you see moonlight could justify hsl(200, 30%, 85%) or shadows could be warmer hsl(260, 20%, 8%), use those!

---

## Color Extraction Rules

### **Base00-07: The Foundation**
Must feel like the wallpaper's material:

**Backgrounds (base00-03)**:
- base00: Main background (never pure black/white)
- base01: UI panels, sidebars (+5-10% lighter)
- base02: Selection/hover states (+10-15% lighter)
- base03: Borders, disabled elements (+15-25% lighter, visible but recessive)

**Foregrounds (base04-07)**:
- base04: Secondary text, icons (60% contrast with base00)
- base05: Primary text (4.5:1 contrast minimum with base00)
- base06: Emphasized text (+10% brighter than base05)
- base07: Brightest highlights (+20% brighter than base05)

**Temperature Rule**: Warm wallpaper → warm grays. Cool wallpaper → cool grays.

### **Base08-0F: The Accents** — ABANDON THE RAINBOW

**Standard Base16 (IGNORE THIS)**:
- base08=Red, base0B=Green, base0D=Blue, base0E=Magenta

**YOUR APPROACH**: Extract the 8 most expressive colors from the wallpaper's actual palette.

#### **Functional Requirements** (for usability):
You need **4+ visually distinct** colors for:

1. **base08** (Alerts/Errors): The "danger" color — typically warmest or most saturated
2. **base0B** (Success/Strings): The "safe" color — can be any mid-tone that contrasts with base08
3. **base0D** (Actions/Functions): The "interactive" color — most prominent/saturated accent
4. **base0E** (Special/Keywords): The "unique" color — distinct hue from base08/0B/0D

**Remaining (base09/0A/0C/0F)**: Can be:
- Variations of the above (warmer/cooler shifts)
- Neutral bridges (desaturated tones between main accents)
- Duplicates if the wallpaper is truly limited (base0C = base0B is acceptable)

#### **Desktop UI Considerations**:
- **base0D**: Primary buttons, focus rings — make it **bold and inviting**
- **base08**: Destructive actions — ensure it **visually warns**
- **base0B**: Success states — should feel **affirming**
- **base02**: Hover states — must have **subtle contrast** with base00

#### **The Cluster Strategy**:
If the wallpaper is:
- **Monochrome Blue**: Use navy, sky, teal, periwinkle for all accents
- **Earth Tones**: Use ochre, rust, olive, umber — no electric blue
- **Sunset Palette**: Use coral, amber, rose, burgundy — no cyan
- **Cyberpunk**: Go full neon in existing hues — no pastels

**Anti-Patterns**:
❌ Adding bright blue to a sepia image "for links"
❌ Forcing green into a red/orange palette "for success"
❌ Using base0A (yellow) if the wallpaper has zero yellow

---

## Validation Checklist
- [ ] **Cohesion**: Palette blends seamlessly with wallpaper
- [ ] **No Outliers**: Every color exists (or could exist) in the image
- [ ] **UI Clarity**: base0D/base08/base0B are visually separable
- [ ] **Contrast**: base05 readable on base00 (test small text)
- [ ] **Desktop Usability**: Hover states (base02) are noticeable but subtle

---

## Output
Return ONLY valid JSON:
```json
{
  "slug": "theme-name",
  "name": "Theme Name",
  "author": "AI Assistant",
  "variant": "dark",
  "palette": {
    "base00": "#HEX",
    "base01": "#HEX",
    "base02": "#HEX",
    "base03": "#HEX",
    "base04": "#HEX",
    "base05": "#HEX",
    "base06": "#HEX",
    "base07": "#HEX",
    "base08": "#HEX",
    "base09": "#HEX",
    "base0A": "#HEX",
    "base0B": "#HEX",
    "base0C": "#HEX",
    "base0D": "#HEX",
    "base0E": "#HEX",
    "base0F": "#HEX"
  }
}
```

**Now analyze the wallpaper. Extract its true color story. Generate the JSON.**
