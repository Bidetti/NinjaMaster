class_name UIPanelCreator
extends RefCounted

static func create_styled_panel(size: Vector2, parent_node: Node) -> Panel:
	var panel = Panel.new()
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style_panel.border_width_left = 3
	style_panel.border_width_right = 3
	style_panel.border_width_top = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color.WHITE
	style_panel.corner_radius_top_left = 15
	style_panel.corner_radius_top_right = 15
	style_panel.corner_radius_bottom_left = 15
	style_panel.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style_panel)
	
	panel.size = size
	panel.position = Vector2(
		(parent_node.get_viewport().size.x - panel.size.x) / 2,
		(parent_node.get_viewport().size.y - panel.size.y) / 2
	)
	
	return panel

static func create_overlay(parent_node: Node) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.size = parent_node.get_viewport().size
	overlay.position = Vector2.ZERO
	return overlay

static func create_styled_button(text: String, font_size: int = 28) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 60)
	
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_color_hover", Color.YELLOW)
	button.add_theme_color_override("font_color_pressed", Color.GREEN)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color.WHITE
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.7, 0.3, 0.9)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color.YELLOW
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.1, 0.5, 0.1, 0.9)
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color.GREEN
	style_pressed.corner_radius_top_left = 10
	style_pressed.corner_radius_top_right = 10
	style_pressed.corner_radius_bottom_left = 10
	style_pressed.corner_radius_bottom_right = 10
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	return button
