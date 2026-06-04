extends Panel

## 单块土地 - 种植、生长、收获逻辑

signal plot_clicked(plot: Panel)

# 土地状态
enum PlotState { EMPTY, PLANTED, GROWING, READY }
var state: PlotState = PlotState.EMPTY

# 当前种植的作物
var crop_id: String = ""
var seed_values: Array = [0, 0, 0]  # 种子的初始数值
var crop_values: Array = [0, 0, 0]  # 生长后的作物数值
var region_id: String = ""

# 生长进度
var plant_timestamp: float = 0.0
var grow_time: float = 0.0  # 需要多少游戏分钟
var growth_progress: float = 0.0  # 0.0 ~ 1.0

@onready var status_label: Label = $StatusLabel
@onready var crop_label: Label = $CropLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	TimeManager.crop_growth_tick.connect(_on_growth_tick)
	update_display()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		plot_clicked.emit(self)

# 种下作物
func plant(p_crop_id: String, p_seed_values: Array, p_region_id: String) -> void:
	crop_id = p_crop_id
	seed_values = p_seed_values
	region_id = p_region_id
	
	var crop_data = DataManager.crop_types[crop_id]
	grow_time = crop_data["grow_time"]
	plant_timestamp = TimeManager.get_current_time()
	
	# 种下时根据地形计算作物数值
	crop_values = DataManager.calculate_crop_values(crop_id, region_id, seed_values)
	
	state = PlotState.PLANTED
	growth_progress = 0.0
	update_display()
	print("[Plot] 种下 %s, 预计数值: %s" % [crop_data["name"], str(crop_values)])

# 生长检查
func _on_growth_tick() -> void:
	if state != PlotState.PLANTED and state != PlotState.GROWING:
		return
	
	var elapsed = TimeManager.get_elapsed_minutes(plant_timestamp)
	growth_progress = clampf(elapsed / grow_time, 0.0, 1.0)
	
	if growth_progress >= 1.0:
		state = PlotState.READY
	else:
		state = PlotState.GROWING
	
	update_display()

# 收获
func harvest() -> Dictionary:
	if state != PlotState.READY:
		return {}
	
	var crop_data = DataManager.crop_types[crop_id]
	var result = {
		"crop_id": crop_id,
		"crop_name": crop_data["name"],
		"values": crop_values.duplicate(),
		"seeds": DataManager.generate_seeds_from_harvest(crop_values),
		"sell_price": DataManager.calculate_sell_price(crop_id, crop_values)
	}
	
	# 重置土地
	state = PlotState.EMPTY
	crop_id = ""
	seed_values = [0, 0, 0]
	crop_values = [0, 0, 0]
	growth_progress = 0.0
	update_display()
	
	return result

func update_display() -> void:
	if not is_node_ready():
		return
	
	match state:
		PlotState.EMPTY:
			status_label.text = "空地"
			crop_label.text = "点击种植"
			progress_bar.value = 0
			self_modulate = Color(0.6, 0.5, 0.3)  # 土色
		PlotState.PLANTED, PlotState.GROWING:
			var crop_name = DataManager.crop_types[crop_id]["name"]
			status_label.text = crop_name
			crop_label.text = "生长中 %d%%" % int(growth_progress * 100)
			progress_bar.value = growth_progress * 100
			self_modulate = Color(0.5, 0.7, 0.3)  # 绿色
		PlotState.READY:
			var crop_name = DataManager.crop_types[crop_id]["name"]
			status_label.text = crop_name
			crop_label.text = "可收获!"
			progress_bar.value = 100
			self_modulate = Color(0.9, 0.8, 0.2)  # 金色
