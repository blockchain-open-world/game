extends TextureRect

var lastWidth = 0
var lastHeight = 0

func _process(_delta):
	var viewport = DisplayServer.window_get_size(0)
	var w = viewport.x
	var h = viewport.y
	
	if lastWidth != w || lastHeight != h:
		var screenSize = int(w*0.02)
		lastHeight = h
		lastWidth = w
		set_size(Vector2(screenSize, screenSize))
		set_position(Vector2(w/2.0-screenSize/2.0,h/2.0-screenSize/2.0))

