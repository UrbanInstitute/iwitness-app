import csv
import json
import os

def csv_to_json(csv_filename):
	path, extension = os.path.splitext(csv_filename)
	json_filename = path + os.path.extsep + 'json'
	csvfile = open(csv_filename, 'r')
	jsonfile = open(json_filename, 'w')

	reader = csv.DictReader(csvfile)
	json.dump({ "persons": list(reader) }, jsonfile)
