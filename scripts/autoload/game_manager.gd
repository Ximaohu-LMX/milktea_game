extends Node

## 全局游戏管理器 - 管理玩家状态、金钱、背包

signal money_changed(new_amount: int)
signal inventory_changed()
signal player_state_changed(new_state: String)

# 玩家基础数据
var player_name: String = "玩家"
var money: int = 500  # 初始资金

# 玩家当前状态（同一时间只能做一件事）
enum PlayerState { IDLE, FARMING, WORKING, MANAGING_SHOP }
var current_state: PlayerState = PlayerState.IDLE

# 背包：物品ID -> {name, type, count, data}
# type: "seed" 种子, "crop" 作物原料, "product" 成品
var inventory: Dictionary = {}

# 拥有的土地 [{region_id, plot_index, crop_data}]
var owned_lands: Array = []

# ---- 金钱操作 ----
func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	print("[GameManager] 金钱 +%d, 当前: %d" % [amount, money])

func spend_money(amount: int) -> bool:
	if money < amount:
		print("[GameManager] 金钱不足! 需要 %d, 当前 %d" % [amount, money])
		return false
	money -= amount
	money_changed.emit(money)
	print("[GameManager] 金钱 -%d, 当前: %d" % [amount, money])
	return true

# ---- 背包操作 ----
func add_item(item_id: String, item_name: String, item_type: String, count: int = 1, data: Dictionary = {}) -> void:
	if inventory.has(item_id):
		inventory[item_id]["count"] += count
	else:
		inventory[item_id] = {
			"name": item_name,
			"type": item_type,
			"count": count,
			"data": data
		}
	inventory_changed.emit()
	print("[GameManager] 获得 %s x%d" % [item_name, count])

func remove_item(item_id: String, count: int = 1) -> bool:
	if not inventory.has(item_id) or inventory[item_id]["count"] < count:
		return false
	inventory[item_id]["count"] -= count
	if inventory[item_id]["count"] <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	if inventory.has(item_id):
		return inventory[item_id]["count"]
	return 0

# ---- 玩家状态 ----
func set_player_state(new_state: PlayerState) -> void:
	current_state = new_state
	var state_names = ["空闲", "务农中", "打工中", "经营店铺中"]
	player_state_changed.emit(state_names[new_state])
	print("[GameManager] 玩家状态: %s" % state_names[new_state])

func is_idle() -> bool:
	return current_state == PlayerState.IDLE

# ---- 存档 ----
func save_game() -> void:
	var save_data = {
		"player_name": player_name,
		"money": money,
		"inventory": inventory,
		"owned_lands": owned_lands,
		"current_state": current_state,
		"timestamp": Time.get_unix_time_from_system()
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("[GameManager] 游戏已保存")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	var data = json.get_data()
	player_name = data.get("player_name", "玩家")
	money = data.get("money", 500)
	inventory = data.get("inventory", {})
	owned_lands = data.get("owned_lands", [])
	current_state = data.get("current_state", PlayerState.IDLE)
	money_changed.emit(money)
	inventory_changed.emit()
	print("[GameManager] 游戏已加载")
	return true
