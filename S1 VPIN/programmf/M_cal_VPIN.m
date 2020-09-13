clear
load IFmain_all.mat
num = 50;

ind = t>=datenum(2010,9,1)&t<=datenum(2011,2,29);
t0 = t(ind);
volume0 = volume(ind);
V0 = sum(volume0);
N0 = length(unique(floor(t0)));
V = round(V0/N0/num);
delt_p0 = p_close(ind)-p_open(ind);
std_x = std(delt_p0);
mx = mean(delt_p0);


ind = t>=datenum(2011,2,29) &t<= datenum(2017,2,29);
t1 = t(ind);
volume1 = volume(ind);
delt_p1 = p_close(ind)-p_open(ind);
T = length(t1);
reset_test = 0;
bucket_v = [0,0];
bucket_ind0 = [0,0];
VPIN = zeros(T,3);
j_t = 1;
for i = 1:T
    %routine work
    bucket_v(2) = bucket_v(2)+volume1(i);
    bucket_ind0(2) = i;
    %Test
    if bucket_v(2)<V
        %do nothing and go on calculating
    else
        if eq(bucket_v(1),0)
            %begin just is empty
            bucket_data_ind = bucket_ind0(1)+1:bucket_ind0(2);
            bucket_data = [t1(bucket_data_ind),delt_p1(bucket_data_ind),volume1(bucket_data_ind)];
        else
            %begin remained some volume
            bucket_data_ind = bucket_ind0(1):bucket_ind0(2);
            bucket_data = [t1(bucket_data_ind),delt_p1(bucket_data_ind),volume1(bucket_data_ind)];
            bucket_data(1,3) = bucket_v(1);
        end
        if  bucket_v(2)>V
            bucket_data(end,3) = bucket_data(end,3)-(bucket_v(2)-V);
            bucket_v(1) = bucket_v(2)-V;
        else
            bucket_v(1) = 0;
        end
        
        std_x = std(cat(1,delt_p0,delt_p1(1:i-1)));
        mx = mean(cat(1,delt_p0,delt_p1(1:i-1)));
        bucket_data_add = zeros(size(bucket_data,1),3);
        for j = 1:size(bucket_data,1)
            sub_x1 = normcdf(bucket_data(j,2),mx,std_x);
            sub_x2 = bucket_data(j,3).*[sub_x1,1-sub_x1];
            bucket_data_add(j,:) = [sub_x1,sub_x2];
        end
        %calculate VPIN
        temp1 = abs(sum(bucket_data_add(:,end-1))-sum(bucket_data_add(:,end)));
        VPIN(j_t,:) = [bucket_data(1,1),bucket_data(end,1),temp1];
        j_t = j_t+1;
        if bucket_v(1)>V
            add_N = floor(bucket_v(1)/V);
            VPIN(j_t:j_t+add_N-1,:) = repmat([VPIN(j_t-1,1:2),abs(V*(1-bucket_data_add(end,1)*2))],add_N,1);  
            j_t=j_t+add_N;
            bucket_v(1) = bucket_v(1)- V*add_N;
        end
        %reset
        bucket_v(2)=bucket_v(1);
        bucket_ind0(1) = i;
        
        sprintf('%0.2f%%',i/T*100)
    end
    
end
VPIN = VPIN(1:j_t-1,:);

[t_u,~,C] = unique(VPIN(:,2));
[~,ia,ib] = intersect(t_u,t);

p = zeros(size(t_u));
p(ia) = p_close(ib);
p1 = p(C);
%{
re = [cellstr(datestr(VPIN(:,1),'yyyy/mm/dd HH:MM')),cellstr(datestr(VPIN(:,2),'yyyy/mm/dd HH:MM')),num2cell(VPIN(:,3))];
re=[{'开始时间','结束时间','不平衡订单量'};re];
xlswrite('bucket.xlsx',re)
save VPIN VPIN V num p1
%}
