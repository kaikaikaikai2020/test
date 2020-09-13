close all;clear;clc;

load ('C:\IF1MIN.mat');

data=data(60681:183041,1:6);

time=time(60681:183041,1);

tic

 

%fee=1.5/10000;%������

fee=0;%������,ʵ��Ҫ��1.5/10000!!

 

Open=data(:,1);%���̼�

High=data(:,2);%��߼�

Low=data(:,3);%��ͼ�

Close=data(:,4);%���̼�

Vol=data(:,5);%�ɽ���

Openint=data(:,6);%�ֲ���

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

 

% ����MACD

%������㳤��

shortPeriod=12;%�������̼۶��ڣ����٣�ƽ���ƶ�ƽ�����㳤��

longPeriod=26;%�������̼۳��ڣ����٣�ƽ���ƶ�ƽ�����㳤��

DEAPeriod=9;%����diff��ƽ���ƶ�ƽ�����㳤��

%����ռλ������߳�������Ч��

EMAshort=zeros(length(Close),1);

EMAlong=zeros(length(Close),1);

DIFF=zeros(length(Close),1);

DEA=zeros(length(Close),1);

MACD=zeros(length(Close),1);

%��ѭ�����������ָ��

EMAshort(1)=Close(1);%��ʼ��EMAshort��һֵ

EMAlong(1)=Close(1);%��ʼ��EMAlong��һ��ֵ

DEA(1)=0;%��ʼ����һֵ

DIFF(1)=0;

MACD(1)=0;

for i=2:lth;

    %������ںͳ���EMA

  EMAshort(i)=Close(i)*(2/(shortPeriod+1))+EMAshort(i-1)*((shortPeriod-1)/(shortPeriod+1));

   EMAlong(i)=Close(i)*(2/(longPeriod+1))+EMAlong(i-1)*((longPeriod-1)/(longPeriod+1));

    %����DIFF

    DIFF(i)=EMAshort(i)-EMAlong(i);

    %����DEA

 DEA(i)=DIFF(i)*(2/(DEAPeriod+1))+DEA(i-1)*((DEAPeriod-1)/(DEAPeriod+1));

    %����MACD

    MACD(i)=2*(DIFF(i)-DEA(i));

end

 

% ����KDJ

Ma_Min=5;%����1��Ma_Min��ʾ�����õ�Ma����Сֵ

Ma=Ma_Min; %����1��Ma��ʾ���ߵ�����,��ʼֵΪMa_Min

Ma_Max=60;%����1��Ma_Max��ʾ�����õ�Ma�����ֵ

for i=2:lth  

    if (Ma>i)  %ǰ�漸������û�о������ݣ���ʵ���������

        KDJ_Matrix(i,1)=0; %ÿ���RSV����������0

        KDJ_Matrix(i,2)=50; %ÿ���Kֵ����Ϊǰһ����Kֵ�����Ը���ֵ50    

        KDJ_Matrix(i,3)=50; %ÿ���Dֵ����Ϊǰһ����Dֵ�����Ը���ֵ50

        KDJ_Matrix(i,4)=0;  %ÿ���Jֵ����Ϊ������Kֵ��Jֵ�����Ը���ֵ0

    else

       KDJ_Matrix(i,1)=(data(i,4)-min((data(i-5+1:i,3))))/(max((data(i-5+1:i,2)))-min((data(i-5+1:i,3))))*100;%ÿ��rsv

        KDJ_Matrix(i,2)=2/3*KDJ_Matrix(i-1,2)+1/3* KDJ_Matrix(i,1); %ÿ��Kֵ��Kֵ=2/3��ǰһ��Kֵ��1/3������RSV

        KDJ_Matrix(i,3)=2/3* KDJ_Matrix(i-1,3)+1/3*KDJ_Matrix(i,2); %ÿ��Dֵ��Dֵ=2/3��ǰһ��Dֵ��1/3�����յ�Kֲ

        KDJ_Matrix(i,4)=3* KDJ_Matrix(i,2)-2*KDJ_Matrix(i,3); %ÿ��Jֵ��Jֵ=3*����Kֵ-2*����Dֵ        

    end

end

 

 %���㵽iʱ��MACD����Сֵ

for i=2:lth

    if MACD(i)>MACD(i-1)||MACD(i)==MACD(i-1);

        minMACD(i)=MACD(i-1);

    elseif MACD(i)

        minMACD(i)=MACD(i);  

    end

end

 

%���㵽iʱ��MACD�����ֵ

for i=2:lth

    if MACD(i)>MACD(i-1)||MACD(i)==MACD(i-1);

       maxMACD(i)=MACD(i);

    elseif MACD(i)

         maxMACD(i)=MACD(i-1);

    end 

end

 

%cmiָ��

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

        buy=(llvc(i)%����    

       sellshort=((MACD(i)up))||((MACD(i)up)&&(KDJ_Matrix(i,4)%����

        sell=(hhvc(i)>hhvc(i-1))&&(maxMACD(i)==maxMACD(i-1));%ƽ��

 buytocover=((MACD(i)>MACD(i-1))&&(Close(i)MACD(i-1))&&(KDJ_Matrix(i,4)>KDJ_Matrix(i-1,4)))||((Close(i)KDJ_Matrix(i-1,4)));%ƽ��

         end

       ifcmi(i)<53

       buy=Close(i)%����

      sellshort=((MACD(i)up))||((MACD(i)up)&&(KDJ_Matrix(i,4)%����

       sell=Close(i)>up;%ƽ�� buytocover=((MACD(i)>MACD(i-1))&&(Close(i)MACD(i-1))&&(KDJ_Matrix(i,4)>KDJ_Matrix(i-1,4)))||((Close(i)KDJ_Matrix(i-1,4)));%ƽ�� 

       end

      

%%����˼��

% ��cmi���ڻ����53ʱ

% ���ࣺMACD�ױ��룻

% ƽ�ࣺMACD�����룻

% ���գ�����MACDС��ǰһ��MACD�����̼�����BOLL���Ϲ졢����JֵС��ǰһ�ڵ�Jֵ����������������2����2�����ϣ�

% ƽ�գ�����MACD����ǰһ��MACD�����̼�����BOLL���¹졢����Jֵ����ǰһ�ڵ�Jֵ����������������2����2�����ϣ�

% ��cmiС��53ʱ

% ���ࣺ���̼�����BOLL���¹죻

% ƽ�ࣺ���̼�����BOLL���Ϲ죻

% ���գ�����MACDС��ǰһ��MACD�����̼�����BOLL���Ϲ졢����JֵС��ǰһ�ڵ�Jֵ����������������2����2�����ϣ�

% ƽ�գ�����MACD����ǰһ��MACD�����̼�����BOLL���¹졢����Jֵ����ǰһ�ڵ�Jֵ����������������2����2�����ϣ�     

      

%%�����Զ�����      

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

%%-%%��������ͼ

sumprofit=cumsum(profit)*300;

sump=cumsum(p);

%��������

finalprofit=sumprofit(end)

finalp=sump(end)

%���״���

tradetimes

%���س�

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

 fprintf('���Ļس�Ϊ%i\n', U);

 fprintf('���Ļس��ĵ�Ϊ%i\n', J);

 fprintf('��ߵĵ�Ϊ%i\n',highestprofit);

 

 %���س�

highestprofitj5=0;maxbackh2=0;

for I=2:lth

   highestprofitj5=max(highestprofitj5,sumprofit(I));

   maxbackh2=max(maxbackh2,highestprofitj5-sumprofit(I));

    drawdown=maxbackh2/highestprofitj5;

end

maxbackh2

%�ʽ�����

drawdown

plot(time,sumprofit);datetick('x','YYYY');

%������ձ�

timenum=datevec(time(end)-time(1));

income_rick=sumprofit(end)/maxbackh2/(timenum(1)+timenum(2)/12+timenum(3)/31)

ind=find(entryprice>0,1)

 fprintf('����۸�Ϊ%i\n',entryprice (ind));

 netprofit=sumprofit(end)-entryprice(ind);

 fprintf('������%i\n',netprofit);

 shouxufei=tradetimes*1.5/10000;

 fprintf('������Ϊ%i\n', shouxufei);

 zongshouyilv=(sumprofit(end)-entryprice(ind))/entryprice(ind);

  fprintf('��������%i\n',zongshouyilv );

nianhuashouyilv=zongshouyilv/(timenum(1)+timenum(2)/12+timenum(3)/31);

  fprintf('�껯������%i\n',nianhuashouyilv );

  zuidahuice=(highestprofit-sumprofit(J))/highestprofit;

  fprintf('��󵥴�ӯ��%i\n', max(profit));

  fprintf('��󵥴ο���%i\n', min(profit));

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

 fprintf('�������ӯ������%i\n', highestx1);

 fprintf('�������ӯ�����%i\n', highestx2);

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

 

fprintf('��������������%i\n',highestx3);

fprintf('�������������%i\n',-highestx4);

 

fprintf('������ձ�%i\n',income_rick);

fprintf('ʤ��Ϊ%i\n',hang/(hang+h));

timenum1=datevec(time(end)-time(8101));

jiaoyipinglv=tradetimes/(timenum1(1)*365+timenum1(2)*30+timenum1(3));

fprintf('����Ƶ��%i\n',jiaoyipinglv);

stdtotal1=std(profit);

sharpraitio=zongshouyilv/stdtotal1;

fprintf('���ձ���%i\n',sharpraitio);

 

close(loading);

toc