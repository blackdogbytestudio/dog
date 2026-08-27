@tool
class_name DogBody2D
extends DogComponent

func host() -> CharacterBody2D:
	return super.host() as CharacterBody2D
