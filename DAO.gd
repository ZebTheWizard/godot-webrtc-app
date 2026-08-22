class_name DAO extends Node

var db

var match_status = {
	&"MATCHING": &"matching",
	&"IN_PROGRESS": &"playing",
}

var map = {
	&"DEFAULT": &"uid://ynqly5lsqmk4"
}

var match_type = {
	&"FFA": &"free-for-all"
}



func _init() -> void:
	db = SQLite.new()
	db.path = "user://data.db"
	db.open_db()
	db.foreign_keys = true
	
	db.create_table("players", {
		"id" : {"data_type": "text", "primary_key" : true, "not_null" : true, },
		"name": {"data_type" : "text"},
		"password" : {"data_type" : "text"},
		"clientId": {"data_type" : "text"},
		"team": {"data_type" : "int"},
		"match_id": {"data_type": "string", "foreign_key": "matches.id"}
	})
	
	db.create_table('matches', {
		"id" : {"data_type": "text", "primary_key" : true, "not_null" : true, },
		"name": {"data_type" : "text"},
		"password": {"data_type" : "text"},
		"map": {"data_type" : "text"},
		"status": {"data_type" : "text"},
		"type": {"data_type" : "text"},
	})
	
func insert_match(data:Dictionary = {}):
	var id = uuid()
	db.insert_row("matches", {
		"id": id,
		"map": data.get("map", map.DEFAULT),
		"name": data.get('name', 'Unnamed Match'),
		'password': data.get('password'),
		"status": data.get("status", match_status.MATCHING),
		"type": data.get("type", match_type.FFA)
	})
	
	return get_match_by_id(id)
	
func get_match_by_id(id:String):
	var query = "SELECT * from matches where id = ?"
	var paramBindings = [id]
	db.query_with_bindings(query, paramBindings)
	for result in db.query_result:
		return result

func uuid() -> String:
	var crypto = Crypto.new()
	var bytes = crypto.generate_random_bytes(16)

	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80

	var hex = bytes.hex_encode()

	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]
