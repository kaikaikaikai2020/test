%计算收益
function [re,pos_re,re_detail] =sta_get_position(sta_results)
    cash0 = 100000;
    T = size(sta_results,1);
    re = zeros(T,1);
    sta_results(isnan(sta_results(:,6)),6) = 0;
    pos_re = zeros(T,3);
    pos_re(1,1) = cash0;
    for i = 2:T
        sub_s0 =sta_results(i-1,6); 
        sub_s = sta_results(i,6);
        sub_beta = sta_results(i,2);
        
        sub_x = (sta_results(i,7:8)-sta_results(i-1,7:8))./sta_results(i-1,7:8);%当日收益率
        if any(isnan(sub_x)) || any(isinf(sub_x))
            %停牌
            pos_re(i,1) = sum(pos_re(i-1,:));
            sta_results(i,6) = 0; %修正信号
            continue
        end

        if eq(sub_s,1)%多信号
            if  eq(sub_s0,0)%昨日为空
                %建模日，无收益
                re(i) = 0;
                pos_re(i,:) = set_model(pos_re,sub_beta,i);
            elseif eq(sub_s0,-1)
                %清仓，计算收益
                re(i) = sub_x(1)*-sub_s+sub_x(2)*sub_s;
                pos_re(i,1) = remove_position(pos_re,i,sub_x,sub_s);
                %再建仓
                pos_re(i,:)=set_model_now(pos_re,sub_beta,i);
            else
                %持有收益
                re(i) = sub_x(1)*-sub_s+sub_x(2)*sub_s;
                pos_re(i,:) = update_position2(pos_re,i,sub_x,sub_s);
            end
        elseif eq(sub_s,-1) %做空信号
            if eq(sub_s0,0)%昨日为空
                %建仓日，无收益
                re(i) = 0;
                pos_re(i,:) = set_model(pos_re,sub_beta,i);
            elseif eq(sub_s0,1)
                %清仓收益
                re(i) = sub_x(1)*-sub_s+sub_x(2)*sub_s;
                pos_re(i,1) = remove_position(pos_re,i,sub_x,sub_s);
                %再建仓
                pos_re(i,:)=set_model_now(pos_re,sub_beta,i);
            else
                %计算收益
                re(i) = sub_x(1)*-sub_s+sub_x(2)*sub_s;
                pos_re(i,:) = update_position2(pos_re,i,sub_x,sub_s);
            end
        else %空信号
            if ~eq(sub_s0,0) %昨日有仓
                re(i) = sub_x(1)*-sub_s+sub_x(2)*sub_s;         %平仓   
                pos_re(i,1) = remove_position(pos_re,i,sub_x,sub_s);
            else
                re(i) = 0; %继续空，无收益
                pos_re(i,:) = pos_re(i-1,:);
            end               
        end

    end
    re_detail = [sta_results(:,[2,6:8]),pos_re];
end
%空仓-建仓
function re = set_model(pos_re,sub_beta,i)
    re = [0,pos_re(i-1,1)*[1,sub_beta]./(1+sub_beta)];
end
%清仓-建仓
function re = set_model_now(pos_re,sub_beta,i)
    re = [0,pos_re(i,1)*[1,sub_beta]./(1+sub_beta)];
end
%清仓
function re = remove_position(pos_re,i,sub_x,sub_s)
    re = pos_re(i-1,2)*(1+sub_x(1)*-sub_s)+pos_re(i-1,3)*(1+sub_x(2)*sub_s);
end
%统计仓位
function re = update_position2(pos_re,i,sub_x,sub_s)
re = [0,pos_re(i-1,2)*(1+sub_x(1)*-sub_s),pos_re(i-1,3)*(1+sub_x(2)*sub_s)];
end