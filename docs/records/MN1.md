# MN1 · The title, the top bar and the menus' look

**Review:** 1 attempt · critic Accept 8/8 (Sonnet) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet 5.5 (worker) | ✓ | 8/8 Accept | – (QA Fail: focus after the credits; performance Fail: menus alive in play; both fixed by the thread before the critic) |

## Decisions

- **Owner, 2026-10-19: no fullscreen button on the title.** The window mode stays in Settings › Display.
- **Owner, 2026-10-19: the version sits bottom right, beside Licences.** The foot reads, left to right: version,
  Licences, QUIT. Nothing goes bottom left.
- **START opens the menus** (`MenuScreen`: the top bar over the Match page). The page body is a stand-in until MN2:
  the map choice (the existing `OptionButton`, same dev-content rule) and the slanted PLAY button, so the game stays
  playable. Esc on the menus goes back to the title; leaving a match comes back to the title, as the pause menu says.
- **QUIT is a quiet text button** in the foot (the concept has none; a desktop game needs one).
- **Level chip reads "LVL 1"** (no levels yet; `TopBar.LEVEL`).
- **The top bar's SETTINGS tab opens the existing `SettingsScreen` under the bar** (its top offset is the bar's
  height), lit while open; MATCH closes it. Settings was not restructured: margins 56 px, headings and tab names in
  capitals through `to_upper()`, row labels as the translation file has them.
- **One look on `GameTheme`:** the concept's palette as constants; Button, tabs, panels, sliders, scroll bars, inputs
  styled; variations `MainButton` (slanted, `SlantStyle`, drawn with `RenderingServer` polygons so no texture), `QuietLink`
  and `QuietLinkRuled` (Licences' rule is a stylebox border, since `Button` has no underline in 4.7). Letter spacing
  comes from cached `FontVariation`s (`GameTheme.spaced_font`).
- **Menu scale (`MenuScale`):** effective scale = min(1.5, min(width/1920, height/1080)); the content scale factor is
  that over the stretch's own scale, so it is 1 up to 1.5x and 0.75 at 4K (measured: 3840x2160 gives a 2560x1440
  visible rect). Chosen from the browser's rule: no never-below-1 (canvas_items already shrinks a small window, as it
  does the HUD) and no 1500 px width hold-back (aspect "expand" scales by the narrower side, so the layout always keeps
  its 1920 px of width). Applied on `size_changed`, reset to 1 while a match is on and when main is freed.
- **Title backdrop** is the concept's `bg-blur.jpg` (a 1920x1080 render of the current build, blurred and darkened),
  shipped as `assets/ui/title-backdrop.jpg` (59 KB), logged in `docs/ASSETS.md` as made in-house. To re-render: play
  Depot, capture a frame at 1920x1080 (a scratch SceneTree script saving `root.get_texture().get_image()`), blur it
  heavily and darken it; no tool script is kept. The left shade is a `GradientTexture2D` (95 %, 75 % at 38 %, 15 % at
  70 % of the page colour), as the HTML's.
- **Words** are translation keys `MENU_*` in `game/ui/text/en.po`; `BOOT_PLAY`, `BOOT_CREDITS`, `BOOT_QUIT` and
  `BOOT_SETTINGS` are gone with the old boot screen.
- **Credits** drawn in the new look (page colour, capital heading and Back, themed text box); Esc and the smoke path
  unchanged.
- **Screenshots** (Xvfb, OpenGL, 1920x1080 and 3840x2160) are in `/mnt/project-files/screens/menus/mn1-*.png`.

- **A match frees the title and the menus; leaving rebuilds them** (performance review: they kept 52 hidden nodes
  through the match). An open Settings closes first. The picked map lives in `main.gd`, so it survives the rebuild.
- **The credits say when they close** (`Credits.closed`), and the title takes the focus back to START, so Enter starts
  again without a Tab (QA).

## Known issues left

Each has a row in `docs/KNOWN_ISSUES.md`.

- The Match page body is a stand-in until MN2.
- The menu scale is off in play, so Settings from the pause menu is not capped at 1.5x.
- START and PLAY show a focus ring on open; a real display, a mouse and 4K are unchecked.
