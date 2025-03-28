class_name SoilData
extends Resource

@export var soil_title: String = "Garden Bed"    # Название грядки
@export var is_sown: bool = false                # Засеяна ли грядка
@export var is_fertilized: bool = false          # Удобрена ли грядка
@export var is_watered: bool = false             # Полита ли грядка
@export var current_plant: String = ""           # Идентификатор посаженного растения
@export var has_plant: bool = false              # Есть ли выросшее растение на грядке

# Стадии роста
@export var growth_stage: int = 0                # Текущая стадия роста (0-3)
@export var growth_progress: float = 0.0         # Прогресс роста (0.0-1.0)
@export var time_planted: float = 0.0            # Время посадки (для расчета длительности роста)

# Дополнительные свойства почвы
@export var fertility: float = 1.0               # Плодородность (множитель скорости роста)
@export var moisture_level: float = 0.0          # Уровень влажности
@export var harvest_yield: int = 1               # Базовое количество урожая

# Информация о последнем урожае
@export var last_harvest_time: float = 0.0       # Время последнего сбора
@export var times_harvested: int = 0             # Сколько раз собран урожай с этой грядки

# Метод для сохранения/загрузки
func serialize() -> Dictionary:
	return {
		"soil_title": soil_title,
		"is_sown": is_sown,
		"is_fertilized": is_fertilized,
		"is_watered": is_watered,
		"current_plant": current_plant,
		"has_plant": has_plant,
		"growth_stage": growth_stage,
		"growth_progress": growth_progress,
		"fertility": fertility,
		"times_harvested": times_harvested
	}

func deserialize(data: Dictionary) -> void:
	if "soil_title" in data:
		soil_title = data.soil_title
	if "is_sown" in data:
		is_sown = data.is_sown
	if "is_fertilized" in data:
		is_fertilized = data.is_fertilized
	if "is_watered" in data:
		is_watered = data.is_watered
	if "current_plant" in data:
		current_plant = data.current_plant
	if "has_plant" in data:
		has_plant = data.has_plant
	if "growth_stage" in data:
		growth_stage = data.growth_stage
	if "growth_progress" in data:
		growth_progress = data.growth_progress
	if "fertility" in data:
		fertility = data.fertility
	if "times_harvested" in data:
		times_harvested = data.times_harvested
