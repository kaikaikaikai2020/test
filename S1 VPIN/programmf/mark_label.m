function mark_label(ah,str)
lims = axis(ah);
mx = [lims(2)-lims(1),lims(4)-lims(3)]/50;
text(ah,lims(1)+mx(1),lims(4)-mx(2),str,'VerticalAlignment','top');
axis(ah,lims);
end