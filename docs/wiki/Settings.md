# Settings

Open **Settings** from the title screen's top bar or the pause menu. Every change applies at once, even in the middle
of a match, and is saved straight away. If the settings file is ever damaged, the game starts on the defaults and
says so.

## Controls

Hip and aimed mouse sensitivity (also as centimetres per 360° at your mouse's DPI), invert vertical look, crouch and
aim as hold or toggle, two keys for every action, and the **Squad orders** section with Order wheel: Hover or Click.
The default keys are on [Controls](Controls).

## Audio

Volumes for **Master**, **Effects**, **Power source** (the motor or gas part of a shot), **Ambience** and
**Interface**.

## Display

- **Window mode:** Windowed, Borderless fullscreen or Exclusive fullscreen. The game opens in the mode you left.
  **F11** or **Alt+Enter** switches between windowed and your last fullscreen mode.
- **Monitor:** with two screens or more, the screen the window opens on.
- **V-Sync** (on by default) and a **Frame rate** limit: Unlimited, or 30 to 360 frames a second. In the background
  the game drops to 30 frames a second.
- **Field of view** and **Show FPS**.

## Graphics

Pick a preset or set each row yourself. The game starts on the preset picked for your graphics card, marked **FOR YOUR
CARD**: Medium for built-in graphics, High for a separate card, never Ultra. Changing a row makes the preset
**Custom** and marks what you changed; **Reset** goes back to the pick for your card.

<!-- wiki:graphics -->

- **Low** is for speed: no sun shadows, ambient occlusion, baked light or wind dust, and a lower render scale. Every
  player gets a soft shadow under their feet instead.
- **Baked light** gives Depot soft shade in its corners and warm light bounced off sunlit walls.
- While graphics are on **For your card**, slow frames in a match step the preset down one at the end of a round,
  never mid-round and never below Low, with a short note under the score. A preset you picked yourself never steps
  down.
- Choices your graphics card or renderer can't draw are greyed out, with the reason.
- **Start-up › Renderer** picks Auto or Compatibility (the simpler renderer) from the next start. If the game closes
  while drawing its graphics, the next start restarts once on the simpler renderer and Low, then asks whether to keep
  safe graphics or try your settings again.

If the game stutters, lower the preset or the render scale first.

## HUD

- **Crosshair:** shape (cross, cross and dot, circle or dot), colour, size, thickness, gap and opacity, dynamic or
  static spread, and an outline, with a live preview.
- **Hit marker:** on or off, with its own colour and size.
- **Ammo counter:** off hides every BB count, and each magazine gauge only shows whether it holds BBs.
- **Hit feed:** top right or bottom left; lines fade after a few seconds, or on **Keep** the last 10 hits stay up all
  match.
- **HUD opacity** sets how solid the panels are; text stays solid.
- **HUD size** from 80 % to 150 %. The crosshair and hit marker keep their size.
- **What got you:** Auto, On or Off ([HUD and Minimap](HUD-and-Minimap#what-got-you)).
- **Minimap:** Rotating or Fixed.
- **Callouts:** On (the default) shows your teammates' calls in the hit feed with a radio click, and lets you hear
  enemies close by keying their radios. Off hides the calls and stops every call's click at once; a squad order a
  teammate takes still clicks.
- **Ping markers:** On (the default) shows your pings and your teammates' marks over the field with their distance,
  and on the minimap. Off hides only the markers: your pings still reach your teammates, the pip still plays and they
  still answer.
- **Mag hand-off:** On (the default) shows the magazine hand-off's line under the crosshair and the magazine by a
  teammate's chevron. Off hides only those: Need a Mag still asks and tosses, and your teammates still call it.

## Accessibility

Team colours, gauge patterns, sound cues, reduced motion and screen reader messages: see
[Accessibility](Accessibility).

## Save file

Your save, its folder and its restore points: see [Saving and Bug Reports](Saving-and-Bug-Reports).

## Dev settings

The **Dev** tab holds tools for testing the game, such as game speed and spectating bots. Every one is off until you
turn it on, and a match played with one that changes how it plays stays out of your records and gives no XP. [Development](Development#dev-settings) lists them.
