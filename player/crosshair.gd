extends TextureRect

var lastWidth = 0
var lastHeight = 0

func _process(delta):
	var viewport = DisplayServer.window_get_size(0)
	var w = viewport.x
	var h = viewport.y
	
	if lastWidth != w || lastHeight != h:
		var size = int(w*0.02)
		lastHeight = h
		lastWidth = w
		set_size(Vector2(size, size))
		set_position(Vector2(w/2-size/2,h/2-size/2))

