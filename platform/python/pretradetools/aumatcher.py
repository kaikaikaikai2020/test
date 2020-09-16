from matcherUS import *
from datetime import *
import platform
plat = platform.platform
if plat.lower().startswith('linux'):
	GOLPATH ='/dat/golkonda_data'
else:
	GOLPATH = 'Y:'
M = matcherUS(coutry="AU")
f = file('%s/P5Asia/AUProd/TODO.txt'%GOLPATH,'w')
f.close()
while (1):
	sleep(5)
	L = os.listdir('%s/P5Asia/AUProd/'%GOLPATH)
	if 'TODO.txt' in L:
		print("P5 not done p5AUProd.py")
		print("will check in 5 sec")
	else:
		break
today =datetime.now(M.TZ)
date1 = today.strftime('%Y-%M-%d')
date2 = today.strftime('%Y%m%d')
M.loadTradeFile('file1')
M.loadTradeFile('file2')
M.matching()
