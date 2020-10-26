clear
%执行部分，预估时间需要运行1整天
%数据已经写入数据库，如果没有数据更新请不要运行这个程序，可以根据程序查看流程。
%逻辑是matlab-python方法-结果写入数据库
title_str = 'A股计算-多';
order_str = 'M_a_stock';
run_program_adair(order_str,title_str);

title_str = 'A股指数计算-多空';
order_str = 'M_a_stock_ef';
run_program_adair(order_str,title_str);


title_str = '指数多空计算';
order_str = 'M_index_test';
run_program_adair(order_str,title_str);

title_str = '国内期货';
order_str = 'M_cf_future';
run_program_adair(order_str,title_str);


title_str = '外汇计算';
order_str = 'M_exchange';
run_program_adair(order_str,title_str);

title_str = 'dowjones-优化方法（效果不明显）';
order_str = 'M_com_dowjones';
run_program_adair(order_str,title_str);

title_str = 'dowjones-经典方法';
order_str = 'M_dowjones_stock_classic';
run_program_adair(order_str,title_str);

title_str = '美股-寻优参数-多空';
order_str = 'M_american_stock';
run_program_adair(order_str,title_str);

title_str = '美股-经典固定参数-多空';
order_str = 'M_american_stock_classic';
run_program_adair(order_str,title_str);
