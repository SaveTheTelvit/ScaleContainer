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
	BUTTON_LEFT : BUTTON_MASK_LEFT,
	BUTTON_RIGHT : BUTTON_MASK_RIGHT,
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
var offset: Vector2 = Vector2.ZERO
var tween: SceneTreeTween = null
var current_key_pressed: int = -1
var last_scale_target: Vector2 = Vector2.ZERO

func _get_property_list() -> Array:
	return [
		{
			"name": "Scroll/scroll",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Scroll/min_scroll_zone",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Scroll/max_scroll_zone",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Scale/scale",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,1000,0.01"
		},
		{
			"name": "Scale/min_scale",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,1000,0.01"
		},
		{
			"name": "Scale/max_scale",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,1000,0.01"
		},
		{
			"name": "Scale/scale_on_content",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "On Small Side,On Big Side, Null"
		},
		{
			"name": "Controls/scroll_mouse_button",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string": "Mouse Left,Mouse Right,Mouse Middle"
		},
		{
			"name": "Controls/one_finger_scrolling",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Controls/no_drag_on_three",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Controls/drag_alpha",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,0.01"
		},
		{
			"name": "Bound/hard_bounds",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ""
		},
		{
			"name": "Bound/returning_time",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,10,0.01"
		},
		{
			"name": "Bound/mouse_await_time",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,10,0.01"
		},
		{
			"name": "Bound/touch_await_time",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,10,0.01"
		}
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
		"Scroll/scroll":
			scroll = value
			return true
		"Scroll/min_scroll_zone":
			min_scroll_zone = value
			return true
		"Scroll/max_scroll_zone":
			max_scroll_zone = value
			return true
		"Scale/scale":
			content_scale = value
			return true
		"Scale/min_scale":
			min_scale = value
			return true
		"Scale/max_scale":
			max_scale = value
			return true
		"Scale/scale_on_content":
			scale_on_content = value
			return true
		"Controls/scroll_mouse_button":
			scroll_mouse_button = value
			return true
		"Controls/one_finger_scrolling":
			one_finger_scrolling = value
			return true
		"Controls/no_drag_on_three":
			no_drag_on_three = value
			return true
		"Controls/drag_alpha":
			drag_alpha = value
			return true
		"Bound/hard_bounds":
			hard_bounds = value
			return true
		"Bound/returning_time":
			returning_time = value
			return true
		"Bound/mouse_await_time":
			mouse_await_time = value
			return true
		"Bound/touch_await_time":
			touch_await_time = value
			return true
	return false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY: 
			rect_clip_content = true
			offset = get_container_offset(content_scale)
			update_scroll_on_real()
			force_standard()
		NOTIFICATION_SORT_CHILDREN: 
			if world_anchor == Vector2.INF: 
				if hard_bounds: force_standard()
				else: to_standard(0)
		NOTIFICATION_WM_MOUSE_ENTER: mouse_exited_flag = false
		NOTIFICATION_WM_MOUSE_EXIT: mouse_exited_flag = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP: 
				update_container(content_scale * 1.1, event.position)
				last_scale_target = event.position
				if !hard_bounds: to_standard(mouse_await_time)
			BUTTON_WHEEL_DOWN: 
				update_container(content_scale / 1.1, event.position)
				last_scale_target = event.position
				if !hard_bounds: to_standard(mouse_await_time)
		if !has_button(scroll_mouse_button, event.button_index): return
		if event.pressed: 
			if !pressed: world_anchor = screen_to_world(event.position - offset)
			set_pressed(event.button_index, true)
			if !hard_bounds: returning_stop()
		else:
			set_pressed(event.button_index, false)
			if !pressed: world_anchor = Vector2.INF
			if dragging:
				dragging = false
				emit_signal("drag_ended")
			if !hard_bounds: to_standard(mouse_await_time)
	elif event is InputEventMouseMotion:
		if world_anchor == Vector2.INF: return
		var new_scroll: Vector2 = world_anchor * content_scale - event.position + offset
		last_scale_target = event.position
		if hard_bounds: new_scroll = minmax_scroll(new_scroll, content_scale)
		if !dragging && (new_scroll - scroll).length() > 2.5:
			dragging = true
			emit_signal("drag_started")
		set_view(content_scale, new_scroll)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed: 
			var point: Vector2 = get_local_mouse_position()
			if !has_mouse_point(point): return
			match event.scancode:
				KEY_MINUS:
					if event.echo: 
						if current_key_pressed != event.scancode: return
					else: current_key_pressed = event.scancode
					if !hard_bounds: returning_stop()
					if pressed && world_anchor != Vector2.INF:
						set_scale_wtch_anchor(content_scale / 1.1, point)
					else: update_container(content_scale / 1.1, point)
					last_scale_target = point
				KEY_EQUAL: 
					if event.echo: 
						if current_key_pressed != event.scancode: return
					else: current_key_pressed = event.scancode
					if !hard_bounds: returning_stop()
					if pressed && world_anchor != Vector2.INF:
						set_scale_wtch_anchor(content_scale * 1.1, point)
					else: update_container(content_scale * 1.1, point)
					last_scale_target = point
				_:
					if !event.echo:
						if !hard_bounds && world_anchor == Vector2.INF: to_standard(mouse_await_time)
						current_key_pressed = -1
		else:
			match event.scancode:
				KEY_MINUS, KEY_EQUAL: 
					if current_key_pressed == event.scancode: 
						if !hard_bounds && world_anchor == Vector2.INF: to_standard(mouse_await_time)
						current_key_pressed = -1
	elif event is InputEventScreenTouch:
		var point: Vector2 = to_local(event.position)
		if event.pressed: 
			if !has_mouse_point(point, true): return
		else: 
			if !touches.has(event.index): return
		on_screen_touch(event.index, event.pressed, point)
	elif event is InputEventScreenDrag:
		if !touches.has(event.index): return
		on_screen_drag(event.index, get_new_position_on_index(event.index, event.position))

func on_screen_touch(index: int, is_pressed: bool, position: Vector2) -> void:
	if is_pressed: 
		touches[index] = position
		if !hard_bounds: returning_stop()
		match touches.size():
			1: 
				dragging = false
				world_anchor = screen_to_world(position - offset)
			_:
				start_scale_touch()
	else: 
		touches.erase(index)
		match touches.size():
			0:
				emit_signal("drag_ended")
				world_anchor = Vector2.INF
				if !hard_bounds: to_standard(touch_await_time)
			1:
				world_anchor = screen_to_world(get_touch(0) - offset)
			_: 
				start_scale_touch()

func on_screen_drag(index: int, position: Vector2) -> void:
	touches[index] = position
	match touches.size():
		1:
			if !one_finger_scrolling: return
			var new_scroll: Vector2 = world_anchor * content_scale - position + offset
			if hard_bounds: new_scroll = minmax_scroll(new_scroll, content_scale)
			if !dragging && (new_scroll - scroll).length() > 2.5:
				dragging = true
				emit_signal("drag_started")
			set_view(content_scale, new_scroll)
		2:
			scale_process()
		_:
			if !no_drag_on_three: scale_process()

func start_scale_touch() -> void:
	var t1: Vector2 = get_touch(0)
	var t2: Vector2 = get_touch(1)
	var center: Vector2 = (t1 + t2) * 0.5 - offset
	world_anchor = screen_to_world(center)
	start_dist = t1.distance_to(t2)
	base_scale = content_scale

func scale_process() -> void:
	if start_dist == 0: return
	var t1: Vector2 = get_touch(0)
	var t2: Vector2 = get_touch(1)
	var center: Vector2 = (t1 + t2) * 0.5 - offset
	var new_dist: float = t1.distance_to(t2)
	var factor: float = new_dist / start_dist
	var new_scale: float = base_scale * factor
	var new_scroll: Vector2
	var new_offset: Vector2
	var offset_delta: Vector2
	if hard_bounds: 
		new_scale = minmax_scale(new_scale)
		new_offset = get_container_offset(new_scale)
		offset_delta = new_offset - offset
		new_scroll = minmax_scroll(world_anchor * new_scale - center + offset_delta, new_scale)
	else:
		new_offset = get_container_offset(new_scale)
		offset_delta = new_offset - offset
		new_scroll = world_anchor * new_scale - center + offset_delta
	last_scale_target = center
	set_view(new_scale, new_scroll, new_offset)

func set_view(new_scale: float, new_scroll: Vector2, offset_v: Vector2 = Vector2.INF) -> void:
	var container: Control = get_container()
	if !container: return
	var off: Vector2 = offset if offset_v == Vector2.INF else offset_v
	container.rect_position = -new_scroll + off
	container.rect_scale = Vector2(new_scale, new_scale)
	content_scale = new_scale
	scroll = new_scroll
	if offset_v != Vector2.INF: offset = offset_v

func update_container(new_scale: float, relative: Vector2 = Vector2.ZERO) -> void:
	if hard_bounds: new_scale = minmax_scale(new_scale)
	var ratio: float = new_scale / content_scale
	var rel: Vector2 = scroll + relative - offset
	offset = get_container_offset(new_scale)
	var new_scroll: Vector2 = rel * ratio - relative + offset
	if hard_bounds: new_scroll = minmax_scroll(new_scroll, new_scale)
	set_view(new_scale, new_scroll, offset)

func force_standard() -> void:
	var std: Dictionary = get_standard(content_scale)
	set_view(std.scale, std.scroll, get_container_offset(std.scale))

func get_standard(scale_arg: float) -> Dictionary:
	var std_scale: float = minmax_scale(scale_arg)
	var ratio: float = std_scale / content_scale
	var rel: Vector2 = scroll + last_scale_target - offset
	var new_offset = get_container_offset(std_scale)
	var std_scroll: Vector2 = rel * ratio - last_scale_target + new_offset
	std_scroll = minmax_scroll(std_scroll, std_scale)
	return {
		"scale": std_scale,
		"scroll": std_scroll
	}

func _return_step(progress: float, from_scale: float, scale_delta: float, from_scroll: Vector2, scroll_delta: Vector2, from_offset: Vector2, offset_delta: Vector2) -> void:
	var scale_value: float = from_scale + progress * scale_delta
	var scroll_value: Vector2 = from_scroll + progress * scroll_delta
	var offset_value: Vector2 = from_offset + progress * offset_delta
	set_view(scale_value, scroll_value, offset_value)

func to_standard(await_time: float) -> void:
	if hard_bounds: return
	if tween && tween.is_valid() && tween.is_running():
		tween.kill()
	var std: Dictionary = get_standard(content_scale)
	tween = create_tween()
	tween.tween_interval(await_time)
	tween.chain().tween_method(self, "_return_step", 0.0, 1.0, returning_time, 
		[
			content_scale, std.scale - content_scale,
			scroll, std.scroll - scroll,
			offset, get_container_offset(std.scale) - offset
		]
	)

func returning_stop() -> void:
	if tween && tween.is_valid() && tween.is_running(): tween.kill()

func update_scroll_on_real() -> void:
	var container: Control = get_container()
	if !container: return
	scroll = -container.rect_position - get_container_offset(content_scale)

func set_scale_wtch_anchor(value: float, point: Vector2) -> void:
	update_container(value, point)
	var new_scroll: Vector2 = world_anchor * content_scale - point + offset
	if hard_bounds: new_scroll = minmax_scroll(new_scroll, content_scale)
	set_view(content_scale, new_scroll)

func screen_to_world(pos: Vector2) -> Vector2:
	return (pos + scroll) / content_scale

func world_to_screen(pos: Vector2) -> Vector2:
	return pos * content_scale - scroll

func get_container() -> Control:
	if get_child_count() == 0: return null
	var child = get_child(0)
	if child is Control: return child
	return null

func get_container_offset(scale_value: float) -> Vector2:
	var container: Control = get_container()
	if !container: return Vector2.ZERO
	var size: Vector2 = (container.rect_size + max_scroll_zone - min_scroll_zone) * scale_value
	return Vector2(
		get_position_on_flag(container.size_flags_horizontal, rect_size.x, size.x),
		get_position_on_flag(container.size_flags_vertical, rect_size.y, size.y)
	)

func minmax_scroll(value: Vector2, scale_value: float) -> Vector2:
	var container: Control = get_container()
	var container_size: Vector2
	if !container: container_size = Vector2.ZERO
	else: container_size = container.rect_size
	var max_v: Vector2 = (container_size + max_scroll_zone) * scale_value - rect_size
	var min_v: Vector2 = min_scroll_zone * scale_value
	max_v.x = max(min_v.x, max_v.x)
	max_v.y = max(min_v.y, max_v.y)
	return clamp_v2(value, min_v, max_v)

func minmax_scale(value: float) -> float:
	if scale_on_content == ContentScale.NULL: return clamp(value, min_scale, max_scale)
	var container: Control = get_container()
	if !container: return 1.0
	var container_size: Vector2 = container.rect_size
	if container_size.x == 0: container_size.x = rect_size.x
	if container_size.y == 0: container_size.y = rect_size.y
	var ratio: Vector2 = rect_size / container_size
	var new_min: float
	if scale_on_content == ContentScale.ON_BIG_SIDE: new_min = min(ratio.x, ratio.y)
	else: new_min = max(ratio.x, ratio.y)
	return clamp(value, max(new_min, min_scale), max_scale)

func clamp_v2(value: Vector2, minv: Vector2, maxv: Vector2) -> Vector2:
	return Vector2(
		clamp(value.x, minv.x, maxv.x),
		clamp(value.y, minv.y, maxv.y)
	)

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
	var rect: Rect2 = Rect2(Vector2.ZERO, rect_size)
	return rect.has_point(point)

func get_size_on_flag(flag: int, avaible_space: float) -> float:
	if flag & SIZE_FILL && flag & SIZE_EXPAND: return avaible_space
	return 0.0

func get_position_on_flag(flag: int, avaible_space: float, size_v: float) -> float:
	var value: float = 0.0
	if !(flag & SIZE_EXPAND) || flag & SIZE_FILL: value = 0.0
	elif flag & SIZE_SHRINK_END: value = avaible_space - size_v
	elif flag & SIZE_SHRINK_CENTER: value = (avaible_space - size_v) * 0.5
	if value < 0.0: return 0.0
	return value
