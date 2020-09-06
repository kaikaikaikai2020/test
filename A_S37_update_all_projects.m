%一键升级所有的程序
%载入路径参数
load S37_para.mat

methods_list = {'S5';'S7';'S11';'S13';'S14';'S17';'S19';'S22';'S23';...
    'S24';'S26';'S28';'S29';'S30';'S31';'S32';'S33';'S34';'S36'};

run_orders = containers.Map(methods_list,{'A_S5_ON_flowchart','A_S7_ON_flowchart','S11_ON_hurst_signal',...
    'A_S13_ON_flowchart','A_S14_ON_flowchart','A_S17_ON_signal','A_S19_21_ON_flowchart',...
    'A_S22_ON_flowchart','A_S23_ON_flowchart','A_S24_ON_flowchart',...
    'A_S26_ON_update','A_S28_ON_flowchart','A_S29_ON_flowchart',...
    'A_S30_ON_flowchart','A31_ON_flowchart','A_S32_ON_flowchart',...
    'A_S33ON_update','A_S34ON_update','A_S36ON_update'});

T = length(methods_list);
pn0 = pwd;
error_recorder = strAdd('错误记录');

for i = 1:T
    order_path = S37_dir.(methods_list{i});
    %运行程序
    e_str = try_methods(order_path,pn0,run_orders(methods_list{i}));
    error_recorder.A(e_str);
end

e_str = try_methods(pn0,pn0,'A_S37_flowchart');
error_recorder.A(e_str)
cd(pn0);

error_info = error_recorder.batch_cell_str(error_recorder.str1);
disp(error_info)