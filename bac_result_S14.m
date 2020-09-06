classdef bac_result_S14 < handle
    properties
        para
        
    end
    methods
        function ini_S14(obj)
            key_str = 'S14策略';
            %t0 = '2005-01-01';
            %tref = yq_methods.get_tradingdate(t0,datestr(now,'yyyy-mm-dd'));
            tref = fetchmysql('select distinct(tradedate) from yuqerdata.yq_MktMFutdGet where tradeDate>=''2005-01-01''',2);
            tref_num = datenum(tref);

            %list
            %获取品种
            sql_str = ['select exchangeCD,contractObject,secShortName,contMultNum from ',...
                ' yuqerdata.yq_FutuGet where exchangeCD in (''XDCE'',''XSGE'',''XZCE'')'];
            x = fetchmysql(sql_str,2);
            y = cellfun(@(x,y) [x,'.',y],x(:,1),x(:,2),'UniformOutput',false);
            [y,ia] = unique(y);
            x = x(ia,:);

            sql_str2 = ['select exchangeCD,contractObject from yuqerdata.yq_MktMFutdGet ',...
                ' where exchangeCD in (''XDCE'',''XSGE'',''XZCE'') and tradeDate = ''%s''',...
                ' and mainCon=1'];
            x1 = fetchmysql(sprintf(sql_str2,tref{end}),2);
            y1 = cellfun(@(x,y) [x,'.',y],x1(:,1),x1(:,2),'UniformOutput',false);
            [symbol0,ia] = intersect(y,y1);
            x = x(ia,:);
            sy_info0 = x(:,3);
            T = length(sy_info0);
            for i = 1:T
                sub_ind = isletter(sy_info0{i});
                sy_info0{i} = sy_info0{i}(sub_ind);
            end
            M = cell2mat(x(:,4));
            T = length(symbol0);

            %这段需要修改为并行
            y_re = zeros(length(tref),T);
            vol_re = y_re;
            r_re1 = y_re;
            r_re2 = y_re;
            r_re3 = y_re;
            r_re4 = y_re;
            r_re5 = y_re;
            close_price = y_re;
            close_price_r = y_re;

            temp_re1 = cell(T,1);
            temp_re2 = temp_re1;
            temp_re3 = temp_re1;
            temp_re4 = temp_re1;
            temp_re5 = temp_re1;
            temp_y_re = temp_re1;
            temp_vol_re = temp_re1;
            temp_close_price = temp_re1;
            temp_close_price_r = temp_re1;

            parfor symbol_sel = 1:T
                symbol = symbol0{symbol_sel};
                sy_info = sy_info0{symbol_sel};

                symbol = strsplit(symbol,'.');
                [cash_flow,sub_tref]=get_bac_data_yuqer_update(symbol,M(symbol_sel),0.2);

                [~,ia] = intersect(tref_num,sub_tref,'stable');
                %y_re(ia,symbol_sel) = [0;cash_flow(2:end)./cash_flow(1:end-1)-1];
                temp_y_re{symbol_sel} = [ia,[0;cash_flow(2:end)./cash_flow(1:end-1)-1]];

                [v,sub_tref2] = get_vol_data(symbol);
                [~,ib] = intersect(tref_num,sub_tref2,'stable');
                %vol_re(ib,symbol_sel) = movmean(v,[20,0]);
                temp_vol_re{symbol_sel} = [ib,movmean(v,[20,0])];

                [r,sub_tref3,sub_close_price] = get_momentum(symbol,40);
                [~,ib,ia] = intersect(tref_num,sub_tref3,'stable');
                %r_re1(ib,symbol_sel) = r(ia);
                %close_price(ib,symbol_sel) = sub_close_price(ia,1);
                %close_price_r(ib,symbol_sel) = sub_close_price(ia,2);
                temp_re1{symbol_sel} = [ib,r(ia)];
                temp_close_price{symbol_sel} = [ib,sub_close_price(ia,1)];
                temp_close_price_r{symbol_sel} = [ib,sub_close_price(ia,2)];
                [r,sub_tref3] = get_sectional_momentum(symbol,40);
                [~,ib,ia] = intersect(tref_num,sub_tref3,'stable');
                %r_re2(ib,symbol_sel) = r(ia);
                temp_re2{symbol_sel} = [ib,r(ia)];

                [r,sub_tref3] = get_roll_return_yq(symbol,4);
                [~,ib,ia] = intersect(tref_num,sub_tref3,'stable');
                %r_re3(ib,symbol_sel) = r(ia);
                temp_re3{symbol_sel} = [ib,r(ia)];

                [r,sub_tref3] = get_basismomentum_return(symbol,120);
                [~,ib,ia] = intersect(tref_num,sub_tref3,'stable');
                %r_re4(ib,symbol_sel) = r(ia);
                temp_re4{symbol_sel} = [ib,r(ia)];

                [r,sub_tref3] = get_warehouse(symbol,90);
                [~,ib,ia] = intersect(tref_num,sub_tref3,'stable');
                %r_re5(ib,symbol_sel) = -r(ia);
                temp_re5{symbol_sel} = [ib,-r(ia)];

                sprintf('%s 载入数据: %d-%d',key_str,symbol_sel,T)
            end
            for symbol_sel = 1:T
                sub_re1 = temp_re1{symbol_sel};
                r_re1(sub_re1(:,1),symbol_sel) = sub_re1(:,2);

                sub_re = temp_re2{symbol_sel};
                r_re2(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_re3{symbol_sel};
                r_re3(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_re4{symbol_sel};
                r_re4(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_re5{symbol_sel};
                r_re5(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_y_re{symbol_sel};
                y_re(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_vol_re{symbol_sel};
                vol_re(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_close_price{symbol_sel};
                close_price(sub_re(:,1),symbol_sel) = sub_re(:,2);

                sub_re = temp_close_price_r{symbol_sel};
                close_price_r(sub_re(:,1),symbol_sel) = sub_re(:,2);
            end
%             [sub_w{1},k_score{1}] = get_volitylity_signal(tref,y_re,r_re1,r_re2,r_re3,r_re4,r_re5,vol_re,close_price,close_price_r);
%             %多因子打分
%             [sub_w{2},k_score{2}]  = get_score_signal(tref,y_re,r_re2,r_re3,r_re4,r_re5,vol_re);
%             %3因子1/K加权
%             [sub_w{3},k_score{3}]  = get_idiosyncractic_signal(tref,y_re,r_re1,r_re2,r_re3,r_re4,r_re5,vol_re);
%             %5因子1/K加权法
%             [sub_w{4},k_score{4}]  = get_1K_signal(tref,y_re,r_re1,r_re2,r_re3,r_re4,r_re5,vol_re);
            obj.para.tref = tref;
            obj.para.tref_num = datenum(tref);
            obj.para.y_re = y_re;
            obj.para.r_re1 = r_re1;
            obj.para.r_re2 = r_re2;
            obj.para.r_re3 = r_re3;
            obj.para.r_re4 = r_re4;
            obj.para.r_re5 = r_re5;
            obj.para.vol_re = vol_re;
            obj.para.close_price = close_price;
            obj.para.close_price_r = close_price_r;
            
        end
        function get_all_results(obj)
            obj.ini_S14()
            methods = {'复合信号策略策略','多因子打分','3因子1/K加权','5因子1/K加权法'};
            file_name = sprintf('S14FICC集成方法%s',datestr(now,'yyyy-mm-dd'));
            
            pn0 = fullfile(pwd,'计算结果');
            if ~exist(pn0,'dir')
                mkdir(pn0);
            end
            
            obj_wd = wordcom(fullfile(pn0,sprintf('%s.doc',file_name)));
            [h,v,v_str0] = obj.bac_volitylity_S14();
            [v,v_str] = ad_trans_sta_info(v,v_str0); 
            temp = [[{sprintf('%s万3','S14FICC')};v_str'],[methods(1);v']];
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');            
            
            [h,v1] = obj.bac_score_S14();
            v1 = ad_trans_sta_info(v1,v_str0); 
            temp = cat(2,temp,[methods(2);v1']);
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');
                        
            [h,v2] = obj.bac_idiosyncractic_S14();
            v2 = ad_trans_sta_info(v2,v_str0);
            temp = cat(2,temp,[methods(3);v2']);
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');
            
            [h,v3] = obj.bac_1K_S14();
            v3 = ad_trans_sta_info(v3,v_str0);
            temp = cat(2,temp,[methods(4);v3']);
            setpixelposition(h,[223,365,1345,420]);
            obj_wd.pasteFigure(h,' ');
            obj_wd.CloseWord()
            
            temp = temp';
            
            xlstocsv_adair(fullfile(pn0,sprintf('%s.xlsx',file_name)),temp)            
        end
        
    end
    methods
        function [h,v,v_str]  =bac_volitylity_S14(obj)
            key_str = '复合信号策略策略';
            sigma_targ = 0.1;
            mod = 5;%3因子还是5因子
            R = 30;
            H = 10;
            %这段需要修改为并行
            tref = obj.para.tref;
            tref_num = obj.para.tref_num;
            %这段需要修改为并行
            y_re = obj.para.y_re;
            vol_re = obj.para.vol_re;
            r_re1 = obj.para.r_re1;
            r_re2 = obj.para.r_re2;
            r_re3 = obj.para.r_re3;
            r_re4 = obj.para.r_re4;
            r_re5 = obj.para.r_re5;
            close_price = obj.para.close_price;
            close_price_r = obj.para.close_price_r;
            %com
            T_tref = length(tref);
            m_num = 5;
            m_num_2 = floor(H/m_num);
            y_bac = zeros(T_tref,m_num);
            ind_ini = find(sum(y_re,2),1);
            if ind_ini<R
                ind_ini = (R+1);
            end
            for i0 = 1:m_num
                for i = ind_ini+(i0-1)*m_num_2:H:T_tref
                    %1/K
                    %选定数据
                    ind_sel0 = find(~eq(y_re(i,:),0)&vol_re(i,:)>10000);

                    sub_r2 = r_re2(i-1,ind_sel0);
                    sub_r3 = r_re3(i-1,ind_sel0);
                    sub_r4 = r_re4(i-1,ind_sel0);
                    [~,ia2] = sort(sub_r2);
                    [~,ia3] = sort(sub_r3);
                    [~,ia4] = sort(sub_r4);
                    sub_r5 = r_re5(i-1,ind_sel0);
                    [~,ia5] = sort(sub_r5);
                    sub_r1 = r_re1(i-1,ind_sel0);
                    [~,ia1] = sort(sub_r1);

                    k_score = zeros(size(y_re(1,:)));
                    for j = 1:mod
                        ia = eval(sprintf('ia%d',j));
                        if eq(j,1)
                            k_score(ia>0) = 1;
                            k_score(ia<0) = -1;
                        else
                            if length(ia)>=5
                                num1 = floor(length(ia)*0.2);
                                ia1 = ia(1:num1);
                                ind_sel1 = ind_sel0(ia1);
                                ia2 = ia(end-num1+1:end);
                                ind_sel2 = ind_sel0(ia2);
                                k_score(ind_sel1) = k_score(ind_sel1)-1;
                                k_score(ind_sel2) = k_score(ind_sel2)+1;
                            end
                        end            
                    end

                    ind_sel1 = find(k_score<0);
                    ind_sel2 = find(k_score>0);

                    %归一化多、空权重
                    sub_w = zeros(size(k_score));
                    sub_w(k_score>0) = k_score(k_score>0)./sum(k_score(k_score>0));
                    sub_w(k_score<0) = k_score(k_score<0)./sum(k_score(k_score<0));
                    if i > 300
                        sub_w0 = sub_w;
                        %调整权重
                        sub_x = y_re(i-240:i,:);
                        sigma_s = std(close_price_r(i-240:i,:))./mean(close_price(i-240:i,:));
                        %less
                        v1 = 0;
                        for j = 1:length(ind_sel1)
                            sub_sub_x = sub_x(:,ind_sel1);
                            sub_v1 = sub_w(ind_sel1(j)).*sub_w(ind_sel1).*corr(sub_sub_x(:,j),sub_sub_x);
                            sub_v1 = -sub_v1(j) + sum(sub_v1);
                            v1 = v1 + sub_v1;
                        end
                        sub_w(ind_sel1) = sigma_targ*sub_w(ind_sel1)./(sigma_s(ind_sel1)*sqrt(sum(sub_w(ind_sel1).^2)+2*v1));
                        %more
                        v2 = 0;
                        for j = 1:length(ind_sel2)
                            sub_sub_x = sub_x(:,ind_sel2);
                            sub_v1 = sub_w(ind_sel2(j)).*sub_w(ind_sel2).*corr(sub_sub_x(:,j),sub_sub_x);
                            sub_v1 = -sub_v1(j) + sum(sub_v1);
                            v2 = v2 + sub_v1;
                        end
                        sub_w(ind_sel2) = sigma_targ*sub_w(ind_sel2)./(sigma_s(ind_sel2)*sqrt(sum(sub_w(ind_sel2).^2)+2*v2));

                        if any(isnan(sub_w(ind_sel1)))
                            sub_w(ind_sel1) = sub_w0(ind_sel1);
                        end
                        if any(isnan(sub_w(ind_sel2)))
                            sub_w(ind_sel2) = sub_w0(ind_sel2);
                        end

                        sub_w(ind_sel1) = sub_w(ind_sel1)/sum(sub_w(ind_sel1));
                        sub_w(ind_sel2) = sub_w(ind_sel2)/sum(sub_w(ind_sel2));

                    end
                    %获取收益率数据,并平均
                    sub_ind = i:(i+H-1);
                    sub_ind(sub_ind>T_tref) = [];
                    %多
                    sub_y_r_m = y_re(sub_ind,ind_sel2);    
                    %手续费
                    sub_y_r_m(1,:) = sub_y_r_m(1,:)-3/10000;
                    sub_y_r_m(end,:) = sub_y_r_m(end,:)-3/10000;
                    temp = sub_w(ind_sel2).*cumprod((1+sub_y_r_m));
                    temp = [1;sum(temp,2)];
                    temp_m = temp(2:end)./temp(1:end-1)-1;
                    if ~isempty(ind_sel1)
                        %空
                        sub_y_r = y_re(sub_ind,ind_sel1);    
                        %手续费
                        sub_y_r([1,end],:) = sub_y_r([1,end],:);
                        temp = sub_w(ind_sel1).*cumprod((1+sub_y_r));
                        temp = [1;sum(temp,2)];
                        temp = temp(2:end)./temp(1:end-1)-1;
                    else
                        temp=0;
                    end
                    y_bac(sub_ind,i0) = temp_m-temp;

                end
            end
            ind = tref_num>datenum(2010,1,1);
            y_bac1 = y_bac(ind,:);
            tref_num1 = tref_num(ind);

            y_bac_t = 1/m_num*cumprod(y_bac1+1);
            y_bac_t = sum(y_bac_t,2);
            bpcure_plot_updateV2(tref_num1,y_bac_t);
            title(key_str);
            [v,v_str] = curve_static(y_bac_t);
            h = gcf;
        end
        %%%%%%%%%
        function [h,v,v_str]  = bac_score_S14(obj)
            key_str = '多因子打分';

            mod = 4;%3因子还是5因子
            R = 30;
            H = 30;

            
            tref = obj.para.tref;
            tref_num = obj.para.tref_num;
            %这段需要修改为并行
            y_re = obj.para.y_re;
            vol_re = obj.para.vol_re;
            r_re1 = obj.para.r_re1;
            r_re2 = obj.para.r_re2;
            r_re3 = obj.para.r_re3;
            r_re4 = obj.para.r_re4;
            r_re5 = obj.para.r_re5;
            %com
            T_tref = length(tref);
            m_num = 5;
            m_num_2 = floor(H/m_num);
            y_bac = zeros(T_tref,m_num);
            ind_ini = find(sum(y_re,2),1);
            if ind_ini<R
                ind_ini = (R+1);
            end
            for i0 = 1:m_num
                for i = ind_ini+(i0-1)*m_num_2:H:T_tref
                    %选定数据
                    ind_sel0 = find(~eq(y_re(i,:),0)&vol_re(i,:)>10000);
                    sub_r1 = r_re2(i-1,ind_sel0);
                    sub_r2 = r_re3(i-1,ind_sel0);
                    sub_r3 = r_re4(i-1,ind_sel0);
                    [~,ia1] = sort(sub_r1);
                    [~,ia2] = sort(sub_r2);
                    [~,ia3] = sort(sub_r3);        
                    if eq(mod,3)
                        sub_r = ia1+ia2+ia3;
                    else
                        sub_r4 = r_re5(i-1,ind_sel0);
                        [~,ia4] = sort(sub_r4);
                        sub_r = ia1+ia2+ia3+ia4;
                    end

                    if length(sub_r)>5
                        [~,ia] = sort(sub_r);
                        num1 = floor(length(ia)*0.2);
                        ia1 = ia(1:num1);
                        ind_sel1 = ind_sel0(ia1);
                        ia2 = ia(end-num1+1:end);
                        ind_sel2 = ind_sel0(ia2);
                    else
                        ind_sel1 = [];
                        ind_sel2 = ind_sel0;

                    end    

                    %获取收益率数据,并平均
                    sub_ind = i:(i+H-1);
                    sub_ind(sub_ind>T_tref) = [];

                    %多
                    sub_y_r_m = y_re(sub_ind,ind_sel2);    
                    %手续费
                    sub_y_r_m(1,:) = sub_y_r_m(1,:)-3/10000;
                    sub_y_r_m(end,:) = sub_y_r_m(end,:)-3/10000;
                    temp = 1/size(sub_y_r_m,2)*cumprod((1+sub_y_r_m));
                    temp = [1;sum(temp,2)];
                    temp_m = temp(2:end)./temp(1:end-1)-1;
                    if ~isempty(ind_sel1)
                        %空
                        sub_y_r = y_re(sub_ind,ind_sel1);    
                        %手续费
                        sub_y_r([1,end],:) = sub_y_r([1,end],:);
                        temp = 1/size(sub_y_r,2)*cumprod((1+sub_y_r));
                        temp = [1;sum(temp,2)];
                        temp = temp(2:end)./temp(1:end-1)-1;
                    else
                        temp=0;
                    end
                    y_bac(sub_ind,i0) = temp_m-temp;
                end
            end
            ind = tref_num>datenum(2010,1,1);
            y_bac1 = y_bac(ind,:);
            tref_num1 = tref_num(ind);

            y_bac_t = 1/m_num*cumprod(y_bac1+1);
            y_bac_t = sum(y_bac_t,2);
            bpcure_plot_updateV2(tref_num1,y_bac_t);
            title(key_str);
            [v,v_str] = curve_static(y_bac_t);  
            h = gcf;
        end
        function [h,v,v_str] = bac_idiosyncractic_S14(obj)
            key_str = '3因子1/K加权';

            mod = 3;%3因子还是5因子
            R = 30;
            H = 10;

            tref = obj.para.tref;
            tref_num = obj.para.tref_num;
            %这段需要修改为并行
            y_re = obj.para.y_re;
            vol_re = obj.para.vol_re;
            r_re1 = obj.para.r_re1;
            r_re2 = obj.para.r_re2;
            r_re3 = obj.para.r_re3;
            r_re4 = obj.para.r_re4;
            r_re5 = obj.para.r_re5;
            
            %com
            T_tref = length(tref);
            m_num = 5;
            m_num_2 = floor(H/m_num);
            y_bac = zeros(T_tref,m_num);
            ind_ini = find(sum(y_re,2),1);
            if ind_ini<R
                ind_ini = (R+1);
            end
            for i0 = 1:m_num
                for i = ind_ini+(i0-1)*m_num_2:H:T_tref
                    %1/K
                    %选定数据
                    ind_sel0 = find(~eq(y_re(i,:),0)&vol_re(i,:)>10000);

                    sub_r2 = r_re2(i-1,ind_sel0);
                    sub_r3 = r_re3(i-1,ind_sel0);
                    sub_r4 = r_re4(i-1,ind_sel0);
                    [~,ia2] = sort(sub_r2);
                    [~,ia3] = sort(sub_r3);
                    [~,ia4] = sort(sub_r4);
                    sub_r5 = r_re5(i-1,ind_sel0);
                    [~,ia5] = sort(sub_r5);
                    sub_r1 = r_re1(i-1,ind_sel0);
                    [~,ia1] = sort(sub_r1);

                    k_score = zeros(size(y_re(1,:)));
                    for j = 1:mod
                        ia = eval(sprintf('ia%d',j));
                        if eq(j,1)
                            k_score(ia>0) = 1;
                            k_score(ia<0) = -1;
                        else
                            if length(ia)>=5
                                num1 = floor(length(ia)*0.2);
                                ia1 = ia(1:num1);
                                ind_sel1 = ind_sel0(ia1);
                                ia2 = ia(end-num1+1:end);
                                ind_sel2 = ind_sel0(ia2);
                                k_score(ind_sel1) = k_score(ind_sel1)-1;
                                k_score(ind_sel2) = k_score(ind_sel2)+1;
                            end
                        end            
                    end

                    ind_sel1 = find(k_score<0);
                    ind_sel2 = find(k_score>0);

                    %归一化多、空权重
                    sub_w = zeros(size(k_score));
                    sub_w(k_score>0) = k_score(k_score>0)./sum(k_score(k_score>0));
                    sub_w(k_score<0) = k_score(k_score<0)./sum(k_score(k_score<0));

                    %获取收益率数据,并平均
                    sub_ind = i:(i+H-1);
                    sub_ind(sub_ind>T_tref) = [];
                    %多
                    sub_y_r_m = y_re(sub_ind,ind_sel2);    
                    %手续费
                    sub_y_r_m(1,:) = sub_y_r_m(1,:)-3/10000;
                    sub_y_r_m(end,:) = sub_y_r_m(end,:)-3/10000;
                    temp = sub_w(ind_sel2).*cumprod((1+sub_y_r_m));
                    temp = [1;sum(temp,2)];
                    temp_m = temp(2:end)./temp(1:end-1)-1;
                    if ~isempty(ind_sel1)
                        %空
                        sub_y_r = y_re(sub_ind,ind_sel1);    
                        %手续费
                        sub_y_r([1,end],:) = sub_y_r([1,end],:);
                        temp = sub_w(ind_sel1).*cumprod((1+sub_y_r));
                        temp = [1;sum(temp,2)];
                        temp = temp(2:end)./temp(1:end-1)-1;
                    else
                        temp=0;
                    end
                    y_bac(sub_ind,i0) = temp_m-temp;
                end
            end
            ind = tref_num>datenum(2010,1,1);
            y_bac1 = y_bac(ind,:);
            tref_num1 = tref_num(ind);

            y_bac_t = 1/m_num*cumprod(y_bac1+1);
            y_bac_t = sum(y_bac_t,2);
            bpcure_plot_updateV2(tref_num1,y_bac_t);
            title(key_str)
            [v,v_str] = curve_static(y_bac_t);
            h=gcf;
        end
        function [h,v,v_str]  = bac_1K_S14(obj)
            key_str = '5因子1/K加权法';

            mod = 5;%3因子还是5因子
            R = 30;
            H = 10;

            %t0 = '2005-01-01';
            %tref = yq_methods.get_tradingdate(t0,datestr(now,'yyyy-mm-dd'));
            tref = obj.para.tref;
            tref_num = obj.para.tref_num;
            %这段需要修改为并行
            y_re = obj.para.y_re;
            vol_re = obj.para.vol_re;
            r_re1 = obj.para.r_re1;
            r_re2 = obj.para.r_re2;
            r_re3 = obj.para.r_re3;
            r_re4 = obj.para.r_re4;
            r_re5 = obj.para.r_re5;

            %com
            T_tref = length(tref);
            m_num = 5;
            m_num_2 = floor(H/m_num);
            y_bac = zeros(T_tref,m_num);
            ind_ini = find(sum(y_re,2),1);
            if ind_ini<R
                ind_ini = (R+1);
            end
            for i0 = 1:m_num
                for i = ind_ini+(i0-1)*m_num_2:H:T_tref
                    %1/K
                    %选定数据
                    ind_sel0 = find(~eq(y_re(i,:),0)&vol_re(i,:)>10000);

                    sub_r2 = r_re2(i-1,ind_sel0);
                    sub_r3 = r_re3(i-1,ind_sel0);
                    sub_r4 = r_re4(i-1,ind_sel0);
                    [~,ia2] = sort(sub_r2);
                    [~,ia3] = sort(sub_r3);
                    [~,ia4] = sort(sub_r4);
                    sub_r5 = r_re5(i-1,ind_sel0);
                    [~,ia5] = sort(sub_r5);
                    sub_r1 = r_re1(i-1,ind_sel0);
                    [~,ia1] = sort(sub_r1);

                    k_score = zeros(size(y_re(1,:)));
                    for j = 1:mod
                        ia = eval(sprintf('ia%d',j));
                        if eq(j,1)
                            k_score(ia>0) = 1;
                            k_score(ia<0) = -1;
                        else
                            if length(ia)>=5
                                num1 = floor(length(ia)*0.2);
                                ia1 = ia(1:num1);
                                ind_sel1 = ind_sel0(ia1);
                                ia2 = ia(end-num1+1:end);
                                ind_sel2 = ind_sel0(ia2);
                                k_score(ind_sel1) = k_score(ind_sel1)-1;
                                k_score(ind_sel2) = k_score(ind_sel2)+1;
                            end
                        end            
                    end

                    ind_sel1 = find(k_score<0);
                    ind_sel2 = find(k_score>0);

                    %归一化多、空权重
                    sub_w = zeros(size(k_score));
                    sub_w(k_score>0) = k_score(k_score>0)./sum(k_score(k_score>0));
                    sub_w(k_score<0) = k_score(k_score<0)./sum(k_score(k_score<0));

                    %获取收益率数据,并平均
                    sub_ind = i:(i+H-1);
                    sub_ind(sub_ind>T_tref) = [];
                    %多
                    sub_y_r_m = y_re(sub_ind,ind_sel2);    
                    %手续费
                    sub_y_r_m(1,:) = sub_y_r_m(1,:)-3/10000;
                    sub_y_r_m(end,:) = sub_y_r_m(end,:)-3/10000;
                    temp = sub_w(ind_sel2).*cumprod((1+sub_y_r_m));
                    temp = [1;sum(temp,2)];
                    temp_m = temp(2:end)./temp(1:end-1)-1;
                    if ~isempty(ind_sel1)
                        %空
                        sub_y_r = y_re(sub_ind,ind_sel1);    
                        %手续费
                        sub_y_r([1,end],:) = sub_y_r([1,end],:);
                        temp = sub_w(ind_sel1).*cumprod((1+sub_y_r));
                        temp = [1;sum(temp,2)];
                        temp = temp(2:end)./temp(1:end-1)-1;
                    else
                        temp=0;
                    end
                    y_bac(sub_ind,i0) = temp_m-temp;
                end
            end
            ind = tref_num>datenum(2010,1,1);
            y_bac1 = y_bac(ind,:);
            tref_num1 = tref_num(ind);

            y_bac_t = 1/m_num*cumprod(y_bac1+1);
            y_bac_t = sum(y_bac_t,2);
            bpcure_plot_updateV2(tref_num1,y_bac_t);
            title(key_str)
            [v,v_str] = curve_static(y_bac_t);
            h = gcf;
            
        end
    end

end

%{
1. 所有品种的保证金固定为 20%；
2. 仓位固定为 50%，即调仓日使用 50%的资金作为保证金买入期货合约，余下的
现金用于每日追加保证金，并按隔夜回购利率 R001 计算每日现金部分收益；
3. 交易成本：全品种按单边万分之三计算；
4. 使用复权主力合约发出交易信号，使用主力合约交易，在切换日收盘时平掉当
前仓位，在下一个主力合约上开仓，开平仓的合约价值相同

开盘买，收盘卖
增加R001收益
在ver1基础上升级

在掘金、fushare组合数据程序基础上升级，使用yuqer数据
优化了回测时间范围
%}
function [cash_flow,tref] = get_bac_data_yuqer_update(symbol,contract_multiplier,position_ratio)
    if nargin < 3
        position_ratio = 0.2;%仓位比例
    end
    %获取掘金主连数据
    sql_str = ['select tradedate,ticker,openprice,closeprice from yuqerdata.yq_MktMFutdGet ',...
        'where exchangeCD=''%s'' and contractObject=''%s''and openprice is not null and closeprice is not null ',...
        'and tradedate>=''2005-01-01'' and mainCon=1 order by tradedate'];
    y_yq = fetchmysql(sprintf(sql_str,symbol{1},symbol{2}),2);

    tref = y_yq(:,1);
    tref = datenum(tref);
    y_yq_price_open = cell2mat(y_yq(:,3));
    y_yq_price_close = cell2mat(y_yq(:,4));
    index_contracts = y_yq(:,1:2);

    T = length(y_yq_price_open);

    ini_cash = 10000000;%初始资金
    fee = 3/10000;%手续费　
    %fee = 0;

    asure_ratio = 0.2; %保证金比例
    R001 = 2/100/365;%R001按照年化2%计算
    N=1e10; %换仓间隔
    %contract_multiplier = 10;%合约乘数
    cash_flow_detail_open = zeros(T,2);%开盘后，剩余流动资金,保证金
    cash_flow_detail_close=cash_flow_detail_open;%收盘后，剩余流动资金,保证金
    cash_flow = zeros(T+1,1);%记录每日资金总数
    cash_flow(1) = ini_cash;
    position_detail_open = zeros(T,2); %买入的价格 买入的手数
    %position_detail_close = position_detail_open;
    fee_flow = zeros(T,2); %开盘买入手续费，收盘卖出手续费

    for i = 1:T
        %建仓条件
        case_open1 = eq(mod(i-1,N),0);%开盘建仓
        if i > 1 %换约建仓
            case_open2 = ~strcmp(index_contracts(i,2),index_contracts(i-1,2));
        else
            case_open2 = false;
        end    
        case_open = case_open1|case_open2;
        %平仓条件
        case_close1 = eq(mod(i,N),0);%结算平仓
        if i <T
            case_close2 = ~strcmp(index_contracts(i,2),index_contracts(i+1,2));
        else
            case_close2 = true;
        end  
        case_close= case_close1|case_close2;

        if case_open %符合开仓条件
            %开盘开仓
            %1手保证金价格
            asure_grid = y_yq_price_open(i)*contract_multiplier*asure_ratio;
            %可买入的手数
            sub_share_num = floor(cash_flow(i)*position_ratio/asure_grid); 
            %记录       
            position_detail_open(i,:) = [y_yq_price_open(i),sub_share_num];
            cash_flow_detail_open(i,:) = [cash_flow(i)*(1-position_ratio),...
                cash_flow(i)*position_ratio-sub_share_num*asure_grid*fee];        
            fee_flow(i,1) = sub_share_num*asure_grid*fee;
        else
            position_detail_open(i,:) = position_detail_open(i-1,:);%record
            cash_flow_detail_open(i,:) =cash_flow_detail_open(i-1,:);%record
        end    
        %收盘统计
        %参数
        if case_open
            temp_cash_flow_detail = cash_flow_detail_open(i,:);
            sub_price = y_yq_price_open(i);
        else
            temp_cash_flow_detail = cash_flow_detail_close(i-1,:).*[1+R001,1];
            sub_price = y_yq_price_close(i-1);
        end
        %质押金变化
        temp_cash_flow_detail(2) = temp_cash_flow_detail(2)+(y_yq_price_close(i)-...
            sub_price)*contract_multiplier*position_detail_open(i,2);
        if case_close %符合平仓条件
            fee_flow(i,2) = y_yq_price_close(i)*contract_multiplier*position_detail_open(i,2)*fee;
            temp_cash_flow_detail(2) = temp_cash_flow_detail(2)-fee_flow(i,2);
            cash_flow_detail_close(i,:) = [sum(temp_cash_flow_detail),0];
            cash_flow(i+1) =  sum(temp_cash_flow_detail);
        else
            %仅仅结算        
            %保证金变化
            temp_asure_cash = sub_price*contract_multiplier*position_detail_open(i,2)*asure_ratio;
            %是否需要追加
            if temp_asure_cash>temp_cash_flow_detail(2)%追加
                cash_need = temp_asure_cash-temp_cash_flow_detail(2);
                temp_cash_flow_detail = temp_cash_flow_detail+[-cash_need,cash_need];
            end
            cash_flow_detail_close(i,:) = temp_cash_flow_detail;
            cash_flow(i+1) = sum(cash_flow_detail_close(i,:));
            if cash_flow(i+1)<=0
                cash_flow(i+1:end) = cash_flow(i+1);
                break
            end
        end
        %if any(isnan(cash_flow));keyboard;end

    end

    cash_flow = cash_flow(2:end);
%     figure;
%     plot(y_jj_price_close/y_jj_price_close(1))
%     hold on
%     plot(cash_flow/cash_flow(1))
    %fee_all = cumsum(sum(fee_flow,2))/cash_flow(1);
    %plot(fee_all);
end

%时间序列动量因子
function [r,tref,add_v] = get_momentum(symbol,N)
sql_str = ['select tradingdate,close_price from futuredata.YQ_future_rehabilitation_data ',...
    'where symbol = ''%s'' and tradingdate>=''2005-01-01'' order by tradingdate'];
x = fetchmysql(sprintf(sql_str,strjoin(symbol,'.')),2);
y = cell2mat(x(:,2));
r = zeros(size(y));
r(N+1:end) = y(N+1:end)./y(1:end-N)-1;
tref = datenum(x(:,1));
add_v = [y,[0;y(2:end)./y(1:end-1)]];
end
%截面动量因子
function [r,tref] = get_sectional_momentum(symbol,N)
sql_str = ['select tradingdate,close_price from futuredata.YQ_future_rehabilitation_data ',...
    'where symbol = ''%s'' and tradingdate>=''2005-01-01'' order by tradingdate'];
x = fetchmysql(sprintf(sql_str,strjoin(symbol,'.')),2);
y = cell2mat(x(:,2));
r = zeros(size(y));
r(N+1:end) = y(N+1:end)./y(1:end-N)-1;
tref = datenum(x(:,1));
end
%展期收益率因子
function [r,tref] = get_roll_return_yq(symbol,N)
sql_str = ['select tradingdate,R1,R2,R3,R4 from futuredata.yuqer_future_rollreturn ',...
    'where  symbol = ''%s'' ',...
    'and tradingdate>=''2005-01-01'' order by tradingdate'];
x = fetchmysql(sprintf(sql_str,symbol{2}),2);
tref = datenum(x(:,1));
r = cell2mat(x(:,N+1));

end
%基差动量
function [r,tref] = get_basismomentum_return(symbol,N,mod)
if nargin < 3
    mod = 1;
end
sql_str = ['select tradingdate,R1,R2,R3,R4,R5 from futuredata.yuqer_future_basis_momentum ',...
    'where symbol = ''%s'' and tradingdate>=''2005-01-01'' order by tradingdate'];
x = fetchmysql(sprintf(sql_str,symbol{2}),2);
y = cell2mat(x(:,2:end));
y(y>0.1) = 0.1;
y(y<-0.1) = -0.1;
y = cumprod(1+y);
r = zeros(size(y));
r(N+1:end,:) = y(N+1:end,:)./y(1:end-N,:);%累积收益率
%当月 次月 主力 次主力 最远月
tref = datenum(x(:,1));
if eq(mod,1)
    r = r(:,1)-r(:,3);
elseif eq(mod,2)
    r = r(:,3)-r(:,4);
end

end
%仓单因子
function [r,tref] = get_warehouse(symbol,R)
    %R = 240;
    sql_str = ['select tradedate,wrvol from futuredata.yq_warehousefactor_data ',...
        'where contractobject = ''%s'' and tradedate>=''2005-01-01'' order by tradedate'];
    x = fetchmysql(sprintf(sql_str,symbol{2}),2);
    if ~isempty(x)
        y = cell2mat(x(:,2:end));
        r = zeros(size(y));
        for i = R+1:length(y)
            r(i) = (y(i)-y(i-R))/y(i-R);
        end
        r(isnan(r)|isinf(r)) = 0;
        tref = datenum(x(:,1));
    else
        r = [];
        tref = [];
    end
end


function [x,tref] = get_vol_data(symbol)
sql_str = ['select tradedate,turnoverVol from yuqerdata.yq_MktMFutdGet ',...
        'where exchangeCD=''%s'' and contractObject=''%s''and openprice is not null and closeprice is not null ',...
        'and tradedate>=''2005-01-01'' and mainCon=1 order by tradedate'];
y_jj = fetchmysql(sprintf(sql_str,symbol{1},symbol{2}),2);
x = cell2mat(y_jj(:,2));
tref = datenum(y_jj(:,1));
end

function bpcure_plot_updateV2(t,x,str,lstr,sel)
%3/1
if nargin < 5
    sel = 2;%两种图都画
end
if nargin < 4
    lstr = [];
end
if nargin < 3
    str = [];
end
if nargin < 2
    x = t(:,2);
    t = t(:,1); 
end

if isnumeric(t)
    t = cellstr(datestr(t,'yyyymmdd'));
end

if eq(sel,2)
%     hold on
%     ylims1 = [min(min(x)),max(max(x))];
%     pic_lim = [-diff(ylims1)/100,diff(ylims1)/100];
%     ylims1 = ylims1+pic_lim;
%     ylims1(1) = ylims1(1)-diff(ylims1)/3;
%     ylim(ylims1)

    v = getdrawdown(x)*100;
    %subplot(1,2,2);
    yyaxis right
    %bar(t,v)
    %plot(t,v);
    %myplot(t,v);
    obj_L = mybar(v,[0.5,0.5,0.5]);
%    lims = axis(gca);
%     plot(lims(1:2),[0,0],'linewidth',2)
    datetick('x','yyyy');

%     ylims1 = [min(min(v)),max(max(v))];
%     pic_lim = [-diff(ylims1)/100,diff(ylims1)/100];
%     ylims1 = ylims1+pic_lim;
%     ylims1(2) = ylims1(2)+3*diff(ylims1);
%     ylim(ylims1)
    xlim([1,length(v)]+[-1,1]);
    
    if  ~isempty(lstr)
        legend(obj_L,lstr,'location','best');
    end
    ylabel('drawdown');
    ah=gca;
    ah.YColor=[0.5,0.5,0.5];
end

%subplot(1,2,1)
x = bsxfun(@rdivide,x*100,x(1,:));
if eq(sel,2)
    yyaxis left
end
obj_L = myplot(x);
if ~isempty(str)
    title(str)
end
%legend({'ref',strjoin(indicatorName0,'\r\n')},'location','best')
if ~eq(sel,2)&&~isempty(lstr)
    legend(obj_L,lstr,'location','best');
end
xlim([1,length(v)]+[-1,1]);
ylabel('bac curve');
set(gca,'linewidth',2);
ah=gca;
ah.YColor='r';

set(gca,'XTickLabelRotation',90);
set(gca,'XTick',floor(linspace(1,length(v),40)),'xlim',[1,length(v)]);
set(gca,'XTickLabel',t(floor(linspace(1,length(t),40))));
%datetick('x','yyyymmdd','keeplimits');
set(gca,'fontsize',12);

end

function obj_L=myplot(y)
    T = size(y,2);
    obj_L = zeros(T,1);
    %C = linspecer(T);
    hold on
    for i = 1:T
        obj_L(i) = plot(y(:,i),'r-','linewidth',2,'Marker','none');
    end

end

function obj_L=mybar(y,c_val)
%     T = size(y,2);
%     obj_L = zeros(T,1);
%     C = linspecer(T);
%     hold on
%     for i = 1:T
%         obj_L(i) = plot(x,y(:,i),'-','color',C(i,:),'linewidth',2,'Marker','none');
%     end
    obj_L = area(y,'FaceAlpha',0.5,'FaceColor',c_val,'EdgeColor','none');
end

function v = getdrawdown(x)
    v = zeros(size(x));
    for i = 1:size(x,2)
        v(:,i) = x(:,i)./cummax(x(:,i))-1;
    end
end

% function a_setylim()
% 
% end