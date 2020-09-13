%M_import_wind_data
%X
%targ_tick
%targ_tick_name
%trade_time
clear

pn = 'F:\works2019\SOME\ÏîÄ¿\S4_FLS\bank_data_wind';
[~,~,targ_tick] = xlsread('bank_ticker.xlsx');
targ_tick_name = targ_tick(2:end,2);
targ_tick = targ_tick(2:end,1);

T = length(targ_tick_name);
re= cell(T,1);
t0 = [];
for i = 1:T
    sub_targ_tick = targ_tick{i};
    fn = [sub_targ_tick,'_Sec300_201009-201403.csv'];
    %var_name = {'tradingdate',sub_targ_tick};
    sub_fn = fullfile(pn,fn);
    x = readtable(sub_fn);
    t = cellfun(@(x,y) [x,' ' y],x{:,1},x{:,2},'UniformOutput',false);
    close_price = cellfun(@str2double,x{:,6});
    
    t = datenum(t,'yyyy/mm/dd HH:MM');
    sub_ind = t>=datenum(2010,9,2)&t<=datenum(2014,3,5);
    re{i} = [t(sub_ind),close_price(sub_ind)];
    t0=unique([t0;t(sub_ind)]);
	sprintf('%d-%d',i,t)
end

t0 = sort(t0);
X = nan(length(t0),T);
for i = 1:T
    [~,ia,ib] = intersect(t0,re{i}(:,1),'stable');
    X(ia,i) = re{i}(ib,2);
end
trade_time = datetime(t0,'ConvertFrom','datenum');

save bank16_data_matrix_wind X targ_tick targ_tick_name trade_time t0

