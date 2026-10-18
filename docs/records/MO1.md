# MO1 · Holster and a smoother lean and vault

**Review:** 1 attempt · critic Accept 8/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – (QA's NaN with a zero ease time fixed; QA added 10 tests) |

## Decisions

- **The holster is the browser game's (M92):** 3 puts the replica away (a one-shot `PlayerCommand.holster`), cancelling
  a reload, a draw and a burst. A slot, a fresh trigger pull, an aim press or a reload draws it at 1.8 times its draw
  time; a trigger or aim held as it went away doesn't. Holstered you run at 5.4 m/s, never past the sprint; walking
  and crouching are no faster.
- **Bots holster by the same command** (`game/ai/bot_holster.gd`): after 1.5 s of calm sprinting in their own half,
  drawing again on a threat, a reload, past halfway, or half a second after the sprint stops.
- **Presses mid-vault:** a holster or a dial turn made during a vault is kept for after it, as a reload or a slot
  already was. The vault's command now carries the aim as the vault found it, so an aim held through a vault doesn't
  draw a holstered replica on landing (the browser game's vaultPresses rule). This also fixes BB1's dial turns being
  dropped mid-vault.
- **A cut lean eases out in 0.1 s,** never more than 0.1 m further out than the simulation's eye, bounded by the eye's
  pace near upright (the lean swings it on an arc, so the pace there is the steepest). A normal release is drawn as
  it is. The browser game's render code wasn't salvaged, so the vault's **dip (0.12 m) and tip (0.14 rad)** peak at the
  vault's middle and follow at 18/s on rendered frames: a first guess to tune by play.
- **"Space to vault"** shows under the crosshair while a Jump press would vault the way your keys push (the same
  `Vault.find_along` rule the vault uses), held 0.15 s after, the browser game's prompt. The player only.
- **The figures carry no replica yet,** so they have no holstered pose.

## Known issues left

None new. "Space to vault" names the key as fixed text until rebinding comes with settings (SE1; the
no-settings row in `docs/KNOWN_ISSUES.md`).
