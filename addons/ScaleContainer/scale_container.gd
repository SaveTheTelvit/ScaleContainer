tool
extends Container
class_name ScaleContainer

signal drag_started
signal drag_ended

enum ContentScale {
	ON_SMALL_SIDE,
	ON_BIG_SIDE,
	NULL
}

const MASK: Dictionary = {
	BUTTON_LEFT: BUTTON_MASK_LEFT,
	BUTTON_RIGHT: BUTTON_MASK_RIGHT,
	BUTTON_MIDDLE: BUTTON_MASK_MIDDLE
}

var scroll: Vector2 = Vector2.ZERO
var min_scroll_zone: Vector2 = Vector2.ZERO
var max_scroll_zone: Vector2 = Vector2.ZERO
var content_scale: float = 1.0
var min_scale: float = 0.1
var max_scale: float = 100
var scale_on_content: int = ContentScale.NULL
var scroll_mouse_button: int = 0b111
var one_finger_scrolling: bool = true
var no_drag_on_three: bool = true
var drag_alpha: float = 0.9
var hard_bounds: bool = false
var returning_time: float = 0.2
var mouse_await_time: float = 0.2
var touch_await_time: float = 0.0

var touches: Dictionary = {}
var dragging: bool = false
var pressed: int = 0
var world_anchor: Vector2 = Vector2.INF
var start_dist: float = 0.0
var base_scale: float = 0.0
var mouse_exited_flag: bool = false
var tween = null
var current_key_pressed: int = -1
var last_scale_target: Vector2 = Vector2.ZERO
var return_from_scale: float = 1.0
var return_to_scale: float = 1.0
var return_from_scroll: Vector2 = Vector2.ZERO
var return_to_scroll: Vector2 = Vector2.ZERO

func _get_property_list() -> Array:
	return [
		{"name": "Scroll/scroll", "type": TYPE_VECTOR2, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Scroll/min_scroll_zone", "type": TYPE_VECTOR2, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Scroll/max_scroll_zone", "type": TYPE_VECTOR2, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Scale/scale", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.01,1000,0.01"},
		{"name": "Scale/min_scale", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.01,1000,0.01"},
		{"name": "Scale/max_scale", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.01,1000,0.01"},
		{"name": "Scale/scale_on_content", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_ENUM, "hint_string": "On Small Side,On Big Side, Null"},
		{"name": "Controls/scroll_mouse_button", "type": TYPE_INT, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_FLAGS, "hint_string": "Mouse Left,Mouse Right,Mouse Middle"},
		{"name": "Controls/one_finger_scrolling", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Controls/no_drag_on_three", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Controls/drag_alpha", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,1,0.01"},
		{"name": "Bound/hard_bounds", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_NONE, "hint_string": ""},
		{"name": "Bound/returning_time", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,10,0.01"},
		{"name": "Bound/mouse_await_time", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,10,0.01"},
		{"name": "Bound/touch_await_time", "type": TYPE_REAL, "usage": PROPERTY_USAGE_DEFAULT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,10,0.01"}
	]

func _get(property: String):
	match property:
		"Scroll/scroll": return scroll
		"Scroll/min_scroll_zone": return min_scroll_zone
		"Scroll/max_scroll_zone": return max_scroll_zone
		"Scale/scale": return content_scale
		"Scale/min_scale": return min_scale
		"Scale/max_scale": return max_scale
		"Scale/scale_on_content": return scale_on_content
		"Controls/scroll_mouse_button": return scroll_mouse_button
		"Controls/one_finger_scrolling": return one_finger_scrolling
		"Controls/no_drag_on_three": return no_drag_on_three
		"Controls/drag_alpha": return drag_alpha
		"Bound/hard_bounds": return hard_bounds
		"Bound/returning_time": return returning_time
		"Bound/mouse_await_time": return mouse_await_time
		"Bound/touch_await_time": return touch_await_time
	return null

func _set(property: String, value) -> bool:
	match property:
		"Scroll/scroll": scroll = value
		"Scroll/min_scroll_zone": min_scroll_zone = value
		"Scroll/max_scroll_zone": max_scroll_zone = value
		"Scale/scale": content_scale = value
		"Scale/min_scale": min_scale = value
		"Scale/max_scale": max_scale = value
		"Scale/scale_on_content": scale_on_content = value
		"Controls/scroll_mouse_button": scroll_mouse_button = value
		"Controls/one_finger_scrolling": one_finger_scrolling = value
		"Controls/no_drag_on_three": no_drag_on_three = value
		"Controls/drag_alpha": drag_alpha = value
		"Bound/hard_bounds": hard_bounds = value
		"Bound/returning_time": returning_time = value
		"Bound/mouse_await_time": mouse_await_time = value
		"Bound/touch_await_time": touch_await_time = value
		_: return false
	return true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			rect_clip_content = true
			update_scroll_on_real()
			force_standard()
		NOTIFICATION_SORT_CHILDREN:
			if world_anchor != Vector2.INF: return
			if hard_bounds: force_standard()
			else: to_standard(0)
		NOTIFICATION_WM_MOUSE_ENTER: mouse_exited_flag = false
		NOTIFICATION_WM_MOUSE_EXIT: mouse_exited_flag = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		BUTTON_WHEEL_UP:
			zoom_at(event.position, content_scale * 1.1)
			last_scale_target = event.position
			if !hard_bounds: to_standard(mouse_await_time)
		BUTTON_WHEEL_DOWN:
			zoom_at(event.position, content_scale / 1.1)
			last_scale_target = event.position
			if !hard_bounds: to_standard(mouse_await_time)
	if !has_button(scroll_mouse_button, event.button_index): return
	if event.pressed:
		if !pressed: world_anchor = screen_to_world(event.position)
		set_pressed(event.button_index, true)
		if !hard_bounds: returning_stop()
	else:
		set_pressed(event.button_index, false)
		if !pressed: world_anchor = Vector2.INF
		_end_drag()
		if !hard_bounds: to_standard(mouse_await_time)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if world_anchor == Vector2.INF: return
	last_scale_target = event.position
	if !dragging && (event.position - world_to_screen(world_anchor)).length() > 2.5: _begin_drag()
	pan_to(world_anchor, event.position)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key(event)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		if !touches.has(event.index): return
		on_screen_drag(event.index, get_new_position_on_index(event.index, event.position))

func _handle_key(event: InputEventKey) -> void:
	if event.pressed:
		var point: Vector2 = get_local_mouse_position()
		if !has_mouse_point(point): return
		match event.scancode:
			KEY_MINUS: _key_zoom(event, point, content_scale / 1.1)
			KEY_EQUAL: _key_zoom(event, point, content_scale * 1.1)
			_:
				if event.echo: return
				if !hard_bounds && world_anchor == Vector2.INF: to_standard(mouse_await_time)
				current_key_pressed = -1
	else:
		match event.scancode:
			KEY_MINUS, KEY_EQUAL: _key_zoom_release(event)

func _key_zoom(event: InputEventKey, point: Vector2, new_scale: float) -> void:
	if event.echo:
		if current_key_pressed != event.scancode: return
	else:
		current_key_pressed = event.scancode
	if !hard_bounds: returning_stop()
	if pressed && world_anchor != Vector2.INF: set_scale_keep(world_anchor, point, new_scale)
	else: zoom_at(point, new_scale)
	last_scale_target = point

func _key_zoom_release(event: InputEventKey) -> void:
	if current_key_pressed != event.scancode: return
	if !hard_bounds && world_anchor == Vector2.INF: to_standard(mouse_await_time)
	current_key_pressed = -1

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var point: Vector2 = to_local(event.position)
	if event.pressed:
		if !has_mouse_point(point, true): return
	elif !touches.has(event.index):
		return
	on_screen_touch(event.index, event.pressed, point)

func on_screen_touch(index: int, is_pressed: bool, position: Vector2) -> void:
	if is_pressed:
		touches[index] = position
		if !hard_bounds: returning_stop()
		match touches.size():
			1:
				dragging = false
				world_anchor = screen_to_world(position)
			_: start_scale_touch()
	else:
		touches.erase(index)
		match touches.size():
			0:
				emit_signal("drag_ended")
				world_anchor = Vector2.INF
				if !hard_bounds: to_standard(touch_await_time)
			1: world_anchor = screen_to_world(get_touch(0))
			_: start_scale_touch()

func on_screen_drag(index: int, position: Vector2) -> void:
	touches[index] = position
	match touches.size():
		1:
			if !one_finger_scrolling: return
			if !dragging && (position - world_to_screen(world_anchor)).length() > 2.5: _begin_drag()
			pan_to(world_anchor, position)
		2: scale_process()
		_:
			if !no_drag_on_three: scale_process()

func start_scale_touch() -> void:
	var t1: Vector2 = get_touch(0)
	var t2: Vector2 = get_touch(1)
	var center: Vector2 = (t1 + t2) * 0.5
	world_anchor = screen_to_world(center)
	start_dist = t1.distance_to(t2)
	base_scale = content_scale

func scale_process() -> void:
	if start_dist == 0: return
	var t1: Vector2 = get_touch(0)
	var t2: Vector2 = get_touch(1)
	var center: Vector2 = (t1 + t2) * 0.5
	var factor: float = t1.distance_to(t2) / start_dist
	last_scale_target = center
	set_scale_keep(world_anchor, center, base_scale * factor)

func _begin_drag() -> void:
	dragging = true
	emit_signal("drag_started")

func _end_drag() -> void:
	if !dragging: return
	dragging = false
	emit_signal("drag_ended")

func set_scale_keep(world: Vector2, pivot: Vector2, new_scale: float) -> void:
	if hard_bounds: new_scale = minmax_scale(new_scale)
	var new_scroll: Vector2 = world * new_scale - pivot + align_offset(new_scale)
	if hard_bounds: new_scroll = minmax_scroll(new_scroll, new_scale)
	set_view(new_scale, new_scroll)

func zoom_at(pivot: Vector2, new_scale: float) -> void:
	set_scale_keep(screen_to_world(pivot), pivot, new_scale)

func pan_to(world: Vector2, pivot: Vector2) -> void:
	set_scale_keep(world, pivot, content_scale)

func set_view(new_scale: float, new_scroll: Vector2) -> void:
	var c: Control = get_container()
	if !c: return
	c.rect_position = -new_scroll + align_offset(new_scale)
	c.rect_scale = Vector2(new_scale, new_scale)
	content_scale = new_scale
	scroll = new_scroll

func align_offset(scale_value: float) -> Vector2:
	var c: Control = get_container()
	if !c: return Vector2.ZERO
	return Vector2(
		_align_axis(c.size_flags_horizontal, rect_size.x, c.rect_size.x * scale_value),
		_align_axis(c.size_flags_vertical, rect_size.y, c.rect_size.y * scale_value)
	)

func _align_axis(flag: int, avail: float, content: float) -> float:
	if flag & SIZE_SHRINK_END: return max(avail - content, 0.0)
	if flag & SIZE_SHRINK_CENTER: return max((avail - content) * 0.5, 0.0)
	return 0.0

func standard_scroll(new_scale: float, pivot: Vector2) -> Vector2:
	new_scale = minmax_scale(new_scale)
	var world: Vector2 = screen_to_world(pivot)
	var s: Vector2 = world * new_scale - pivot + align_offset(new_scale)
	return minmax_scroll(s, new_scale)

func to_standard(await_time: float) -> void:
	if hard_bounds: return
	returning_stop()
	return_from_scale = content_scale
	return_to_scale = minmax_scale(content_scale)
	return_from_scroll = scroll
	return_to_scroll = standard_scroll(return_to_scale, last_scale_target)
	tween = create_tween()
	tween.tween_interval(await_time)
	tween.chain().tween_method(self, "_return_step", 0.0, 1.0, returning_time)

func _return_step(t: float) -> void:
	set_view(lerp(return_from_scale, return_to_scale, t), return_from_scroll.linear_interpolate(return_to_scroll, t))

func force_standard() -> void:
	var s: float = minmax_scale(content_scale)
	set_view(s, standard_scroll(s, last_scale_target))

func returning_stop() -> void:
	if tween && tween.is_valid() && tween.is_running(): tween.kill()

func update_scroll_on_real() -> void:
	var c: Control = get_container()
	if !c: return
	scroll = -c.rect_position + align_offset(content_scale)

func screen_to_world(pos: Vector2) -> Vector2:
	return (pos + scroll - align_offset(content_scale)) / content_scale

func world_to_screen(pos: Vector2) -> Vector2:
	return pos * content_scale - scroll + align_offset(content_scale)

func get_container() -> Control:
	if get_child_count() == 0: return null
	var child = get_child(0)
	return child if child is Control else null

func minmax_scroll(value: Vector2, scale_value: float) -> Vector2:
	var c: Control = get_container()
	var cs: Vector2 = c.rect_size if c else Vector2.ZERO
	var max_v: Vector2 = (cs + max_scroll_zone) * scale_value - rect_size
	var min_v: Vector2 = min_scroll_zone * scale_value
	max_v = Vector2(max(max_v.x, min_v.x), max(max_v.y, min_v.y))
	return clamp_v2(value, min_v, max_v)

func minmax_scale(value: float) -> float:
	if scale_on_content == ContentScale.NULL: return clamp(value, min_scale, max_scale)
	var c: Control = get_container()
	if !c: return 1.0
	var cs: Vector2 = c.rect_size
	if cs.x == 0: cs.x = rect_size.x
	if cs.y == 0: cs.y = rect_size.y
	var ratio: Vector2 = rect_size / cs
	var new_min: float = min(ratio.x, ratio.y) if scale_on_content == ContentScale.ON_BIG_SIDE else max(ratio.x, ratio.y)
	return clamp(value, max(new_min, min_scale), max_scale)

func clamp_v2(value: Vector2, minv: Vector2, maxv: Vector2) -> Vector2:
	return Vector2(clamp(value.x, minv.x, maxv.x), clamp(value.y, minv.y, maxv.y))

func has_button(value: int, button_index: int) -> bool:
	if !MASK.has(button_index): return false
	return value & MASK[button_index] != 0

func set_pressed(button_index: int, value: bool) -> void:
	if !MASK.has(button_index): return
	if value: pressed |= MASK[button_index]
	else: pressed &= ~MASK[button_index]

func get_new_position_on_index(index: int, raw_position: Vector2) -> Vector2:
	if !touches.has(index): return to_local(raw_position)
	var last_position: Vector2 = to_global(touches[index])
	var smoothed: Vector2 = drag_alpha * raw_position + (1.0 - drag_alpha) * last_position
	if (smoothed - last_position).length() < 2.5: return touches[index]
	return to_local(smoothed)

func get_touch(index: int) -> Vector2:
	return touches[touches.keys()[index]]

func to_local(global_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * global_point

func to_global(local_point: Vector2) -> Vector2:
	return get_global_transform() * local_point

func has_mouse_point(point: Vector2, skip_flag: bool = false) -> bool:
	if !skip_flag && mouse_exited_flag: return false
	return Rect2(Vector2.ZERO, rect_size).has_point(point)
