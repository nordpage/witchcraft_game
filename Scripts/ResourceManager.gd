extends Node

signal resource_changed(resource_name: String, new_value: int)

# Здесь можно разделить ресурсы по категориям, либо хранить все в одном словаре.
# Пример: "materials" – сырье, "items" – собранные или созданные предметы, "stats" – состояние игры.
var resources = {
	# Материалы
	"firewood": 10,    # Дрова
	"seeds": 50,      # Зерно
	"plants": 2,       # Растения (например, выращенные на огороде)

	# Предметы
	"potions": 2,      # Зелья
	"money": 100,      # Деньги

	# Параметры состояния
	"witch_fatigue": 0.0,  # Усталость ведьмы (0.0 – полностью отдохнувшая, 1.0 – максимально усталая)
	"day": 1,              # Текущий номер дня
	"time_of_day": 0.0     # Время суток (можно использовать значение от 0.0 до 1.0, где 0.0 – рассвет, 0.5 – полдень, 1.0 – закат/ночь)
}

# Функция для добавления ресурсов. Используем float для универсальности.
func add_resource(resource_name: String, amount: float) -> void:
	if resources.has(resource_name):
		resources[resource_name] += amount
	else:
		resources[resource_name] = amount
	emit_signal("resource_changed", resource_name, resources[resource_name])
	print(resource_name, "added:", amount, "Total:", resources[resource_name])

# Функция для расхода ресурсов. Возвращает true, если операция прошла успешно.
func remove_resource(resource_name: String, amount: float) -> bool:
	if resources.has(resource_name) and resources[resource_name] >= amount:
		resources[resource_name] -= amount
		emit_signal("resource_changed", resource_name, resources[resource_name])
		#print(resource_name, "removed:", amount, "Total:", resources[resource_name])
		return true
	return false

# Функция для получения текущего значения ресурса.
func get_resource(resource_name: String) -> float:
	return resources.get(resource_name, 0.0)

# Функция для установки ресурса (например, для синхронизации состояния)
func set_resource(resource_name: String, new_value: float) -> void:
	resources[resource_name] = new_value
	emit_signal("resource_changed", resource_name, new_value)
