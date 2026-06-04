extends Node

## 时间管理器 - 基于现实时间的作物生长系统

signal minute_passed()
signal crop_growth_tick()

# 游戏时间倍率（1.0 = 现实时间，调试时可加快）
var time_scale: float = 60.0  # 默认60倍速，1现实秒=1游戏分钟

# 生长检查间隔（秒）
var growth_check_interval: float = 1.0
var _growth_timer: float = 0.0

# 获取当前时间戳（用于计算离线生长）
func get_current_time() -> float:
	return Time.get_unix_time_from_system()

# 计算两个时间点之间经过了多少游戏分钟
func get_elapsed_minutes(from_timestamp: float) -> float:
	var real_seconds = get_current_time() - from_timestamp
	return real_seconds * time_scale / 60.0

func _process(delta: float) -> void:
	_growth_timer += delta
	if _growth_timer >= growth_check_interval:
		_growth_timer -= growth_check_interval
		crop_growth_tick.emit()
