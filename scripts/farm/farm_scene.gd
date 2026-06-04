extends Control

## 农场场景 - 管理一个地区的所有土地

var current_region: String = ""
var plots: Array = []

@onready var region_label: Label = $TopBar/RegionLabel
@onready var money_label: Label = $TopBar/MoneyLabel
@onready var plots_container: GridContainer = $ScrollContainer/PlotsContainer
@onready var info_panel: Panel = $InfoPanel
@onready var info_label: RichTextLabel = $InfoPanel/InfoLabel
@onready var action_button: Button = $InfoPanel/ActionButton
@onready var back_button: Button = $TopBar/BackButton

var selected_plot = null
var plot_scene = preload("res://scenes/farm/plot.tscn")

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	back_button.pressed.connect(_on_back_pressed)
	action_button.pressed.connect(_on_action_pressed)
	info_panel.visible = false
	
	_on_money_changed(GameManager.money)
	
	# 默认加载平原（后续从选择界面进入）
	if current_region == "":
		load_region("plains")

func load_region(region_id: String) -> void:
	current_region = region_id
	var region = DataManager.regions[region_id]
	region_label.text = region["name"]
	
	# 清除旧地块
	for child in plots_container.get_children():
		child.queue_free()
	plots.clear()
	
	# 创建5块地
	for i in 5:
		var plot = plot_scene.instantiate()
		plot.region_id = region_id
		plot.plot_clicked.connect(_on_plot_clicked)
		plots_container.add_child(plot)
		plots.append(plot)

func _on_plot_clicked(plot: Panel) -> void:
	selected_plot = plot
	info_panel.visible = true
	_update_info_panel()

func _update_info_panel() -> void:
	if selected_plot == null:
		return
	
	match selected_plot.state:
		selected_plot.PlotState.EMPTY:
			info_label.text = "[b]空地[/b]\n选择种子进行种植"
			action_button.text = "种植"
			action_button.visible = _has_any_seeds()
		selected_plot.PlotState.PLANTED, selected_plot.PlotState.GROWING:
			var crop_name = DataManager.crop_types[selected_plot.crop_id]["name"]
			var vals = selected_plot.crop_values
			info_label.text = "[b]%s 生长中[/b]\n甜度:%d 香味:%d 产量:%d\n进度: %d%%" % [
				crop_name, vals[0], vals[1], vals[2],
				int(selected_plot.growth_progress * 100)
			]
			action_button.text = "等待中..."
			action_button.visible = false
		selected_plot.PlotState.READY:
			var crop_name = DataManager.crop_types[selected_plot.crop_id]["name"]
			var vals = selected_plot.crop_values
			var price = DataManager.calculate_sell_price(selected_plot.crop_id, vals)
			info_label.text = "[b]%s 已成熟![/b]\n甜度:%d 香味:%d 产量:%d\n预估售价: %d金币" % [
				crop_name, vals[0], vals[1], vals[2], price
			]
			action_button.text = "收获"
			action_button.visible = true

func _on_action_pressed() -> void:
	if selected_plot == null:
		return
	
	match selected_plot.state:
		selected_plot.PlotState.EMPTY:
			_show_seed_selection()
		selected_plot.PlotState.READY:
			_harvest_plot()

func _harvest_plot() -> void:
	var result = selected_plot.harvest()
	if result.is_empty():
		return
	
	# 作物加入背包
	var crop_item_id = "%s_%d_%d_%d" % [result["crop_id"], result["values"][0], result["values"][1], result["values"][2]]
	GameManager.add_item(
		crop_item_id,
		"%s [%d,%d,%d]" % [result["crop_name"], result["values"][0], result["values"][1], result["values"][2]],
		"crop",
		result["values"][2],  # 产量决定数量
		{"crop_id": result["crop_id"], "values": result["values"]}
	)
	
	# 种子加入背包
	for i in result["seeds"].size():
		var seed_vals = result["seeds"][i]
		var seed_id = "%s_seed_%d_%d_%d" % [result["crop_id"], seed_vals[0], seed_vals[1], seed_vals[2]]
		GameManager.add_item(
			seed_id,
			"%s种子 [%d,%d,%d]" % [result["crop_name"], seed_vals[0], seed_vals[1], seed_vals[2]],
			"seed",
			1,
			{"crop_id": result["crop_id"], "values": seed_vals}
		)
	
	info_label.text = "[b]收获成功![/b]\n获得 %s x%d\n获得 %d 颗种子" % [
		result["crop_name"], result["values"][2], result["seeds"].size()
	]
	action_button.visible = false

func _show_seed_selection() -> void:
	# 简化版：自动选第一个可用种子种下
	# 后续替换为种子选择弹窗
	for item_id in GameManager.inventory:
		var item = GameManager.inventory[item_id]
		if item["type"] == "seed":
			var crop_id = item["data"]["crop_id"]
			var seed_vals = item["data"]["values"]
			GameManager.remove_item(item_id, 1)
			selected_plot.plant(crop_id, seed_vals, current_region)
			_update_info_panel()
			return
	
	info_label.text = "没有种子！\n去商店购买或者打工赚钱吧"

func _has_any_seeds() -> bool:
	for item_id in GameManager.inventory:
		if GameManager.inventory[item_id]["type"] == "seed":
			return true
	return false

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "%d 金币" % new_amount

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
