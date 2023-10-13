class_name NetworkMessage

var timeout = 0
var id = 0
var data: PackedByteArray
var response:PackedByteArray
var responseIndex = 0
var received = false

func getInteger():
	var value = response.decode_s16(responseIndex);
	responseIndex = responseIndex + 2;
	return value;

func hasNext():
	return response.size() > responseIndex
