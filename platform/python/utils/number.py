import sys
def is_number(value):
	return isinstance(value, (int, float, complex))

int_min = -sys.maxsize
int_max = sys.maxsize