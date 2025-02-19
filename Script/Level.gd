class_name Level
extends Node2D

signal win
signal lose

enum LevelType { NORMAL, TITLE, COMPLETE }
@export var level_type := LevelType.NORMAL

enum {TILE_WALL = 0, TILE_PLAYER = 1, TILE_GOOBER = 2}
@onready var Map: TileMapLayer = $Map

var ScenePlayer = load("res://Scene/Player.tscn")
var SceneGoober = load("res://Scene/Goober.tscn")

## This scene is used when the player or a goober is destroyed.
@export var explosion_scene := preload("res://Scene/Explosion.tscn")

var check := false

func _ready():
	MapStart()

	for player in get_tree().get_nodes_in_group("player"):
		player.died.connect(_on_died.bind(player))
		player.stomped.connect(_on_stomped)

	# When using a TileSetScenesCollectionSource to place scenes as cells of a
	# TileMapLayer, adding these to the tree gets batched together with other
	# TileMapLayer updates at the end of the frame. Monitor changes to the
	# TileMapLayer's children and connect signals to any players found there.
	Map.child_entered_tree.connect(_child_entered_tree_cb)


func _child_entered_tree_cb(node: Node):
	if node.is_in_group("player"):
		node.died.connect(_on_died.bind(node))
		node.stomped.connect(_on_stomped)


func MapStart():
	for pos in Map.get_used_cells():
		var id = Map.get_cell_source_id(pos)
		match id:
			TILE_WALL:
				# Use random wall tile from 3×3 tileset to make levels look less repetitive
				var atlas = Vector2(randi_range(0, 2), randi_range(0, 2))
				Map.set_cell(pos, TILE_WALL, atlas)
			TILE_PLAYER:
				# Add live player to the scene
				var inst = ScenePlayer.instantiate()
				inst.position = Map.map_to_local(pos) + Vector2(4, 0)
				self.add_child(inst)
				# Remove static player tile from the tile map
				Map.set_cell(pos, -1)
			TILE_GOOBER:
				# Add live goober to the scene
				var inst = SceneGoober.instantiate()
				inst.position = Map.map_to_local(pos) + Vector2(4, 0)
				self.add_child(inst)
				# Remove static goober tile from the tile map
				Map.set_cell(pos, -1)

func _process(_delta: float):
	# should i check?
	if check:
		check = false
		var count = get_tree().get_node_count_in_group("goober")
		print("Goobers: ", count)
		if count == 0:
			win.emit()

func Explode(character: Node2D):
	var xpl = explosion_scene.instantiate()
	xpl.position = character.position
	add_child(xpl)
	character.queue_free()

func _on_died(player: CharacterBody2D):
	Explode(player)
	lose.emit()

func _on_stomped(goober: CharacterBody2D):
	Explode(goober)
	check = true
