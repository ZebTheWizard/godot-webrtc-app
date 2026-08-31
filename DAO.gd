class_name DAO extends Node

var db: SQLite
var crypto: CryptoUtils

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
	crypto = CryptoUtils.new()
	db = SQLite.new()
	db.path = "user://data.db"
	db.open_db()
	db.foreign_keys = true
	
	var matches_query := """
	CREATE TABLE IF NOT EXISTS matches (
	    id TEXT PRIMARY KEY NOT NULL UNIQUE,
	    name TEXT,
	    password TEXT,
	    map TEXT,
	    status TEXT,
	    type TEXT
	);
	"""

	var players_query := """
	CREATE TABLE IF NOT EXISTS players (
	    id TEXT PRIMARY KEY NOT NULL UNIQUE,
	    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
	    password TEXT NOT NULL,
	    client_id INTEGER UNIQUE,
		is_host BOOLEAN NOT NULL DEFAULT 0,
	    team INTEGER,
	    match_id TEXT,
	    FOREIGN KEY (match_id) REFERENCES matches(id)
	);
	"""

	db.query(matches_query)
	db.query(players_query)
	
func insert_match(data:Dictionary = {}):
	var id = crypto.GenerateUUID()
	db.insert_row("matches", {
		"id": id,
		"name": data.get('name', 'Unnamed Match'),
		"password": data.get("password"),
		'map': data.get("map", map.DEFAULT),
		"status": data.get("status", match_status.MATCHING),
		"type": data.get("type", match_type.FFA)
	})
	
	return get_match_by_id(id)

func insert_player(data:Dictionary = {}):
	var id = crypto.GenerateUUID()
	db.insert_row("players", {
		"id": id,
		"username": data.get("username"),
		"password": data.get('password'),
		'client_id': data.get('client_id'),
		'is_host': data.get('is_host', 0),
		"team": data.get("team"),
		"match_id": data.get("match_id"),
	})
	
	return get_player_by_id(id)
	
func get_match_by_id(id:String):
	var query = "SELECT * from matches where id = ?"
	var paramBindings = [id]
	db.query_with_bindings(query, paramBindings)
	for result in db.query_result:
		return result

func get_players_by_match_id(id:String):
	var query = "SELECT * from players where match_id = ?"
	var paramBindings = [id]
	db.query_with_bindings(query, paramBindings)
	return db.query_result
	
func get_matches():
	var query = "SELECT * from matches ORDER BY name"
	db.query_with_bindings(query, [])
	return db.query_result
	
func get_player_by_id(id:String):
	var query = "SELECT * from players where id = ?"
	var paramBindings = [id]
	db.query_with_bindings(query, paramBindings)
	for result in db.query_result:
		return result
			
func get_player_by_client_id(id:int):
	var query = "SELECT * from players where client_id = ?"
	var paramBindings = [id]
	db.query_with_bindings(query, paramBindings)
	for result in db.query_result:
		return result
			
func get_player_by_username(username:String):
	var query = "SELECT * from players where username = ?"
	var paramBindings = [username]
	db.query_with_bindings(query, paramBindings)
	for result in db.query_result:
		return result
		
func update_player_by_client_id(client_id:int, data:Dictionary):
	return _update_with_bindings('players', 'client_id = ?', data, [client_id])
		
func delete_match_by_id(match_id):
	return db.delete_rows('matches', 'id = %s' % match_id)
		
func _update_with_bindings(table:String, condition:String, data:Dictionary, condition_bindings:Array):
	var set_clauses : Array = []
	var bindings : Array = []

	for key in data.keys():
		set_clauses.append("%s = ?" % key)
		bindings.append(data[key])

	bindings.append_array(condition_bindings)

	var query_string : String = "UPDATE %s SET %s WHERE %s;" % [table, ", ".join(set_clauses), condition]
	return db.query_with_bindings(query_string, bindings)	
