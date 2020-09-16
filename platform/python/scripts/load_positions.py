import sys
from datasets.live.data_srouce import PositionDataSource

if __name__ == '__main__':
	if len(sys.args)>2:
		if sys.argv[1] == 'asia':
			ds = PositionDataSource(aisa=True)
			ds.backfill()

		else:
			raise ValueError("invalid arguemnt")
	else:
		ds= PositionDataSource()
		ds.backfill()