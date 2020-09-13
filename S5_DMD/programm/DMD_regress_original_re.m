clear
load dmd_regress_re2.mat
%load dmd_regress_re_window.mat
%load dmd_regress_re_window_update1.mat;re = re(:,[1,5,2,4,3,6]);
%load dmd_regress_re_window_update3.mat;re = re(:,[1,5,2,4,3,6]);

X0 = [ones(size(re(:,1))),re(:,1),abs(re(:,2))];
y0 = re(:,3);

[b,bint,r,rint,stats] = regress(y0,X0);




