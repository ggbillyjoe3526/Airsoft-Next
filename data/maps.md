# Maps: which fields are listed

Every map the game can load (`data/maps/<id>.json`) has one row here: its name as shown, whether it is public or still
dev content, and a line about it. A `dev` map is listed only while the Dev tab's Dev content switch is on, and a match
on one stays out of the records (`docs/DECISIONS.md` › Content tags and dev content). Making a map public means
changing its Tag to `public`; Woodland and Neon Heights stay dev until the owner has playtested them and makes each
public himself.

**The game reads this file** when it starts (`game/map/map_catalog.gd`). A row it can't read is left out with a
warning; a map with no row is not listed.

- **Id** is the map file's name without `.json`.
- **Kind** is `field` for a match map (listed in the Map choice) or `range` for the practice range (listed beside the fields, with Practice as its only mode).
- **Tag** is `public` or `dev`.

## Maps

| Id | Name | Kind | Tag | Blurb |
|---|---|---|---|---|
| depot | Depot | field | public | An abandoned warehouse yard. |
| woodland | Woodland | field | dev | A wide wood with a hill, at night. |
| neonHeights | Neon Heights | field | dev | A neon city block on three floors. |
| range | Range | range | public | Targets 10 to 60 m. No bots, no score. |
