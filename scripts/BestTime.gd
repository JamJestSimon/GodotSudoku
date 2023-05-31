extends Node

var best_times = []

func fill_best_times(amount):
	for i in range(amount):
		best_times.append(-1)

func get_best_time(i):
	return best_times[i]

func save():
	var save_dict = {
		"best-times" : best_times
	}
	return save_dict
