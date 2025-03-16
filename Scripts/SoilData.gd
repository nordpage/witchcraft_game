# SoilData.gd
extends Resource
class_name SoilData

@export var soil_title: String = "Garden Bed"
@export var is_sown: bool = false        # Засеяна ли грядка
@export var is_fertilized: bool = false    # Удобрена ли грядка
@export var is_watered: bool = false       # Полита ли грядка
@export var plant_type: String = ""        # Тип растения (название или идентификатор)
@export var growth_stage: int = 0          # Текущая стадия роста растения
@export var moisture_level: float = 0.0    # Уровень влаги в почве

# Дополнительные параметры для управления ростом и сбором урожая:
@export var has_plant: bool = false        # Есть ли выросшее растение на грядке
@export var growth_progress: float = 0.0   # Прогресс роста растения (0.0 - не выросло, 1.0 - полностью выросло)
@export var harvest_yield: int = 0         # Количество урожая, которое можно собрать
