extends Control

## 主界面 - 游戏入口，导航到各个功能

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var state_label: Label = $TopBar/StateLabel
@onready var farm_button: Button = $MenuContainer/FarmButton
@onready var shop_button: Button = $MenuContainer/ShopButton
@onready var inventory_button: Button = $MenuContainer/InventoryButton
@onready var save_button: Button = $MenuContainer/SaveButton

func _ready() -> void:
	GameManager.money_changed.connect(func(m): money_label.text = "%d 金币" % m)
	GameManager.player_state_changed.connect(func(s): state_label.text = s)
	
	farm_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/farm/farm.tscn"))
	shop_button.pressed.connect(func(): _open_shop())
	inventory_button.pressed.connect(func(): _show_inventory())
	save_button.pressed.connect(func(): GameManager.save_game())
	
	money_label.text = "%d 金币" % GameManager.money
	state_label.text = "空闲"
	
	# 尝试加载存档
	GameManager.load_game()
	
	# 如果是新玩家，给初始种子
	if GameManager.inventory.is_empty():
		_give_starter_seeds()

func _give_starter_seeds() -> void:
	# 新玩家赠送初始种子
	GameManager.add_item("green_tea_seed_0_0_0", "绿茶种子 [0,0,0]", "seed", 3,
		{"crop_id": "green_tea", "values": [0, 0, 0]})
	GameManager.add_item("apple_seed_0_0_0", "苹果种子 [0,0,0]", "seed", 2,
		{"crop_id": "apple", "values": [0, 0, 0]})
	print("[Main] 发放新手种子包")

func _open_shop() -> void:
	# 简化版商店：直接在这里处理购买
	# 后续替换为独立商店场景
	var shop_dialog = AcceptDialog.new()
	shop_dialog.title = "大肥猪商店"
	
	var text = "欢迎来到大肥猪的商店！哼哼~\n\n"
	text += "【土地】\n"
	for region_id in DataManager.regions:
		var r = DataManager.regions[region_id]
		text += "  %s - %d金币 (%s)\n" % [r["name"], r["price"], r["description"]]
	text += "\n【种子】\n"
	for crop_id in DataManager.crop_types:
		var c = DataManager.crop_types[crop_id]
		text += "  %s种子 - %d金币\n" % [c["name"], c["sell_base_price"]]
	text += "\n(购买功能开发中...先去农场种初始种子吧！)"
	
	shop_dialog.dialog_text = text
	add_child(shop_dialog)
	shop_dialog.popup_centered(Vector2(600, 500))

func _show_inventory() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "背包"
	
	if GameManager.inventory.is_empty():
		dialog.dialog_text = "背包空空如也~"
	else:
		var text = ""
		for item_id in GameManager.inventory:
			var item = GameManager.inventory[item_id]
			var type_name = {"seed": "种子", "crop": "原料", "product": "成品"}
			text += "[%s] %s x%d\n" % [
				type_name.get(item["type"], "其他"),
				item["name"],
				item["count"]
			]
		dialog.dialog_text = text
	
	add_child(dialog)
	dialog.popup_centered(Vector2(500, 400))
