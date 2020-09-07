%国内成分计算
clear;
%难点 S&P 500成分股代号获取
addpath(genpath(fullfile(pwd,'jplv7')))
topN=10; % Max number of positions
entryZscore=1;
lookback=20; % for MA

key_str = 'A_41';
index_pool = {'000300','000905','000001'};
for index_id = 1:3
    index_sel = index_pool{index_id};
    stocks = yq_methods.get_index_pool(index_sel,'2005-01-01');

    temp = get_pool_data(stocks,'2005-01-01','csi');
    cl=temp.cl;
    hi=temp.hi;
    lo=temp.lo;
    op=temp.op;
    tday=temp.tday;
    tref = temp.tref;


    stdretC2C90d=backshift(1, smartMovingStd(calculateReturns(cl, 1), 90));
    buyPrice=backshift(1, lo).*(1-entryZscore*stdretC2C90d);

    retGap=(op-backshift(1, lo))./backshift(1, lo);

    pnl=zeros(length(tday), 1);

    positionTable=zeros(size(cl));

    ma=backshift(1, smartMovingAvg(cl, lookback));

    for t=2:size(cl, 1)
        hasData=find(isfinite(retGap(t, :)) & op(t, :) < buyPrice(t, :) & op(t, :) > ma(t, :));

        [foo idxSort]=sort(retGap(t, hasData), 'ascend');
        positionTable(t, hasData(idxSort(1:min(topN, length(idxSort)))))=1;
    end

    retO2C=(cl-op)./op;


    pnl=smartsum(positionTable.*(retO2C), 2);
    ret=pnl/topN; 
    ret(isnan(ret))=0;

    fprintf(1, '%i - %i\n', tday(1), tday(end));
    fprintf(1, 'APR=%10.4f\n', prod(1+ret).^(252/length(ret))-1);

    fprintf(1, 'Sharpe=%4.2f\n', mean(ret)*sqrt(252)/std(ret));
    % APR=8.7%, Sharpe=1.5

    %cumret=cumprod(1+ret)-1; % compounded ROE

    %plot(cumret);
    if ~isempty(tref)
        y_re = cumprod(1+ret)-1;
        %setfigure
        h = figure_S53(y_re,tref,[]);
        title(sprintf('A-41-%s',index_sel))
    else
        figure;
        plot(cumprod(1+ret)-1); % Cumulative compounded return
    end
end
