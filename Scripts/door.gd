extends InteractiveObject

func _ready():
	super._ready()  # Важно вызвать метод родителя
	default_hint_text = "Открыть"

func interact():
	print("Дверь открыта!")
	# Ваша дополнительная логика
