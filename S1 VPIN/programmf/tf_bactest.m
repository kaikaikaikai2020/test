classdef tf_bactest < handle
    methods(Static)
        function [y,orders] = simu_bac_method(index,price,fee,t,print_sel)
            if nargin < 4
                t = num2cell(1:size(index,1));
                t = cellfun(@num2str,t,'UniformOutput',false);
            end
            if nargin< 5
                print_sel = 0;
            end
            f_str1 = containers.Map([1,-1,0],{'平多','平空','空空'});
            f_str2 = containers.Map([1,-1],{'持多','持空'});
            scale_val = 300;
            T = length(index);
            y = zeros(T,1);
            orders = cell(T,1);
            for i = 2:T-1
                if eq(index(i),0)
                    %发出空信号
                    if eq(index(i),index(i-1))
                        y(i+1) = 0;
                        orders{i+1} = sprintf('%s,signal:%d,price:%0.2f,order: 0',t{i},index(i),price(i+1,1));
                    else
                        y(i+1) = (price(i+1,1)-price(i,1))*index(i-1)*scale_val;
                        y(i+1) = y(i+1)*-abs(y(i+1))*fee;
                        orders{i+1} = sprintf('%s,signal:%d,price:%0.2f,order: %s, 收益, %0.2f',t{i},index(i),price(i+1,1),f_str1(index(i-1)),y(i+1));
                    end                   
                else
                    if eq(index(i,1),index(i-1))
                        y(i+1) = (price(i+1,1)-price(i,1))*index(i)*scale_val;
                        orders{i} = sprintf('%s,signal:%d,price:%0.2f,order: %s, 收益, %0.2f',t{i},index(i),price(i+1,1),f_str2(index(i-1)),y(i+1));
                    else
                        %清
                        y(i+1) = (price(i+1,1)-price(i,1))*index(i-1)*scale_val;
                        y(i+1) = y(i+1)-abs(y(i+1))*fee;
                        orders{i} = sprintf('%s,signal:%d,price:%0.2f,order: %s, 收益, %0.2f',t{i},index(i),price(i+1,1),f_str1(index(i-1)),y(i+1));
                    end
                end
            end
            if print_sel>0
                for i = 1:T
                    if ischar(orders{i})
                        sprintf(orders{i})
                    end
                end
            end
        end
    end
    
    
end