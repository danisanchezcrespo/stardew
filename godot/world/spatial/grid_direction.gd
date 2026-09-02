class_name GridDirection
extends RefCounted

enum QuarterTurn {
	NORTH = 0,
	EAST = 1,
	SOUTH = 2,
	WEST = 3,
}


static func normalize(turn: int) -> int:
	return posmod(turn, 4)


static func rotate_cell_clockwise(cell: Vector2i, turn: int) -> Vector2i:
	match normalize(turn):
		QuarterTurn.NORTH:
			return cell
		QuarterTurn.EAST:
			return Vector2i(-cell.y, cell.x)
		QuarterTurn.SOUTH:
			return Vector2i(-cell.x, -cell.y)
		QuarterTurn.WEST:
			return Vector2i(cell.y, -cell.x)
	return cell


static func name_for(turn: int) -> String:
	match normalize(turn):
		QuarterTurn.NORTH:
			return "north"
		QuarterTurn.EAST:
			return "east"
		QuarterTurn.SOUTH:
			return "south"
		QuarterTurn.WEST:
			return "west"
	return "north"
