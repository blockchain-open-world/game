class_name NetworkMessage

var timeout = 0
var id = 0
var method = 0
var data: PackedByteArray
var response:PackedByteArray
var responseIndex = 0
var received = false

func getShort():
	var value = response.decode_s16(responseIndex);
	responseIndex = responseIndex + 2;
	return value;
	
func getUShort():
	var value = response.decode_u16(responseIndex);
	responseIndex = responseIndex + 2;
	return value;

func getInteger():
	var value = response.decode_s32(responseIndex);
	responseIndex = responseIndex + 4;
	return value;
	
func getUInteger():
	var value = response.decode_u32(responseIndex);
	responseIndex = responseIndex + 4;
	return value;

func hasNext():
	return response.size() > responseIndex
