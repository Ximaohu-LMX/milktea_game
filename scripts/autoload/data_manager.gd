extends Node

## 数据管理器 - 作物、地形、种子的静态数据定义

# 地形类型定义
# 每个地形影响因子：温度、温差、海拔、降水、土壤类型
var regions: Dictionary = {
	"plateau": {
		"name": "高原", "plots": 5,
		"price": 200,
		"factors": {"temp": 2, "temp_diff": 3, "altitude": 5, "rain": 1, "soil": 2},
		"description": "海拔高，昼夜温差大，适合苹果和高山茶"
	},
	"plains": {
		"name": "平原", "plots": 5,
		"price": 150,
		"factors": {"temp": 3, "temp_diff": 1, "altitude": 1, "rain": 3, "soil": 4},
		"description": "土壤肥沃，降水适中，适合大多数作物"
	},
	"tropical": {
		"name": "热带", "plots": 5,
		"price": 180,
		"factors": {"temp": 5, "temp_diff": 1, "altitude": 1, "rain": 5, "soil": 3},
		"description": "高温多雨，适合热带水果和特殊茶叶"
	},
	"hills": {
		"name": "丘陵", "plots": 5,
		"price": 170,
		"factors": {"temp": 3, "temp_diff": 2, "altitude": 3, "rain": 2, "soil": 3},
		"description": "地形起伏，排水好，适合柑橘类"
	},
}

# 作物大类定义
# base_values: 初始 (甜度, 香味, 产量) 都从0开始
# preferred_region: 最适合的地形
# grow_time: 生长周期（游戏分钟）
# category: "tea" 茶叶, "fruit" 水果
var crop_types: Dictionary = {
	"apple": {
		"name": "苹果", "category": "fruit",
		"base_values": [0, 0, 0],
		"preferred_region": "plateau",
		"grow_time": 30,
		"sell_base_price": 10,
		"description": "常见水果，高原种植品质最佳"
	},
	"orange": {
		"name": "橘子", "category": "fruit",
		"base_values": [0, 0, 0],
		"preferred_region": "hills",
		"grow_time": 25,
		"sell_base_price": 8,
		"description": "柑橘类水果，丘陵地形产出多样品种"
	},
	"green_tea": {
		"name": "绿茶", "category": "tea",
		"base_values": [0, 0, 0],
		"preferred_region": "plateau",
		"grow_time": 40,
		"sell_base_price": 15,
		"description": "基础茶叶，高原产出清香型"
	},
	"mango": {
		"name": "芒果", "category": "fruit",
		"base_values": [0, 0, 0],
		"preferred_region": "tropical",
		"grow_time": 35,
		"sell_base_price": 12,
		"description": "热带水果，需要高温高湿环境"
	},
}

# 根据地形计算种子种下后的数值变化
# 返回 [甜度, 香味, 产量]
func calculate_crop_values(crop_id: String, region_id: String, seed_values: Array) -> Array:
	var crop = crop_types[crop_id]
	var region = regions[region_id]
	var factors = region["factors"]
	
	# 基础公式：种子数值 + 地形影响 + 随机波动
	var sweetness = seed_values[0] + factors["temp"] + factors["soil"] - 3
	var aroma = seed_values[1] + factors["altitude"] + factors["temp_diff"] - 2
	var yield_val = seed_values[2] + factors["rain"] + factors["soil"] - 2
	
	# 如果是适合的地形，额外加成
	if crop["preferred_region"] == region_id:
		sweetness += 2
		aroma += 1
		yield_val += 2
	
	# 小范围随机波动 (-1 到 +1)
	sweetness += randi_range(-1, 1)
	aroma += randi_range(-1, 1)
	yield_val += randi_range(-1, 1)
	
	# 限制最低为0
	return [maxi(sweetness, 0), maxi(aroma, 0), maxi(yield_val, 0)]

# 生成收获后的种子（变异系统）
# 返回一批种子，数值在亲代基础上波动
func generate_seeds_from_harvest(parent_values: Array, count: int = 3) -> Array:
	var seeds = []
	for i in count:
		var new_values = []
		for v in parent_values:
			# 亲代越好，子代下限越高（正反馈）
			var min_val = maxi(v - 2, 0)
			var max_val = v + 2
			# 小概率大幅变异
			if randf() < 0.1:
				max_val += 3
			new_values.append(randi_range(min_val, max_val))
		seeds.append(new_values)
	return seeds

# 根据作物数值计算售价
func calculate_sell_price(crop_id: String, values: Array) -> int:
	var base = crop_types[crop_id]["sell_base_price"]
	var quality_bonus = values[0] + values[1]  # 甜度+香味影响品质
	var yield_bonus = values[2]  # 产量影响数量
	return base + quality_bonus * 2 + yield_bonus
