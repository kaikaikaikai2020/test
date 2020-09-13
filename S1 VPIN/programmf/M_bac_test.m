close all;clear;clc;

load ('C:\IF1MIN.mat');

data=data(60681:183041,1:6);

time=time(60681:183041,1);

tic

 

%fee=1.5/10000;%手续费

fee=0;%手续费,实际要用1.5/10000!!

 

Open=data(:,1);%开盘价

High=data(:,2);%最高价

Low=data(:,3);%最低价

Close=data(:,4);%收盘价

Vol=data(:,5);%成交量

Openint=data(:,6);%持仓量

hhvc=hhigh(High,7);

llvc=llow(Low,7);

 

[lth,wth]=size(data);

profit=zeros(lth,1);

holding=zeros(lth,1);

entryprice=zeros(lth,1);

tradetimes=0;

cmi=zeros(lth,1);

f=0;g=0;

 

loading= waitbar(0,'Loading');

 

% 计算MACD

%定义计算长度

shortPeriod=12;%定义收盘价短期（快速）平滑移动平均计算长度

longPeriod=26;%定义收盘价长期（慢速）平滑移动平均计算长度

DEAPeriod=9;%定义diff线平滑移动平均计算长度

%建立占位矩阵，提高程序运行效率

EMAshort=zeros(length(Close),1);

EMAlong=zeros(length(Close),1);

DIFF=zeros(length(Close),1);

DEA=zeros(length(Close),1);

MACD=zeros(length(Close),1);

%用循环语句计算各个指标

EMAshort(1)=Close(1);%初始化EMAshort第一值

EMAlong(1)=Close(1);%初始化EMAlong第一个值

DEA(1)=0;%初始化第一值

DIFF(1)=0;

MACD(1)=0;

for i=2:lth;

    %计算短期和长期EMA

  EMAshort(i)=Close(i)*(2/(shortPeriod+1))+EMAshort(i-1)*((shortPeriod-1)/(shortPeriod+1));

   EMAlong(i)=Close(i)*(2/(longPeriod+1))+EMAlong(i-1)*((longPeriod-1)/(longPeriod+1));

    %计算DIFF

    DIFF(i)=EMAshort(i)-EMAlong(i);

    %计算DEA

 DEA(i)=DIFF(i)*(2/(DEAPeriod+1))+DEA(i-1)*((DEAPeriod-1)/(DEAPeriod+1));

    %计算MACD

    MACD(i)=2*(DIFF(i)-DEA(i));

end

 

% 计算KDJ

Ma_Min=5;%参数1，Ma_Min表示测试用的Ma的最小值

Ma=Ma_Min; %参数1，Ma表示均线的天数,初始值为Ma_Min

Ma_Max=60;%参数1，Ma_Max表示测试用的Ma的最大值

for i=2:lth  

    if (Ma>i)  %前面几个数据没有均线数据，用实际数据替代

        KDJ_Matrix(i,1)=0; %每天的RSV参数，等于0

        KDJ_Matrix(i,2)=50; %每天的K值，因为前一天无K值，所以赋初值50    

        KDJ_Matrix(i,3)=50; %每天的D值，因为前一天无D值，所以赋初值50

        KDJ_Matrix(i,4)=0;  %每天的J值，因为当天无K值和J值，所以赋初值0

    else

       KDJ_Matrix(i,1)=(data(i,4)-min((data(i-5+1:i,3))))/(max((data(i-5+1:i,2)))-min((data(i-5+1:i,3))))*100;%每日rsv

        KDJ_Matrix(i,2)=2/3*KDJ_Matrix(i-1,2)+1/3* KDJ_Matrix(i,1); %每日K值，K值=2/3×前一日K值＋1/3×当日RSV

        KDJ_Matrix(i,3)=2/3* KDJ_Matrix(i-1,3)+1/3*KDJ_Matrix(i,2); %每日D值，D值=2/3×前一日D值＋1/3×当日的K植

        KDJ_Matrix(i,4)=3* KDJ_Matrix(i,2)-2*KDJ_Matrix(i,3); %每日J值，J值=3*当日K值-2*当日D值        

    end

end

 

 %计算到i时刻MACD的最小值

for i=2:lth

    if MACD(i)>MACD(i-1)||MACD(i)==MACD(i-1);

        minMACD(i)=MACD(i-1);

    elseif MACD(i)

        minMACD(i)=MACD(i);  

    end

end

 

%计算到i时刻MACD的最大值

for i=2:lth

    if MACD(i)>MACD(i-1)||MACD(i)==MACD(i-1);

       maxMACD(i)=MACD(i);

    elseif MACD(i)

         maxMACD(i)=MACD(i-1);

    end 

end

 

%cmi指标

for i=2:lth

cmi(i)=(abs(Close(i)-Close(i-1)))*100/(hhvc(i)-llvc(i));

end

 

for i=7:lth

     holding(i)=holding(i-1);

    entryprice(i)=entryprice(i-1);   

    if mod (i,round(lth/50))==0

        waitbar(i/lth,loading)

    end

    currentbar=mod(i,270);

    if i>10

        std1=std(Close(i-9:i),1)*2;

         ma=mean(Close(i-9:i));

        up=ma+std1;

        dn=ma-std1;

         if(cmi(i)>53)||(cmi(i)==53)

        buy=(llvc(i)%开多    

       sellshort=((MACD(i)up))||((MACD(i)up)&&(KDJ_Matrix(i,4)%开空

        sell=(hhvc(i)>hhvc(i-1))&&(maxMACD(i)==maxMACD(i-1));%平多

 buytocover=((MACD(i)>MACD(i-1))&&(Close(i)MACD(i-1))&&(KDJ_Matrix(i,4)>KDJ_Matrix(i-1,4)))||((Close(i)KDJ_Matrix(i-1,4)));%平空

         end

       ifcmi(i)<53

       buy=Close(i)%开多

      sellshort=((MACD(i)up))||((MACD(i)up)&&(KDJ_Matrix(i,4)%开空

       sell=Close(i)>up;%平多 buytocover=((MACD(i)>MACD(i-1))&&(Close(i)MACD(i-1))&&(KDJ_Matrix(i,4)>KDJ_Matrix(i-1,4)))||((Close(i)KDJ_Matrix(i-1,4)));%平空 

       end

      

%%交易思想

% 当cmi大于或等于53时

% 开多：MACD底背离；

% 平多：MACD顶背离；

% 开空：当天MACD小于前一天MACD、收盘价碰到BOLL的上轨、当期J值小于前一期的J值，三个条件中满足2个或2个以上；

% 平空：当天MACD大于前一天MACD、收盘价碰到BOLL的下轨、当期J值大于前一期的J值，三个条件中满足2个或2个以上；

% 当cmi小于53时

% 开多：收盘价碰到BOLL的下轨；

% 平多：收盘价碰到BOLL的上轨；

% 开空：当天MACD小于前一天MACD、收盘价碰到BOLL的上轨、当期J值小于前一期的J值，三个条件中满足2个或2个以上；

% 平空：当天MACD大于前一天MACD、收盘价碰到BOLL的下轨、当期J值大于前一期的J值，三个条件中满足2个或2个以上；     

      

%%利润自动计算      

        if(buytocover && holding(i)<-0.5) || (sell && holding(i)>0.5 )   

            profit(i)=profit(i)-Close(i)*fee;

            holding(i)=0;

            tradetimes=tradetimes+1;

        end       

        ifsellshort && holding(i)>-0.5

            ifholding(i)>0.5

               profit(i)=profit(i)-Close(i)*fee;

                tradetimes=tradetimes+1;

            end

            entryprice(i)=Close(i);

            profit(i)=profit(i)-Close(i)*fee;

            holding(i)=-1;

        end

       

        if buy&& holding(i)<0.5

            ifholding(i)<-0.5

               profit(i)=profit(i)-Close(i)*fee;

                tradetimes=tradetimes+1;

            end

            entryprice(i)=Close(i);

            profit(i)=profit(i)-Close(i)*fee;

            holding(i)=1;

        end

          ifholding(i-1)>0.5

           profit(i)=profit(i)+Close(i)-Close(i-1);

              p(i)=profit(i)/Close(i); 

        end

        ifholding(i-1)<-0.5

           profit(i)=profit(i)+Close(i-1)-Close(i);

            p(i)=profit(i)/Close(i);

        end 

    end

end

%%-%%结果输出绘图

sumprofit=cumsum(profit)*300;

sump=cumsum(p);

%最终收益

finalprofit=sumprofit(end)

finalp=sump(end)

%交易次数

tradetimes

%最大回撤

highestprofit=0;maxbackjj=0;

 maxbackd2=zeros(lth,1);

for I=1:lth

   highestprofit=max(highestprofit,sumprofit(I));

   maxbackd2(I)=max(maxbackjj,highestprofit-sumprofit(I));

end

[U,J]=max(maxbackd2);

for I=1:J

   highestprofit=max(highestprofit,sumprofit(I));

   maxbackd2(I)=max(maxbackjj,highestprofit-sumprofit(I));

end

 fprintf('最大的回撤为%i\n', U);

 fprintf('最大的回撤的点为%i\n', J);

 fprintf('最高的点为%i\n',highestprofit);

 

 %最大回撤

highestprofitj5=0;maxbackh2=0;

for I=2:lth

   highestprofitj5=max(highestprofitj5,sumprofit(I));

   maxbackh2=max(maxbackh2,highestprofitj5-sumprofit(I));

    drawdown=maxbackh2/highestprofitj5;

end

maxbackh2

%资金曲线

drawdown

plot(time,sumprofit);datetick('x','YYYY');

%收益风险比

timenum=datevec(time(end)-time(1));

income_rick=sumprofit(end)/maxbackh2/(timenum(1)+timenum(2)/12+timenum(3)/31)

ind=find(entryprice>0,1)

 fprintf('买入价格为%i\n',entryprice (ind));

 netprofit=sumprofit(end)-entryprice(ind);

 fprintf('净利润%i\n',netprofit);

 shouxufei=tradetimes*1.5/10000;

 fprintf('手续费为%i\n', shouxufei);

 zongshouyilv=(sumprofit(end)-entryprice(ind))/entryprice(ind);

  fprintf('总收益率%i\n',zongshouyilv );

nianhuashouyilv=zongshouyilv/(timenum(1)+timenum(2)/12+timenum(3)/31);

  fprintf('年化收益率%i\n',nianhuashouyilv );

  zuidahuice=(highestprofit-sumprofit(J))/highestprofit;

  fprintf('最大单次盈利%i\n', max(profit));

  fprintf('最大单次亏损%i\n', min(profit));

  zdyl=find(profit>0);

  [hang,lie]=size(zdyl);

 f=find(profit<0);

  [h,l]=size(f);

  countx1=0;

  highestx1=0;

  countx2=0;

  highestx2=0;

  for I=1:(hang-1)

       ifzdyl(I+1)-zdyl(I)==1

          countx1=countx1+1;

          countx2=countx2+profit(zdyl(I));

       else

        highestx1=max(countx1,highestx1);

        highestx2=max(countx2,highestx2);

        countx1=0;

        countx2=0;

        continue;

      end

  end

 fprintf('最大连续盈利次数%i\n', highestx1);

 fprintf('最大连续盈利金额%i\n', highestx2);

zxsy=find(profit<0);

[hang1,lie1]=size(zxsy);

countx3=0;

highestx3=0;

countx4=0;

highestx4=0;

for J=1:(hang1-1)

 if zxsy(J+1)-zxsy(J)==1

     countx3=countx3+1;

     countx4=countx4+abs(profit(zxsy(J)));

 else

     highestx3=max(countx3,highestx3);

     highestx4=max(countx4,highestx4);

     countx3=0;

     countx4=0;

     continue;

 end

 

end

 

fprintf('最大连续亏损次数%i\n',highestx3);

fprintf('最大连续亏损金额%i\n',-highestx4);

 

fprintf('收益风险比%i\n',income_rick);

fprintf('胜率为%i\n',hang/(hang+h));

timenum1=datevec(time(end)-time(8101));

jiaoyipinglv=tradetimes/(timenum1(1)*365+timenum1(2)*30+timenum1(3));

fprintf('交易频率%i\n',jiaoyipinglv);

stdtotal1=std(profit);

sharpraitio=zongshouyilv/stdtotal1;

fprintf('夏普比率%i\n',sharpraitio);

 

close(loading);

toc