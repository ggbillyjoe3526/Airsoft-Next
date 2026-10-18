class_name NavVaults
## Vault links (the browser game's nav/vaultLinks.ts, M102): where a body can vault a low obstacle (Vault.plan), a link
## from the node it stands on to the node past the obstacle, so a bot's route can go over it. Found from the grid (a
## walkable node beside a blocked one of the same floor) and the level's rays, along the grid's four axes: the maps'
## blocks are all square to them, so a vault straight across is the one a bot walks. Each link costs its length plus
## `price` metres (a vault is slower than its length on foot, the replica is carried, and it is loud), so a route takes
## one only where it saves more than that walking round.
##
## In the search each link is a point of its own between the two nodes (AStar3D prices a step by its length times the
## weight of the point stepped onto), one way, weighted so the two halves cost the link's price.

## The four straight steps, as (di, dj).
const DI: Array[int] = [1, -1, 0, 0]
const DJ: Array[int] = [0, 0, 1, -1]
## How far past the vault's clear point the landing node is looked for, in cells (the first walkable one wins).
const LAND_CELLS: Array[int] = [1, 2, 3]


## Finds `g`'s vault links through `query` (a body standing on each node, from a standstill) and adds them to its
## search, enabled. Once per grid: a second call does nothing. Returns how many there are.
static func link(g: NavGrid, query: WorldQuery, vault: VaultConfig, body: BodyConfig, price: float) -> int:
	if g.vault_base >= 0:
		return g.vault_to.size()
	var nodes := g.node_count()
	var start := PackedInt32Array()
	start.resize(nodes + 1)
	var to := PackedInt32Array()
	var plan := VaultState.new()
	var weight := 0.0
	for k in nodes:
		start[k] = to.size()
		if g.walkable[k] == 0:
			continue
		if weight == 0.0:
			weight = g.astar.get_point_weight_scale(k)
		var c := g.node_cell[k]
		var ci := c % g.cols
		var cj := c / g.cols
		for d in DI.size():
			var ni := ci + DI[d]
			var nj := cj + DJ[d]
			if ni < 0 or nj < 0 or ni >= g.cols or nj >= g.rows:
				continue
			var n := g.step_node(k, nj * g.cols + ni)
			if n < 0 or g.walkable[n] == 1:
				continue
			var feet := g.node_position(k) + Vector3(0.0, body.rest_gap, 0.0)
			var way := Vector2(DI[d], DJ[d])
			if not Vault.plan(feet, way, 0.0, vault, body, query, plan):
				continue
			for cells: int in LAND_CELLS:
				var s := plan.far + cells * g.cell
				var m := g.node_at(Vector3(feet.x + way.x * s, plan.top_y, feet.z + way.y * s))
				if m < 0 or g.walkable[m] == 0:
					continue
				to.append(m)
				break
	start[nodes] = to.size()
	g.vault_start = start
	g.vault_to = to
	g.vault_base = nodes
	for k in nodes:
		for l in range(start[k], start[k + 1]):
			_add_point(g, k, to[l], nodes + l, weight, price)
	return to.size()


## The link from node `k` to node `m` as search point `id`, between them, so the step on and the step off together cost
## (length + price) at the grid's `weight`.
static func _add_point(g: NavGrid, k: int, m: int, id: int, weight: float, price: float) -> void:
	var a := g.node_position(k)
	var b := g.node_position(m)
	var length := maxf(a.distance_to(b), g.cell)
	var half := length * 0.5
	g.astar.add_point(id, (a + b) * 0.5, weight * (half + price) / half)
	g.astar.connect_points(k, id, false)
	g.astar.connect_points(id, m, false)
