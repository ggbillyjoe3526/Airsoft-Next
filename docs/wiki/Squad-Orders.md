# Squad Orders

Your bot teammates follow the team's plan on their own, but you can tell them what to do. Orders go to every
teammate still in play.

| Order | Key | What your teammates do |
| --- | --- | --- |
| **Follow Me** | F | Stay with you and keep up as you move. |
| **Hold Here** | X | Spread out across the spot you are looking at and hold it (where they stand, if you look at nothing in reach). |
| **Regroup** | V | Come back to you. |
| **Team Plan** | wheel only | Drop your order and go back to the team's own plan. |

Hold **Z** to open the **order wheel** round the crosshair: point at an order with the mouse and let go (or click,
with **Order wheel: Click** in Settings › Controls › Squad orders). The slice you point at lights yellow, and the order
in force wears a blue band and an **ACTIVE** tag. While the wheel is open the mouse aims it instead of turning your
view.

- You hear a **radio click** when your team takes an order. That click is the only confirmation: there's no order text
  on the HUD. An order nobody can take is silent, and the wheel's middle says why (for example "No teammates in play
  to order").
- **Hold Here** puts a "HOLD · 18 M" marker over the spot, with a dashed ring on the floor. Turn away and it slides to
  the screen edge with an arrow. The minimap shows it as a diamond.
- An order lasts until you give another, until you are hit, or until the round ends. In Attack / Defend it overrides
  your teammates' work at the pole.
- Orders do nothing on the [Practice Range](Practice-Range), where there's nobody to order.

All four keys can be rebound in Settings › Controls ([Controls](Controls)).

## In development

**Pings:** press the **middle mouse button** (Squad: ping a spot in Settings › Controls) to mark where your crosshair
meets the field, up to <!-- wiki:config ping_config.reach --> m away, for your bot teammates; the sky marks nothing.
An opponent under your crosshair that you can see is marked as a contact instead, and counts as a threat. Your
teammates take a ping as somewhere worth a look, kept in mind for <!-- wiki:config bot_config.ping_memory --> seconds
unless they see or hear something newer: one sets off to check it the way it plays (a rusher runs, a careful bot walks
in), and one under your order, at its post or holding watches it instead. A teammate in a fight, in cover or with
someone in sight carries on. One of them answers in the hit feed, "Going to your ping" or "Watching your ping" in its
own words. You have one ping at a time and a double click is one ping; pings clear each round and do nothing while you
are out or on the [Practice Range](Practice-Range). Nothing marks the spot on screen yet: the answer is the sign it was
taken.
