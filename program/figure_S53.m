function h = figure_S53(y_re,tref,t_str1)
    t_str = cellfun(@(x) strjoin(strsplit(x,'-'),''),tref,'UniformOutput',false);
    T = length(t_str);
    h = figure;
    plot(y_re,'LineWidth',2);
    set(gca,'xlim',[0,T]);
    set(gca,'XTick',floor(linspace(1,T,15)));
    set(gca,'XTickLabel',t_str(floor(linspace(1,T,15))));
    set(gca,'XTickLabelRotation',90)    
    setpixelposition(h,[223,365,1345,420]);
    %legend(leg_str,'Location','best')
    box off
    if ~isempty(t_str1)
        title(t_str1)
    end
end