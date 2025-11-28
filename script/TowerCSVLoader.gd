extends Node

class_name TowerCSVLoader

static func load_tower_data_from_csv(file_path: String) -> Dictionary:
	var tower_data_dict = {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to load tower CSV file: " + file_path)
		return tower_data_dict
	
	# Baca header
	var headers = file.get_csv_line()
	
	# Baca data
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= headers.size() and line[0] != "":
			var tower_type = line[0]
			var data = {
				# Hapus scene_path dari CSV, gunakan @export di Inspector saja
				"bullet_speed": float(line[1]),
				"bullet_damage": float(line[2]),
				"cooldown": float(line[3]),
				"range_radius": float(line[4]),
				"base_cost": int(line[5]),
				"upgrade_cost_level2": int(line[6]),
				"upgrade_cost_level3": int(line[7])
			}
			tower_data_dict[tower_type] = data
	
	file.close()
	return tower_data_dict
