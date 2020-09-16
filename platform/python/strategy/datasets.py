from datasets.dataset import dataset
from reuters.trth import Bar as trth_bar
class Bar(Dataset):
	def __init__(self):
		super.__init__(name='bar', symbologies = None, parent=None, frequency='1d')
