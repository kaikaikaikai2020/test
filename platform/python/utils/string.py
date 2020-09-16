def has_number(str):
	return any(char.isdigit() for char in str)

def find_number(str):
	for i in range(len(str)):
		if str[i].isdigit():
			return i

	return -1