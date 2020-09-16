from abc import ABC
from abc import abstractmethod
class StrategyImpl(ABC):
	@abstractmethod
	def get_current_time(self):
		...

	@abstractmethod
	def get_current_date(self):
		...
	@abstractmethod
	def insert_order(self, order):
		...

	@abstractmethod
	def cancel_order(self, id):
		...
	@abstractmethod
	def modify_order(self, order):
		...

	@abstractmethod
	def is_live(self) -> bool:
		return False

