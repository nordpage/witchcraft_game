extends InteractiveObject

func _ready():
	super._ready()  # Важно вызвать метод родителя
	default_hint_text = "Проверить"

func interact():
	print("🌿 Посадка выполнена!")
	# Ваша дополнительная логика
