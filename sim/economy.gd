class_name PREconomy
extends RefCounted

var money: float = PRConstants.STARTING_MONEY
var total_revenue: float = 0.0
var total_expenses: float = 0.0

func can_afford(amount: float) -> bool:
	return money >= amount

func spend(amount: float) -> bool:
	if money < amount:
		return false
	money -= amount
	total_expenses += amount
	return true

func earn(amount: float) -> void:
	money += amount
	total_revenue += amount

func is_bankrupt() -> bool:
	return money < 0.0
