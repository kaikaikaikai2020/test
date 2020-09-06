%S19和S21需要运行两个python程序，需要记录路径参数

clear
error_recorder = strAdd('错误记录');

obj = bac_tool_S37();
%每增加一个，必须先创建symbol表格
obj.create_tables_S37();
obj.create_group_return_result_table();
%做两个接口，一个写如数据库，一个计算并写入word
method_id1 = {'36','33','32','30','23','23_1','23_2','22'};
for i = 1:length(method_id1)
    try
        eval(sprintf('obj.select_symbols_S%s();',method_id1{i}))
        eval(sprintf('obj.get_group_return_S%s();',method_id1{i}))
        eval(sprintf('obj.write_S%s_report();',method_id1{i}))
    catch e_info
        sprintf(e_info.message)
        T = length(e_info);
        for j = 1:T
            e_str = sprintf('Error \n File: %s\n Name: %s\n Line: %d ',...
                e_info.stack(j).file,e_info.stack(j).name,e_info.stack(j).line);
            error_recorder.A(e_str);
        end
    end
end

try
    obj.write_S26_report();
catch e_info
    sprintf(e_info.message)
    T = length(e_info);
    for j = 1:T
        e_str = sprintf('Error \n File: %s\n Name: %s\n Line: %d ',...
            e_info.stack(j).file,e_info.stack(j).name,e_info.stack(j).line);
        error_recorder.A(e_str);
    end
end
method_id2 = {'13','11','5','14','24','31','28','19','7','34','38','39',...
    '29','40','43','45','46','42','49','50','51','52','53'};
for i = 1:length(method_id2)
    try
        obj1=eval(sprintf('bac_result_S%s();',method_id2{i}));
        obj1.get_all_results();
        if strcmp(method_id2{i},'46')
            obj1=eval(sprintf('bac_result_S%s_2();',method_id2{i}));
            obj1.get_all_results();
        end
    catch e_info
        sprintf(e_info.message)
        T = length(e_info);
        for j = 1:T
            e_str = sprintf('Error \n File: %s\n Name: %s\n Line: %d ',...
                e_info.stack(j).file,e_info.stack(j).name,e_info.stack(j).line);
            error_recorder.A(e_str);
        end
    end
end

error_info = error_recorder.batch_cell_str(error_recorder.str1);
disp(error_info)