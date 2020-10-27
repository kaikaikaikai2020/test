clear
%结果验证部分
title_str = 'A股只多框架验证';
order_str = 'M_a_stock_sta';
run_program_adair(order_str,title_str);

title_str = 'A股指数成分股组合结果验证-多';
order_str = 'M_a_stock_com1';
run_program_adair(order_str,title_str);

title_str = 'A股指数成分股组合结果验证-多空';
order_str = 'M_a_stock_com2';
run_program_adair(order_str,title_str);

title_str = '指数多空框架验证';
order_str = 'M_index_sta';
run_program_adair(order_str,title_str);

title_str = '国内期货';
order_str = 'M_cf_future_sta';
run_program_adair(order_str,title_str);


title_str = '外汇多空框架验证';
order_str = 'M_exchange_sta';
run_program_adair(order_str,title_str);

title_str = 'dowjones指成分股-多';
order_str = 'M_dowjones_stock_lo_sta';
run_program_adair(order_str,title_str);

title_str = 'dowjones指成分股-多空';
order_str = 'M_exchange_sta';
run_program_adair(order_str,title_str);

title_str = '美股-寻优参数-多空';
order_str = 'M_american_stock_sta';
run_program_adair(order_str,title_str);

title_str = '美股-经典固定参数-多空';
order_str = 'M_american_stock_classic_sta';
run_program_adair(order_str,title_str);

%M_american_stock_classic_com_sta
title_str = '美股-经典固定参数-组合';
order_str = 'M_american_stock_classic_com_sta';
run_program_adair(order_str,title_str);