# Добавьте этот скрипт как новый файл WitchFatigue.gd
extends Node

@export var fatigue_regen_rate: float = 0.02  # Скорость восстановления в секунду
@export var max_fatigue: float = 1.0
@export var fatigue_threshold_warning: float = 0.7  # Порог для уведомления игрока
@export var enable_auto_recovery: bool = true

var is_recovering: bool = true
var recovery_multiplier: float = 1.0

func _ready():
	# Устанавливаем начальное значение усталости
	ResourceManager.set_resource("witch_fatigue", 0.0)

func _process(delta):
	if enable_auto_recovery and is_recovering:
		var current_fatigue = ResourceManager.get_resource("witch_fatigue")
		if current_fatigue > 0:
			# Уменьшаем усталость со временем
			var recovery = fatigue_regen_rate * delta * recovery_multiplier
			var new_fatigue = max(0, current_fatigue - recovery)
			# Напрямую используем set_resource, чтобы обновить значение даже при малых изменениях
			ResourceManager.set_resource("witch_fatigue", new_fatigue)
		
	# Проверяем, не достигла ли усталость критического уровня
	check_fatigue_warnings()

# Добавляет усталость с проверкой максимума
func add_fatigue(amount: float) -> void:
	var current = ResourceManager.get_resource("witch_fatigue")
	var new_value = min(current + amount, max_fatigue)
	ResourceManager.set_resource("witch_fatigue", new_value)
	
	# Останавливаем восстановление на короткий период после добавления усталости
	is_recovering = false
	await get_tree().create_timer(1.0).timeout
	is_recovering = true

# Увеличивает множитель восстановления (например, когда ведьма отдыхает)
func boost_recovery(multiplier: float, duration: float) -> void:
	var old_multiplier = recovery_multiplier
	recovery_multiplier = multiplier
	
	await get_tree().create_timer(duration).timeout
	recovery_multiplier = old_multiplier

# Проверяет уровень усталости и отображает предупреждения
func check_fatigue_warnings() -> void:
	var current = ResourceManager.get_resource("witch_fatigue")
	if current >= fatigue_threshold_warning:
		# Здесь можно добавить визуальный эффект или звук
		if current >= max_fatigue:
			# Критическая усталость - принудительный отдых или другие последствия
			pass
