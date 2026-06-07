---
inclusion: manual
---

# Brand Pack Generator

A one-shot brand starter kit. Activate this skill by saying:

> generate brand pack for **<name>**

Where `<name>` is the brand the pack belongs to (e.g. *RADHA*, *Acme*, *Northbeam*).

## What this skill produces

A coherent set of brand assets, all generated through `kiro-gpt-bridge` with `enhance_prompt: true`, all bucketed under `assets/` per the rules in `.kiro/steering/visual-assets.md`:

| Asset | Tool | Output path |
|---|---|---|
| Primary logo (light + dark) | `generate_logo` | `assets/logo/{brand}-primary-{light|dark}.png` |
| Marketing hero | `generate_hero` | `assets/hero/{brand}-marketing-hero.png` |
| Six-icon UI set | `generate_icon_set` | `assets/icon/{brand}-{icon}.svg` × 6 |
| Homepage UI mockup | `generate_ui_mockup` | `assets/mockup/{brand}-homepage.png` |

Slugs are kebab-cased from the brand name.

## Workflow (run these steps top to bottom)

### 1. Confirm the brand palette

Read `.kiro/steering/visual-assets.md` → "Brand palette" section.

- If the palette still shows the placeholder values (`#1A1A1A`, `#FAFAF7`, `#C9512E`), STOP and ask the user:
  > "Before I generate the brand pack, the palette in `.kiro/steering/visual-assets.md` is still the placeholder. What are the real brand hex colours and display font?"
- If the palette has been edited, proceed using those values verbatim. Do not re-pick colours yourself.

### 2. Generate the logo

Call `generate_logo` once per variant (light background + dark background):

```
generate_logo({
  brief: "<200–600 char brief naming style anchor, geometric construction, exact hex from palette, negative anchors>",
  enhance_prompt: true,
  output_path: "assets/logo/{brand-slug}-primary-light.png"
})
```

Repeat with `-primary-dark.png` and the inverted background hex.

### 3. Generate the marketing hero

```
generate_hero({
  brief: "<200–600 char brief — context: marketing landing for {brand}, use exact palette hex, single accent, mention concrete style anchor like 'editorial swiss poster' or 'bauhaus geometric', append negative anchors>",
  enhance_prompt: true,
  output_path: "assets/hero/{brand-slug}-marketing-hero.png"
})
```

### 4. Generate the icon set

Always use this exact six-icon roster: `search`, `settings`, `user`, `cart`, `heart`, `menu`.

```
generate_icon_set({
  brief: "<200–600 char brief — line-only or glyph style, 24×24 grid, 1.5px stroke, single accent on hover state mark, exact palette hex, negative anchors>",
  icons: ["search", "settings", "user", "cart", "heart", "menu"],
  enhance_prompt: true,
  output_dir: "assets/icon/"
})
```

Files land as `assets/icon/{brand-slug}-{icon}.svg`.

### 5. Generate the homepage mockup

```
generate_ui_mockup({
  brief: "<200–600 char brief — 'desktop homepage at 1440px wide, hero + three-card row + footer', name the layout shape, exact palette hex, single accent, mention typography from palette, negative anchors including 'no purple gradients, no centered hero with 3 equal cards'>",
  enhance_prompt: true,
  output_path: "assets/mockup/{brand-slug}-homepage.png"
})
```

### 6. Summarise to the user

Once all calls succeed, print a markdown table of what was saved:

```
## {brand} brand pack — generated

| Asset | Path |
|---|---|
| Primary logo (light) | assets/logo/{brand-slug}-primary-light.png |
| Primary logo (dark)  | assets/logo/{brand-slug}-primary-dark.png |
| Marketing hero       | assets/hero/{brand-slug}-marketing-hero.png |
| Icon — search        | assets/icon/{brand-slug}-search.svg |
| Icon — settings      | assets/icon/{brand-slug}-settings.svg |
| Icon — user          | assets/icon/{brand-slug}-user.svg |
| Icon — cart          | assets/icon/{brand-slug}-cart.svg |
| Icon — heart         | assets/icon/{brand-slug}-heart.svg |
| Icon — menu          | assets/icon/{brand-slug}-menu.svg |
| Homepage mockup      | assets/mockup/{brand-slug}-homepage.png |
```

Do not include URLs, prompts, or generation metadata in the summary — just the table of saved paths.

## Rules

- Always run steps 1 → 6 in order. Do not skip the palette check.
- Every tool call must include `enhance_prompt: true`.
- Every brief follows the 200–600 char + concrete anchors + hex + negative-anchor rules from `.kiro/steering/visual-assets.md`.
- If any tool call fails, surface the error to the user and stop the sequence — do not best-effort partial.
- Never overwrite a file that already exists at the target path. If a path is taken, append `-v2`, `-v3`, etc.
- After the run finishes, do not auto-commit or stage the new files.
