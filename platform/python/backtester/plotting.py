import pandas as pd
import numpy as np
from bokeh.plotting import figure, output_notebook, show
from bokeh.io import push_notebook
from bokeh.palettes import d3
from bokeh.models.tools import CrosshairTool, BoxSelectTool, HoverTool, WheelPanTool
from bokeh.models import ColumnDataSource, LinearAxis, RangeId, Legend

output_notebook()

def plot_nice_table(data, title):
	from IPython.display import display, HTML
	
	def hover(hover_color="#03F0F7"):
		return dict(selector="tr:hover", props=[("background-color","%s", %hover_color)])
	styles = [
	hover(),
	dict(selector="th", props=[("background-color","#eee"), ("text-aligh", "center")]),
	dict(selector="td", props=[("text-aligh","right"),("min-width","5em")])
	]

	html = (data.style.set_table_styles(styles).set_caption(title))

	display(html)

def plot_instrument_pnl_contribution_hist(pnl_series, figsize=(15,10)):
	import matplotlib.pyplot as plt
	stock_pnl = pnl_series[abs(pnl_series)>0]
	stock_pnl = stock_pnl.groupby(level=1).sum()
	stock_contribution = stock_pnl/stock_pnl.sum()
	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)
	stock_contribution.hist(bins=50, ax=ax)
	ax.set_xlabel ('Pnl contribution', size =10)
	ax.set_ylabel('Frequecy', size =10)
	ax.set_title ('pnl contribution mist')
	return ax

def plot_instrument_pnl_contribution(pnl_series, figsize = (15,10)):
	import matplotlib.pyplot as plt
	pnl = pnl_series[abs(pnl_series)>0]
	pnl = pnl.groupby(level=1).sum()
	contribution = pd.DataFrame(index = pnl.index)
	contribution['contribution(%)'] = contribution['pnl']/pnl.sum()*100
	contribution_sorted = contribution.sort_values(by='pnl', ascending= False)
	if len(contribution_sorted) >20:
		contribution_top = contribution_sorted.nlargest(10, columns='pnl')
		contribution_bottom = contribution.nsmallest(10, columns= 'pnl')
		plot_nice_table(contribution_top.reset_index(), 'Instrument pnl top 10')
		plot_nice_table(contribution_bottom.reset_index(), 'Instrument pnl bottom 10')
		top_10 = contribution_top.index.unique()
		bottom_10 = contribution_bottom.index.unique()
		pnl_10 = pnl_series.loc[slice(None), top_10.tolist()+bottom_10.tolist()].sort_index().fillna(0).groupby(level=1).cumsum()
		pnl_stack = pnl_10.unstack()
		plot_ts(pnl_stack)
	else:
		df = contribution_sorted.dropna()
		plot_nice_table(df.reset_index(), 'Instrument pnl')
		pnl_10 = pnl_series.loc[slice(None), contribution.index.unique().tolist()].sort_index().fillna(0).groupby(level=1).cumsum()
		pnl_stack = pnl_10.unstack()
		plot_ts(pnl_stack)
	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)
	df = contribution_sorted.dropna()
	df['contribution(%)'].plot(ax=ax, kind='bar')
	ax.xaxis.set_visible(False)
	ax.set_xlabel('Symobol', size =10)
	ax.set_ylabel ('contribution(%)', size =10)
	ax.set_title('Instrument pnl contribution')
	return ax

def plot_stock_pnl_contribution(stock_pnl_series, figsize=(15,10)):
	import matplotlib.pyplot as plt
	pnl = stock_pnl_series.groupby(level=1).sum()
	contribution = pd.DataFrame(index=pnl.index)
	contribution['pnl'] =pnl
	contribution['pct'] = contribution['pnl']/abs(pnl.sum())*100
	contribution_sorted = contribution.sort_values(by='pnl', ascending= False)
	df = contribution_sorted.dropna()
	plot_nice_table(df.sort_values(by='pnl', ascending=False).reset_index().head(10),"top 10")
	plot_nice_table(df.sort_values(by='pnl', ascending=True).reset_index().head(10),"bottom 10")

	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)

	df['pct'].plot(ax=ax, kind='bar')
	ax.xaxis.set_visible(False)
	ax.set_xlabel('Symobol', size =10)
	ax.set_ylabel ('contribution(%)', size =10)
	ax.set_title('stock pnl contribution')
	return ax

def plot_sector_pnl_contribution(data, figsize=(15,10)):
	import matplotlib.pyplot as plt
	pnl = data.groupby('sector_name')['pnl_usd'].sum()
	contribution = pd.DataFrame(index=pnl.index)
	contribution['pnl'] =pnl
	contribution['pct'] = contribution['pnl']/abs(pnl.sum())*100
	contribution_sorted = contribution.sort_values(by='pnl', ascending= False)
	df = contribution_sorted.dropna()
	plot_nice_table(df.reset_index().head(10),"sector pnl")
	

	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)

	df['pct'].plot(ax=ax, kind='bar')
	ax.xaxis.set_visible(False)
	ax.set_xlabel('Symobol', size =10)
	ax.set_ylabel ('contribution(%)', size =10)
	ax.set_title('sector pnl contribution')
	return ax

def plot_annual_returns_stack(data, pnl_col = 'pnl', figsize=(15,10)):
	d = data
	d['year'] = d.index.map(lambda x:x.year)
	d['date'] = d.index.map(lambda x:x.replace(year=2000))

	df= pd.DataFrame(index = pd.date_range(start = '20000101', end = '20001231'))
	for year, group in d.groupby('year'):
		df[str(year)] = group[['date', pnl_col]].set_index('date')[pnl_col].cumsum()

	df.ffill(inplace=True)

	return plot_ts(df, width=950, height=600, title='annual pnl stack', x_label='date', y_label = 'cumulative pnl')

def plot_day_of_month_returns(data, figsize= (15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax= fig.add_subplot(111)
	d = data
	d['day'] = d.index.map(lambda x:x.day)
	day_pnl = d.groupby('day')['ret'].mean()
	day_pnl.plot(ax=ax, kind='bar')
	ax.set_xlabel('Day of month')
	ax.set_ylabel('average return')
	ax.set_title('day of month return')
	ax.Legend(loc='best')
	return ax

def plot_day_of_week_returns(data, figsize= (15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax= fig.add_subplot(111)
	d = data
	d['day'] = d.index.map(lambda x:x.dayofweek)
	day_pnl = d.groupby('day')['ret'].mean()
	day_pnl.plot(ax=ax, kind='bar')
	ax.set_xlabel('Day of week')
	ax.set_ylabel('average return')
	ax.set_title('day of week return')
	ax.Legend(loc='best')
	return ax

def plot_pos_adv_hist(value, adv, factor=1, log=True, quantile=0.95, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax = fig.add_subplot(111)
	df = pd.DataFrame()
	df['value'] = value.abs()*factor
	df['adv'] = adv
	filtered = df[df['value']>0][['value', 'adv']]
	filtered['pos_adv_pct'] = filtered['value']/filtered['adv']
	filtered = filtered [np.isfinite(filtered['pos_adv_pct'])]
	cutoff = filtered['pos_adv_pct'].quantile(q=quantile)
	total_poss = len(filtered)
	filtered = filtered(filtered['pos_adv_pct']>cutoff)
	if log:
		filtered['pos_adv_pct'] = np.log10(filtered['pos_adv_pct'])
	filtered['pos_adv_pct'].hist(bins=50, ax=ax, weights= np.zeros_like(filtered['pos_adv_pct'])+100/total_poss)

	if log:
		x_labels = np.linspace(np.log10(cutoff), filtered['pos_adv_pct'].max(),10)
		ax.set_xtick(x_label, size=10)
		ax.set_xticklabels(['%.2f' %10**x for x in x_labels])

	xlabel = 'Pos / ADV'
	ax.set_xlabel(xlabel, size=10)
	ax.set_ylabel('Frequecy', size =10)
	ax.set_title('Pos / ADV hist {}%@ {}'.format(quatile*100, cutoff))

	return ax

def plot_trd_adv_hist(trade, adv, factor=1, log=True, quantile=0.95, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax = fig.add_subplot(111)
	df = pd.DataFrame()
	df['trade'] = trade.abs()*factor
	df['adv'] = adv
	filtered = df[df['trade']>0][['trade', 'adv']]
	filtered['trd_adv_pct'] = filtered['trade']/filtered['adv']
	filtered = filtered [np.isfinite(filtered['trd_adv_pct'])]
	cutoff = filtered['trd_adv_pct'].quantile(q=quantile)
	total_poss = len(filtered)
	filtered = filtered(filtered['trd_adv_pct']>cutoff)
	if log:
		filtered['trd_adv_pct'] = np.log10(filtered['trd_adv_pct'])
	filtered['trd_adv_pct'].hist(bins=50, ax=ax, weights= np.zeros_like(filtered['trd_adv_pct'])+100/total_poss)

	if log:
		x_labels = np.linspace(np.log10(cutoff), filtered['pos_adv_pct'].max(),10)
		ax.set_xtick(x_label, size=10)
		ax.set_xticklabels(['%.2f' %10**x for x in x_labels])

	xlabel = 'Trade size / ADV'
	ax.set_xlabel(xlabel, size=10)
	ax.set_ylabel('Frequecy', size =10)
	ax.set_title('trade / ADV hist {}%@ {}'.format(quatile*100, cutoff))

	return ax


def plot_return_adv_scatter(ret, adv, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)
	df = pd.DataFrame()
	df['ret'] = ret
	df['adv'] = adv
	df = df[(df['adv']>0)&(df['ret'].abs()>0)]
	ax.scatter(np.log10(df['adv'].values), df['ret'].values)
	ax.set_xlabel('log10 adv', size=10)
	ax.set_ylabel('return', size =10)
	ax.set_title("return vs log10 adv")
	return ax

def plot_pos_adv_scatter(pos, adv, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)
	df = pd.DataFrame()
	df['pos'] = pos
	df['adv'] = adv
	df = df[(df['adv']>0)&(df['pos'].abs()>0)]
	ax.scatter(np.log10(df['adv'].values), df['pos'].values)
	ax.set_xlabel('log10 adv', size=10)
	ax.set_ylabel('pos', size =10)
	ax.set_title("pos vs log10 adv")
	return ax

def plot_trd_adv_scatter(trade, adv, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize=figsize)
	ax = fig.add_subplot(111)
	df = pd.DataFrame()
	df['pos'] = pos
	df['trade'] = trade
	df = df[(df['adv']>0)&(df['trade'].abs()>0)]
	ax.scatter(np.log10(df['adv'].values), df['trade'].values)
	ax.set_xlabel('log10 adv', size=10)
	ax.set_ylabel('trade', size =10)
	ax.set_title("trade vs log10 adv")
	return ax

def plot_return_pnl(data, figsize=(15,10), return_only=False, days = None, from_date = None, to_date = None, ret_col ='ret', pnl_col ='pnl', show_diff = False, benchmark = None, show_annual = False):
	from backtester.result import Result
	if isinstance(data, dict):
		pnl_df = None
		ret_df = None
		for k, d in data.items():
			d = d.portfolio_data
		if pnl_df is None:
			pnl_df = d[pnl_col].fillna(0).to_frame(k)
		else:
			pnl_df[k] = df[pnl_col].fillna(0)
		if ret_df is None:
			ret_df = d[ret_col].fillna(0).to_frame(k)
		else:
			ret_df[k] = d[ret_col].fillna(0)

		if from_date is not None:
			start_date = pd.Timestamp(from_date)
		else:
			start_date = ret_df.index[0]

		if to_date is not None:
			end_date = pd.Timestamp(to_date)
		else:
			end_date = ret_df.index[-1]
		if days is not none:
			start_date = ret_df.index[-days]

		plot_ts(ret_df[start_date:end_date].fillna(0).cumsum(), title="return")
		if not return_only:
			plot_ts(pnd_df[start_date:end_date].fillna(0).cumsum(), title='pnl')
		if show_diff:
			if benchmark is None:
				raise ValueError('please specify the benchmark')
			ret_df_diff = ret_df.sub(ret_df[benchmark].values, axis=0)
			plot_ts(ret_df_diff.cumsum(), title = 'return diff')

			if not return_only:
				pnl_df_diff = pnl_df.sub(pnl_df[benchmark].values, axis =0)
				plot_ts(pnl_df_diff.cumsum(), title= 'pnl diff')
		if show_annual:
			pnl_df = pnl_df[start_date:end_date]
			pnl_df['year'] = pnl_df.index.map(lambda x: x.year)
			pnl_df['date'] = pnl_df.index.map(lambda x:x)
			 for year, group in pnl_df.groupby('year'):
			 	df = group.set_index('date').cumsum()
			 	df = df.drop('year', axis =1)
			 	plot_ts(df, title='annual pnl ){}'.format(year), x_label = 'date', y_label = 'cumulative pnl')
	else:
		data[pnl_col]= data[pnl_col].fillna(0)
		data[ret_col] = data[ret_col].fillna(0)
		if from_date is not None:
			start_date = pd.Timestamp(from_date)
		else:
			start_date = data.index[0]

		if to_date is not None:
			end_date = pd.Timestamp(to_date)
		else:
			end_date = data.index[-1]
		if days is not none:
			start_date = data.index[-days]
		plot_ts(data[ret_col][start_date:end_date].cumsum(), title = 'return')
		if not return_only:
			plot_ts(data[pnl_col][start_date:].cumsum(), title= 'pnl')
def plot_pnl_long_short(data, figsize = (15,10)):
	plot_ts(data[['cum_pnl', 'cum_long_pnl', 'cum_short_pnl']], title='long/short pnl')
def plot_pnl_hedge(data,figsize= (15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax = fig.add_subplot(111)
	data[['cum_pnl', 'cum_hedge_pnl', 'cum_total_pnl', 'delta']].plot(ax=ax, secondary_y=['delta'])
	ax.set_title("hedge / total pnl")
	return ax

def plot_delta_and_size(data, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax = fig.add_subplot(111)
	data[['value', 'delta']].plot(ax=ax, secondary_y=['delta'])
	ax.set_title("delta and portfolio size")

	return ax

def plot_pnl_breakdown(statistics, hedging= False, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize= figsize)
	ax = fig.add_subplot(111)

	if hedging:
		explode = (0.1,0,0,0,0,0,0)
		np.abs(statistics.rename(columns={'hedge_pnl':'hedge'})[['total_pnl', 'tcost', 'slippage','financing_cost', 'hedge','borrow_cost', 'tax_cost']].loc['All']).plot(ax=ax, kind='pie', autopct='%1.1f%%', shadow = True, explode = explode)
	else:
		explode = (0.1,0,0,0,0,0)
		np.abs(statistics[['pnl','tcost, slippage', 'financing_cost','borrow_cost', 'tax_cost']].loc['All']).plot(ax=ax, kind='pie', autopct='%1.1f%%', shadow = True, explode = explode)
	ax.axis("equal")
	ax.set_title('pnl breakdown')
	return ax

def plot_slippage_sweep(portfolio_data, current_slippage, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize = figsize)
	ax = fig.add_subplot(111)
	d = portfolio_data
	pnl = d['pnl']+d['slippage']
	df = pd.DataFrame(index = portfolio_data.index)
	slippage_params = (0,1,2,5,10,20)
	for i in slippage_params:
		slippage = np.abs(d['turnover']*i/10000.0)
		pnl_slippage = pnl -slippage
		df['{} bps'.format(i)] = pnl_slippage.cumsum()

	if current_slippage in slippage_params:
		df.rename(columns={'{} bps'.format(current_slippage): '{} bps (current) '.format(current_slippage)}, inplace= True)
	else:
		df['{} bps (current)'.format(current_slippage)] = portfolio_data['cum_pnl']
	df.plot(ax=ax)
	ax = ax.set_title('pnl slippage sensitivie')
	return ax

def plot_rolling_beta(instrument_data, portfolio_data, benchmark_symbol):
	import pyfolio as pf
	benchmark_data = instrument_data.loc[(slice(None), benchmark_symbol),].reset_index(level=1, drop=True)
	benchmark_data['ret'] = benchmark_data['close'].pct_change().shift(-1)
	ax = pf.plotting.plot_rolling_beta(portfolio_data['ret'], benchmark_data['ret'])
	ax.autoscale()
def plot_turnover(turnover, figsize=(15,10)):
	import matplotlib.pyplot as plt
	fig = plt.figure(figsize = figsize)
	ax = fig.add_subplot(111)
	turnover.plot(ax=ax)
	ax.set_title('turnover')
	return ax
def load_and_plot_return(result_dict, figsize=(15,10), days= None):
	from simulation.api import load_result
	data_dict ={}
	results_dict = {}
	for n, r in result_dict.items():
		result = load_result(id=r)
		data_dict[n] = result.portfolio_data
		results_dict[n] = result
	plot_return_pnl(data= data_dict, return_only = True)
	if days is not None:
		plot_return_pnl(data= data_dict, return_only = True, days = day)
	return results_dict

def plot_ts(data, fig=None, width=950, title= None, x_label = None, y_label= None, line_width=2, show_figure = True, return_figure = False, right_y_axis = False): 
	if isinstance(data.index, pd.DatatimeIndex):
		x_axis_type = 'datetime'
		hover = HoverTool(tooltips=[("datetime", "$x{%F}"), ("value", "$y")], formatters= {'$x':'datetime'}, mode="mouse")
	else:
		x_axis_type = 'linear'
		hover = HoverTool(tooltips=[("index", "$x"), ("value", "$y")],  mode="mouse")
	if fig is None:
		p = figure(plot_width= width, plot_height = height, x_axis_type = x_axis_type,x_axis_label = x_label, y_axis_label = y_label, toolbar_location ='above')
		p.add_tools(CrosshairTool())
		p.add_tools(hover)
	else:
		p = fig
	y_range_name = None
	if right_y_axis:
		if isinstance(data, pd.DataFrame):
			axis_start = data.min().min()
			axis_end = data.max().max()
		else:
			axis_start = data.min()
			axis_end - data.max()
		p.extra_y_ranges = {"foo":Range1d(start= axis_start - abs(axis_end -axis_start)*0.2, end = axis_end +abs(axis_end -axis_start)*0.2, end=axis_end +abs(axis_end-axis_start)*0.2)} 
		p.add_layout(LinearAxis(y_range_name= "foo"), 'right')
		y_range_name = 'foo'
	if title is not None:
		p.title.text = title
	items = []
	if isinstance(data,pd.DataFrame):
		num_of_columns = len(data.columns)
		if num_of_columns <=10:
			color_scheme = 'Category10'
		else:
			color_scheme = 'Category20'
		color_list = d3[color_scheme][min(20, max(3, num_of_columns))]
		color_list_size = len(color_list)
		for i in range(len(data.columns)):
			col = data.columns[i]
			color = color_list[i % color_list_size]
			if y_range_name is not None:
				item = p.line(x=data.index, y= data[col], line_width=line_width, color = color, y_range_name = y_range_name)
			else:
				item = p.line(x=data.index, y= data[col], line_width=line_width, color = color)
			items.append((str(col), [item]))
	elif isinstance(data, pd.Series):
		if y_range_name is not None:
			item = p.line(x=data.index, y= data.values, line_width=line_width,  y_range_name = y_range_name)
		else:
			item = p.line(x=data.index, y= data[col], line_width=line_width)
		items.append((data.name, [item]))
	else:
		raise ValueError("unsupport data type")

	legend = Legend(items=items, location='center')
	p.add_layout(legend, 'right')
	p.legend.click_policy = 'hide'
	if show_figure:
		show(p, notebook_handle=True)

	if return_figure:
		return p
def plot_histogram(data, fig= None, width=950, hieght =600, title= None, x_label = None, y_label=None, show_figure = True, extra_bars= None, return_figure = False):
	if not isinstance(data, pd.Series):
		raise ValueError('only pandas series supported')
	if fig is None:
		p = figure(plot_width =width, plot_height=height, x_axis_label=x_label, y_axis_label=y_label, title=title)
		p.add_tools(CrosshairTool())
	else:
		p = fig
	hist, edges = np.histograme(data.dropna(), density = False, bins= bins)
	p.quad(top=hist, bottom=0, left=edges[:-1], right=edges[1:], fill_color="#036564", line_color="#033649")

	if extra_bars is not None:
		for bars, bar_color in extra_bars:
			p.vbar(x=bars, width=1, top=hist.max(), color= bar_color)	
	if show_figure:
		show(p, notebook_handle)
	if return_figure:
		return p

def plot_hist(*args, **kwargs):
	return plot_histogram(*args, **kwargs)

def plot_bars(data, fig=None, width=950, height =600, title=None, x_label=None, y_label=None, color='blue', show_figure=True, return_figure = False):
	if not isinstance(data, pd.Series):
		raise ValueError('only pandas series supported')
	if fig is None:
		p = figure(plot_width =width, plot_height=height, x_axis_label=x_label, y_axis_label=y_label, title=title)
		p.add_tools(CrosshairTool())
	else:
		p = fig

	df = data.fillna(0)
	df = df[df.index.notnull()]
	p.vbar(x=df.index.tolist(), width=1, top=df.values.tolist(), color= color)
	if show_figure:
		show(p, notebook_handle)
	if return_figure:
		return p
def hover(hover_color="#03F0F7"):
	return dict(selector="tr:hover", props=[("background-color","%s"% hover_color)])

def hover_col(hover_color = "#F3A60C"):
	return dict(selector="td:hover", props=[("background-color","%s"% hover_color),('max-width','200px'), ('front-size','12pt')])

def highlight_nonzero(s, threshold, column):
	is_max = pd.Series(data= False, index= s.index)
	is_max[column]= abs(s.loc[column])>=threshold

	return ['background-color:yellow' if is_max.any() else '' for v in is_max]

def highlight_nonzero(s, column, color='red'):

	is_true = pd.Series(data= False, index= s.index)
	is_true[column]= s.loc[column]

	return ['background-color: {}'.format(color) if is_true.any() else '' for v in is_true]





