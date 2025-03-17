# BrewingUI.gd
extends Control

@onready var growth_button = $VBoxContainer/VBoxContainer/GrowthButton
@onready var weather_button = $VBoxContainer/VBoxContainer/WeatherButton
@onready var energy_button = $VBoxContainer/VBoxContainer/EnergyButton

@onready var brewing_animation = $BrewingAnimation
@onready var result_label = $VBoxContainer/ResultLabel
@onready var close_button = $VBoxContainer/CloseButton
# Ссылка на синглтон PotionSystem
@onready var potion_system = get_node("/root/PotionSystem")

func _ready():
	# Скрываем UI по умолчанию
	visible = false
	
	# Подключаем кнопки
	growth_button.connect("pressed", Callable(self, "_on_growth_button_pressed"))
	weather_button.connect("pressed", Callable(self, "_on_weather_button_pressed"))
	energy_button.connect("pressed", Callable(self, "_on_energy_button_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))  # Подключаем сигнал кнопки закрытия

	# Подключаем сигналы
	ResourceManager.connect("resource_changed", Callable(self, "_update_buttons"))
	if potion_system:
		potion_system.connect("potion_brewed", Callable(self, "_on_potion_brewed"))
	
	# Обновляем состояние кнопок
	_update_buttons("", 0)
	
	# Скрываем метку результата
	result_label.visible = false

func _on_growth_button_pressed():
	if potion_system:
		potion_system.brew_potion(potion_system.PotionType.GROWTH)

func _on_weather_button_pressed():
	if potion_system:
		potion_system.brew_potion(potion_system.PotionType.WEATHER)

func _on_energy_button_pressed():
	if potion_system:
		potion_system.brew_potion(potion_system.PotionType.ENERGY)

func _on_close_button_pressed():
	# Просто скрываем UI при нажатии на кнопку закрытия
	visible = false

func _on_potion_brewed(potion_type, potion_name):
	# Отображаем результат
	result_label.text = "Prepared:\n" + potion_name
	result_label.visible = true
	
	# Скрываем метку через 3 секунды
	await get_tree().create_timer(3.0).timeout
	result_label.visible = false
	
	# Проигрываем анимацию, если она есть
	if brewing_animation and brewing_animation.has_animation("brew"):
		brewing_animation.play("brew")

func _update_buttons(resource_name="", value=0):
	if potion_system:
		# Обновляем состояние кнопок в зависимости от доступности ингредиентов
		growth_button.disabled = !potion_system.can_brew_potion(potion_system.PotionType.GROWTH)
		weather_button.disabled = !potion_system.can_brew_potion(potion_system.PotionType.WEATHER)
		energy_button.disabled = !potion_system.can_brew_potion(potion_system.PotionType.ENERGY)
		
		# Обновляем текст на кнопках, показывая необходимые ингредиенты
		update_button_text(growth_button, potion_system.PotionType.GROWTH, "Elixir of Growth")
		update_button_text(weather_button, potion_system.PotionType.WEATHER, "Weather Potion")
		update_button_text(energy_button, potion_system.PotionType.ENERGY, "Restorative Tincture")

func update_button_text(button, potion_type, base_name):
	var recipe = potion_system.recipes[potion_type]
	var text = base_name + "\n"
	
	for ingredient in recipe:
		var required = recipe[ingredient]
		var available = ResourceManager.get_resource(ingredient)
		text += ingredient + ": " + str(int(available)) + "/" + str(required) + "\n"
	
	button.text = text

func show_brewing_ui():
	visible = true
	_update_buttons()

func hide_brewing_ui():
	visible = false
