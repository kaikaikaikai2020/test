%ʹ�þ���ģ�ͼ������ɽ��
clear

print_sel = true;
symbol_pool_all = fetchmysql('select distinct(symbol) from  us_stock.us_stock_daytick',2);
T_symbol_pool_all = length(symbol_pool_all);

for sel = 1
    if eq(sel,0)
        run_mod = 'm';
    else
        run_mod = 'f';
    end

    parfor i = 1:T_symbol_pool_all
        dos_str = sprintf('python M_TD_update1.py %s %s american_stock_classic',symbol_pool_all{i},run_mod);
        %sprintf(dos_str)
        dos(dos_str)
    end
end