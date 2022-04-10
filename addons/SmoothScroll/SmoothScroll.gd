extends Control

export(float, 10, 1) var multi = 8	# drag speed of one input
export var damping = 0.1
export var scrollbar_damping = 1.0
export var touch_support = false

var v = Vector2(0,0) 				# current velocity
var just_stop_under = 0.01
var is_grabbed = false

var over_drag_multiplicator_top = 1
var over_drag_multiplicator_bottom = 1


var scroll_grabbed = false
var cursor_offset = 0


var content_node : Control

onready var input_shape = $ScrollArea/ScrollShape

func _ready():
	input_shape.position = rect_size / 2
	input_shape.shape.set("extents", rect_size / 2)
	
	
	for c in get_children():
		if c.name.find("Scroll"):
			c.show_behind_parent = true
			c.mouse_filter = MOUSE_FILTER_IGNORE
			content_node = c

func _process(delta):
	if !content_node:
		return
	var d = delta
	var content_size = content_node.rect_size.y
	# If no scroll needed
	if content_size <= self.rect_size.y:
		$ScrollThumb.hide()
		$ScrollTrack.hide()
		content_node.rect_size.y = self.rect_size.y
	else:
		pass
		#$ScrollThumb.show()
		#$ScrollTrack.show()
		
	var bottom_pos = content_node.rect_position.y + content_size - self.rect_size.y
	var top_pos = content_node.rect_position.y
	
	# If overdragged:
	if bottom_pos < 0 :
		over_drag_multiplicator_bottom = 1/abs(bottom_pos)*10
	else:
		over_drag_multiplicator_bottom = 1
	
	if top_pos > 0:
		over_drag_multiplicator_top = 1/abs(top_pos*top_pos)*10
	else:
		over_drag_multiplicator_top = 1
	
	
	v *= 0.9
	
	if v.length() <= just_stop_under:
		v = Vector2(0,0)
	
	if not is_grabbed:
		if bottom_pos < 0 :
			v.y = lerp(v.y, -bottom_pos/8, damping)
		if top_pos > 0:
			v.y = lerp(v.y, -top_pos/8, damping)
	else:
		if bottom_pos < -20 || top_pos > 20:
			v.y = v.y / 2

	# Move content node
	if !scroll_grabbed:
		content_node.rect_position += v
		# Calculate scrollbar
		if   top_pos > 0:
			$ScrollThumb.rect_scale.y = (1 / content_size * 1000)  /  (top_pos/1000 + 1)
			$ScrollThumb.rect_pivot_offset.y = 0
			shift_thumb(false)
		elif bottom_pos < 0:
			$ScrollThumb.rect_scale.y = -(1 / content_size * 1000)  /  (bottom_pos/1000 + 1)
			shift_thumb(true)
		else:
			shift_thumb(false)
			$ScrollThumb.rect_pivot_offset.y = 0
			$ScrollThumb.rect_scale.y = 1 / content_size * 1000
			if (content_size - self.rect_size.y) != 0:
				$ScrollThumb.rect_position.y = - (content_node.rect_position.y / (content_size - self.rect_size.y)) * 2500
	else:
		$ScrollThumb.rect_global_position.y = get_global_mouse_position().y - cursor_offset
		content_node.rect_position.y = lerp(content_node.rect_position.y, - ($ScrollThumb.rect_position.y / (content_size - self.rect_size.y)) * 1900, scrollbar_damping)

var did_shift = false

func shift_thumb(do_shift):
	if do_shift && !did_shift:
		$ScrollThumb.rect_position.y += $ScrollThumb.rect_size.y
		did_shift = true
	if !do_shift:
		did_shift = false

var last_mouse_pos = Vector2.ZERO

func _on_ScrollThumb_gui_input(event):
	if event is InputEventMouseButton:
		if !event.pressed:
			scroll_grabbed = false
			return
		
		if !scroll_grabbed:
			scroll_grabbed = true
			cursor_offset = get_global_mouse_position().y - $ScrollThumb.rect_global_position.y


func _on_Area2D_input_event(viewport, event, shape_idx):
	var mouse_pos = get_viewport().get_mouse_position()

	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:  is_grabbed = event.pressed

	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_DOWN:  v.y -= multi
			BUTTON_WHEEL_UP:    v.y += multi
			BUTTON_WHEEL_RIGHT: v.x -= multi
			BUTTON_WHEEL_LEFT:  v.x += multi
	
	if !touch_support:
		return
	if event is InputEventScreenDrag && is_grabbed:
		v.y = (last_mouse_pos.direction_to(mouse_pos)).y * multi
	last_mouse_pos = mouse_pos
