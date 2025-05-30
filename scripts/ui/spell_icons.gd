extends Node

# Icon generation settings
const ICON_SIZE = 48  # Size of the generated icons
const LINE_WIDTH = 2.0  # Width of lines in the icons

# Colors
const FIRE_COLOR = Color(1.0, 0.4, 0.2)  # Orange-red for fire
const ICE_COLOR = Color(0.4, 0.8, 1.0)   # Light blue for ice
const ICON_BG = Color(0.2, 0.2, 0.2, 0.8)  # Dark background
const ICON_BORDER = Color(0.4, 0.4, 0.4, 0.8)  # Border color

# Generate all spell icons
func generate_spell_icons() -> Dictionary:
	var icons = {}
	
	# Generate ground target spell icon
	icons["ground_target"] = generate_ground_target_icon()
	
	# Generate projectile spell icon
	icons["projectile"] = generate_projectile_icon()
	
	# Generate wall spell icon
	icons["wall"] = generate_wall_icon()
	
	return icons

# Generate ground target spell icon (circular area with target)
func generate_ground_target_icon() -> Texture2D:
	var image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(ICON_BG)
	
	# Draw border
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			if x < 2 or x > ICON_SIZE - 3 or y < 2 or y > ICON_SIZE - 3:
				image.set_pixel(x, y, ICON_BORDER)
	
	# Draw outer circle
	var center = Vector2(ICON_SIZE/2, ICON_SIZE/2)
	var radius = ICON_SIZE/3
	draw_circle(image, center, radius, FIRE_COLOR)
	
	# Draw inner circle (target)
	draw_circle(image, center, radius/2, ICE_COLOR)
	
	# Draw crosshair
	var line_length = radius/2
	draw_line(image, center - Vector2(line_length, 0), center + Vector2(line_length, 0), FIRE_COLOR)
	draw_line(image, center - Vector2(0, line_length), center + Vector2(0, line_length), FIRE_COLOR)
	
	return ImageTexture.create_from_image(image)

# Generate projectile spell icon (arrow/bolt)
func generate_projectile_icon() -> Texture2D:
	var image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(ICON_BG)
	
	# Draw border
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			if x < 2 or x > ICON_SIZE - 3 or y < 2 or y > ICON_SIZE - 3:
				image.set_pixel(x, y, ICON_BORDER)
	
	# Draw projectile (arrow)
	var start = Vector2(ICON_SIZE/4, ICON_SIZE/2)
	var end = Vector2(ICON_SIZE * 3/4, ICON_SIZE/2)
	
	# Draw main line
	draw_line(image, start, end, FIRE_COLOR)
	
	# Draw arrow head
	var arrow_size = ICON_SIZE/6
	draw_line(image, end, end - Vector2(arrow_size, arrow_size), FIRE_COLOR)
	draw_line(image, end, end - Vector2(arrow_size, -arrow_size), FIRE_COLOR)
	
	# Draw energy trail
	for i in range(3):
		var offset = Vector2(-ICON_SIZE/8 * (i + 1), 0)
		draw_line(image, start + offset, end + offset, ICE_COLOR)
	
	return ImageTexture.create_from_image(image)

# Generate wall spell icon (vertical barrier)
func generate_wall_icon() -> Texture2D:
	var image = Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(ICON_BG)
	
	# Draw border
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			if x < 2 or x > ICON_SIZE - 3 or y < 2 or y > ICON_SIZE - 3:
				image.set_pixel(x, y, ICON_BORDER)
	
	# Draw wall segments
	var wall_width = ICON_SIZE/8
	var wall_height = ICON_SIZE/4
	var start_x = ICON_SIZE/4
	
	for i in range(3):
		var pos = Vector2(start_x + i * wall_width * 2, ICON_SIZE/4)
		draw_rect_filled(image, Rect2(pos, Vector2(wall_width, wall_height)), FIRE_COLOR)
		draw_rect_filled(image, Rect2(pos + Vector2(0, wall_height + wall_width), Vector2(wall_width, wall_height)), ICE_COLOR)
	
	return ImageTexture.create_from_image(image)

# Helper function to draw a circle
func draw_circle(image: Image, center: Vector2, radius: float, color: Color):
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			var pos = Vector2(x, y)
			if pos.distance_to(center) <= radius:
				image.set_pixel(x, y, color)

# Helper function to draw a line
func draw_line(image: Image, start: Vector2, end: Vector2, color: Color):
	var points = get_line_points(start, end)
	for point in points:
		if point.x >= 0 and point.x < ICON_SIZE and point.y >= 0 and point.y < ICON_SIZE:
			image.set_pixel(point.x, point.y, color)

# Helper function to get points along a line
func get_line_points(start: Vector2, end: Vector2) -> Array:
	var points = []
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx - dy
	
	var x = start.x
	var y = start.y
	
	while true:
		points.append(Vector2(x, y))
		if x == end.x and y == end.y:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	return points

# Helper function to draw a filled rectangle
func draw_rect_filled(image: Image, rect: Rect2, color: Color):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x >= 0 and x < ICON_SIZE and y >= 0 and y < ICON_SIZE:
				image.set_pixel(x, y, color) 