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

var _scroll: Vector2 = Vector2.ZERO
var _min_scroll_zone: Vector2 = Vector2.ZERO
var _max_scroll_zone: Vector2 = Vector2.ZERO
var _scale: float = 1.0
var _min_scale: float = 0.1
var _max_scale: float = 100
var _scale_on_content: int = ContentScale.NULL
var _scroll_mouse_button: int = 0b111
var _one_finger_scrolling: bool = true
var _drag_alpha: float = 0.9
var _hard_bounds: bool = false
var _returning_time: float = 0.2
var _mouse_await_time: float = 0.2
var _touch_await_time: float = 0.0

var touches: Dictionary = {}
var dragging: bool = false
var pressed: int = 0
var untouched: bool = true
var world_anchor: Vector2 = Vector2.INF
var start_dist: float = 0.0
var base_scale: float = 0.0
var mouse_exited_flag: bool = false
var offset: Vector2 = Vector2.ZERO
var tween: SceneTreeTween = null
var current_key_pressed: int = -1

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
		"Scroll/scroll": return _scroll
		"Scroll/min_scroll_zone": return _min_scroll_zone
		"Scroll/max_scroll_zone": return _max_scroll_zone
		"Scale/scale": return _scale
		"Scale/min_scale": return _min_scale
		"Scale/max_scale": return _max_scale
		"Scale/scale_on_content": return _scale_on_content
		"Controls/scroll_mouse_button": return _scroll_mouse_button
		"Controls/one_finger_scrolling": return _one_finger_scrolling
		"Controls/drag_alpha": return _drag_alpha
		"Bound/hard_bounds": return _hard_bounds
		"Bound/returning_time": return _returning_time
		"Bound/mouse_await_time": return _mouse_await_time
		"Bound/touch_await_time": return _touch_await_time
	return null

func _set(property: String, value) -> bool:
	match property:
		"Scroll/scroll":
			_scroll = value
			return true
		"Scroll/min_scroll_zone":
			_min_scroll_zone = value
			return true
		"Scroll/max_scroll_zone":
			_max_scroll_zone = value
			return true
		"Scale/scale":
			_scale = value
			return true
		"Scale/min_scale":
			_min_scale = value
			return true
		"Scale/max_scale":
			_max_scale = value
			return true
		"Scale/scale_on_content":
			_scale_on_content = value
			return true
		"Controls/scroll_mouse_button":
			_scroll_mouse_button = value
			return true
		"Controls/one_finger_scrolling":
			_one_finger_scrolling = value
			return true
		"Controls/drag_alpha":
			_drag_alpha = value
			return true
		"Bound/hard_bounds":
			_hard_bounds = value
			return true
		"Bound/returning_time":
			_returning_time = value
			return true
		"Bound/mouse_await_time":
			_mouse_await_time = value
			return true
		"Bound/touch_await_time":
			_touch_await_time = value
			return true
	return false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY: 
			rect_clip_content = true
			offset = get_container_offset(_scale)
			update_scroll_on_real()
			force_standard()
		NOTIFICATION_SORT_CHILDREN: 
			if world_anchor == Vector2.INF: 
				if _hard_bounds: force_standard()
				else: to_standard(0)
		NOTIFICATION_WM_MOUSE_ENTER: mouse_exited_flag = false
		NOTIFICATION_WM_MOUSE_EXIT: mouse_exited_flag = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP: 
				update_container(_scale * 1.1, event.position)
				if !_hard_bounds: to_standard(_mouse_await_time)
			BUTTON_WHEEL_DOWN: 
				update_container(_scale / 1.1, event.position)
				if !_hard_bounds: to_standard(_mouse_await_time)
		if !has_button(_scroll_mouse_button, event.button_index): return
		if event.pressed: 
			if !pressed: world_anchor = screen_to_world(event.position - offset)
			set_pressed(event.button_index, true)
			if !_hard_bounds: returning_stop()
		else:
			set_pressed(event.button_index, false)
			if !pressed: world_anchor = Vector2.INF
			if dragging:
				dragging = false
				emit_signal("drag_ended")
			if !_hard_bounds: to_standard(_mouse_await_time)
	elif event is InputEventMouseMotion:
		if world_anchor == Vector2.INF: return
		var new_scroll: Vector2 = world_anchor * _scale - event.position + offset
		if _hard_bounds: new_scroll = minmax_scroll(new_scroll, _scale)
		if !dragging && (new_scroll - _scroll).length() > 2.5:
			dragging = true
			emit_signal("drag_started")
		set_view(_scale, new_scroll)

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
					if !_hard_bounds: returning_stop()
					if pressed && world_anchor != Vector2.INF:
						set_scale_witch_anchor(_scale / 1.1, point)
					else: update_container(_scale / 1.1, point)
				KEY_EQUAL: 
					if event.echo: 
						if current_key_pressed != event.scancode: return
					else: current_key_pressed = event.scancode
					if !_hard_bounds: returning_stop()
					if pressed && world_anchor != Vector2.INF:
						set_scale_witch_anchor(_scale * 1.1, point)
					else: update_container(_scale * 1.1, point)
				_:
					if !event.echo:
						if !_hard_bounds && world_anchor == Vector2.INF: to_standard(_mouse_await_time)
						current_key_pressed = -1
		else:
			match event.scancode:
				KEY_MINUS, KEY_EQUAL: 
					if current_key_pressed == event.scancode: 
						if !_hard_bounds && world_anchor == Vector2.INF: to_standard(_mouse_await_time)
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

func on_screen_touch(index: int, pressed: bool, position: Vector2) -> void:
	if pressed: 
		touches[index] = position
		if !_hard_bounds: returning_stop()
		match touches.size():
			1: 
				untouched = false
				dragging = false
				world_anchor = screen_to_world(position - offset)
			2: start_scale_touch()
	else: 
		touches.erase(index)
		if !untouched: untouched = true
		if touches.size() == 0: 
			emit_signal("drag_ended")
			world_anchor = Vector2.INF
			if !_hard_bounds: to_standard(_touch_await_time)

func on_screen_drag(index: int, position: Vector2) -> void:
	if untouched: return
	touches[index] = position
	match touches.size():
		1:
			if !_one_finger_scrolling: return
			var new_scroll: Vector2 = world_anchor * _scale - position + offset
			if _hard_bounds: new_scroll = minmax_scroll(new_scroll, _scale)
			if !dragging && (new_scroll - _scroll).length() > 2.5:
				dragging = true
				emit_signal("drag_started")
			set_view(_scale, new_scroll)
		2:
			scale_process()

func start_scale_touch() -> void:
	var t1: Vector2 = get_touch(0)
	var t2: Vector2 = get_touch(1)
	var center: Vector2 = (t1 + t2) * 0.5 - offset
	world_anchor = screen_to_world(center)
	start_dist = t1.distance_to(t2)
	base_scale = _scale

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
	if _hard_bounds: 
		new_scale = minmax_scale(new_scale)
		new_offset = get_container_offset(new_scale)
		offset_delta = new_offset - offset
		new_scroll = minmax_scroll(world_anchor * new_scale - center + offset_delta, new_scale)
	else:
		new_offset = get_container_offset(new_scale)
		offset_delta = new_offset - offset
		new_scroll = world_anchor * new_scale - center + offset_delta
	set_view(new_scale, new_scroll, new_offset)

func set_view(new_scale: float, new_scroll: Vector2, offset_v: Vector2 = Vector2.INF) -> void:
	var container: Control = get_container()
	if !container: return
	var off: Vector2 = offset if offset_v == Vector2.INF else offset_v
	container.rect_position = -new_scroll + off
	container.rect_scale = Vector2(new_scale, new_scale)
	_scale = new_scale
	_scroll = new_scroll
	if offset_v != Vector2.INF: offset = offset_v

func update_container(new_scale: float, relative: Vector2 = Vector2.ZERO) -> void:
	if _hard_bounds: new_scale = minmax_scale(new_scale)
	var ratio: float = new_scale / _scale
	var rel: Vector2 = _scroll + relative - offset
	offset = get_container_offset(new_scale)
	var new_scroll: Vector2 = rel * ratio - relative + offset
	if _hard_bounds: new_scroll = minmax_scroll(new_scroll, new_scale)
	set_view(new_scale, new_scroll, offset)

func force_standard() -> void:
	var std: Dictionary = get_standard(_scale)
	set_view(std.scale, std.scroll, get_container_offset(std.scale))

func get_standard(scale: float) -> Dictionary:
	var std_scale: float = minmax_scale(scale)
	var std_scroll: Vector2 = minmax_scroll(_scroll, std_scale)
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
	if _hard_bounds: return
	if tween && tween.is_valid() && tween.is_running():
		tween.kill()
	var std: Dictionary = get_standard(_scale)
	tween = create_tween()
	tween.tween_interval(await_time)
	tween.chain().tween_method(self, "_return_step", 0.0, 1.0, _returning_time, [_scale, std.scale - _scale, _scroll, std.scroll - _scroll, offset, get_container_offset(std.scale) - offset])

func returning_stop() -> void:
	if tween && tween.is_valid() && tween.is_running(): tween.kill()

func update_scroll_on_real() -> void:
	var container: Control = get_container()
	if !container: return
	_scroll = -container.rect_position - get_container_offset(_scale)

func set_scale_witch_anchor(value: float, point: Vector2) -> void:
	update_container(value, point)
	var new_scroll: Vector2 = world_anchor * _scale - point + offset
	if _hard_bounds: new_scroll = minmax_scroll(new_scroll, _scale)
	set_view(_scale, new_scroll)

func screen_to_world(pos: Vector2) -> Vector2:
	return (pos + _scroll) / _scale

func world_to_screen(pos: Vector2) -> Vector2:
	return pos * _scale - _scroll

func get_container() -> Control:
	if get_child_count() == 0: return null
	var child = get_child(0)
	if child is Control: return child
	return null

func get_container_offset(scale_value: float) -> Vector2:
	var container: Control = get_container()
	if !container: return Vector2.ZERO
	var size: Vector2 = (container.rect_size + _max_scroll_zone - _min_scroll_zone) * scale_value
	return Vector2(
		get_position_on_flag(container.size_flags_horizontal, rect_size.x, size.x),
		get_position_on_flag(container.size_flags_vertical, rect_size.y, size.y)
	)

func minmax_scroll(value: Vector2, scale_value: float) -> Vector2:
	var container: Control = get_container()
	var container_size: Vector2
	if !container: container_size = Vector2.ZERO
	else: container_size = container.rect_size
	var max_v: Vector2 = (container_size + _max_scroll_zone) * scale_value - rect_size
	var min_v: Vector2 = _min_scroll_zone * scale_value
	max_v.x = max(min_v.x, max_v.x)
	max_v.y = max(min_v.y, max_v.y)
	return clamp_v2(value, min_v, max_v)

func minmax_scale(value: float) -> float:
	if _scale_on_content == ContentScale.NULL: return clamp(value, _min_scale, _max_scale)
	var container: Control = get_container()
	if !container: return 1.0
	var container_size: Vector2 = container.rect_size
	if container_size.x == 0: container_size.x = rect_size.x
	if container_size.y == 0: container_size.y = rect_size.y
	var ratio: Vector2 = rect_size / container_size
	var new_min: float
	if _scale_on_content == ContentScale.ON_BIG_SIDE: new_min = min(ratio.x, ratio.y)
	else: new_min = max(ratio.x, ratio.y)
	return clamp(value, max(new_min, _min_scale), _max_scale)

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
	var smoothed: Vector2 = _drag_alpha * raw_position + (1.0 - _drag_alpha) * last_position
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

func get_position_on_flag(flag: int, avaible_space: float, size: float) -> float:
	var value: float = 0.0
	if !(flag & SIZE_EXPAND) || flag & SIZE_FILL: value = 0.0
	elif flag & SIZE_SHRINK_END: value = avaible_space - size
	elif flag & SIZE_SHRINK_CENTER: value = (avaible_space - size) * 0.5
	if value < 0.0: return 0.0
	return value
