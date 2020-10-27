clear

print_sel = true;
symbol_pool_all = yq_methods.get_symbol_A();
T_symbol_pool_all = length(symbol_pool_all);

t0 = datetime;
run_mod = 'f';
parfor i = 1:T_symbol_pool_all
    dos_str = sprintf('python M_TD_update1.py %s %s a_stock',symbol_pool_all{i},run_mod);
    %sprintf(dos_str)
    dos(dos_str)
end

tt = datetime;

tt-t0
