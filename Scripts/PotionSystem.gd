# PotionSystem.gd
extends Node

signal potion_brewed(potion_type, potion_name)

enum PotionType {
	GROWTH,     # Ускоряет рост растений
	WEATHER,    # Изменяет погоду
	ENERGY      # Восстанавливает энергию ведьмы
}

# Рецепты зелий
var recipes = {
	PotionType.GROWTH: {"plants": 2},
	PotionType.WEATHER: {"plants": 1, "firewood": 1},
	PotionType.ENERGY: {"plants": 1, "seeds": 1}
}

# Названия зелий
var potion_names = {
	PotionType.GROWTH: "Elixir of Growth",
	PotionType.WEATHER: "Weather Potion",
	PotionType.ENERGY: "Restorative Tincture"
}

# Проверяет доступность зелья
func can_brew_potion(potion_type: int) -> bool:
	if !recipes.has(potion_type):
		return false
		
	var recipe = recipes[potion_type]
	for ingredient in recipe:
		if ResourceManager.get_resource(ingredient) < recipe[ingredient]:
			return false
	return true

# Создает зелье
func brew_potion(potion_type: int) -> bool:
	if !can_brew_potion(potion_type):
		return false
		
	var recipe = recipes[potion_type]
	for ingredient in recipe:
		ResourceManager.remove_resource(ingredient, recipe[ingredient])
		
	ResourceManager.add_resource("potion_" + str(potion_type), 1)
	emit_signal("potion_brewed", potion_type, potion_names[potion_type])
	return true

# Использует зелье
func use_potion(potion_type: int) -> bool:
	if ResourceManager.get_resource("potion_" + str(potion_type)) <= 0:
		return false
		
	ResourceManager.remove_resource("potion_" + str(potion_type), 1)
	
	match potion_type:
		PotionType.GROWTH:
			apply_growth_effect()
		PotionType.WEATHER:
			apply_weather_effect()
		PotionType.ENERGY:
			apply_energy_effect()
	
	return true

func apply_growth_effect():
	# Ускоряет рост всех растений на грядках
	for soil in get_tree().get_nodes_in_group("soil"):
		if soil.soil_parameters.is_sown and !soil.soil_parameters.has_plant:
			soil.grow_plant()

func apply_weather_effect():
	# Меняет погоду на случайную
	var weather_controller = get_node_or_null("/root/WeatherController") 
	if weather_controller:
		var new_weather = randi() % weather_controller.WeatherType.size()
		weather_controller.set_weather(new_weather)

func apply_energy_effect():
	# Восстанавливает энергию ведьмы
	WitchFatigue.reset_fatigue()
