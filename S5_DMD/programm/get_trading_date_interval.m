function [t,t_ind] = get_trading_date_interval(tref,t_now,N)
    ind = find(eq(tref,t_now));
    v1 = ind+N;
    v2 = ind;
    
    t_ind = min([v1,v2]):max([v1,v2]);
    t = tref(t_ind);
end