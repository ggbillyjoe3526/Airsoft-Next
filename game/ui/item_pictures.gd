class_name ItemPictures
extends RefCounted
## The picture of any pool item, drawn from its own model by a ReplicaPictures (so an attachment always looks like its model,
## the way Customise and the Loadout show it): a replica in the paint it starts in (a Cobalt rifle, a Ghost pistol), a
## power source from its model (PowerModels), a part alone, on the first replica whose part models have it. Null for an
## item with no model.

## The paint a part is drawn in.
const PART_PAINT := &"cobalt"

var _pool: Pool = null
var _pictures: ReplicaPictures = null
var _rules: LoadoutRules = null


## `rules` gives each replica its starting paint (LoadoutRules.default_tune); none: the shipped rules, read when a
## replica is first drawn.
func _init(pool: Pool, pictures: ReplicaPictures, rules: LoadoutRules = null) -> void:
	_pool = pool
	_pictures = pictures
	_rules = rules


func texture(item: Pool.Item) -> Texture2D:
	match item.kind:
		Pool.Kind.REPLICA:
			if _rules == null:
				_rules = LoadoutRules.standard()
			return _pictures.texture(item.key, _rules.default_tune(item).paint, false)
		Pool.Kind.POWER:
			if not PowerModels.has(item.id):
				return null
			return _pictures.power_texture(PowerModels.file(item.id), PowerModels.label(item.id), PowerModels.tip(item.id))
		Pool.Kind.PART:
			for replica in _pool.replicas:
				var t := _pictures.part_texture(replica.key, item.slot, item.key, PART_PAINT, false)
				if t != null:
					return t
	return null
