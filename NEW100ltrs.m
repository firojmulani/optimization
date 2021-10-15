clc;
tic
G_hour=load('radiation2013yk.txt')*10^6*27.8*10^-5; %solar radiation
Temp_hour=load('Tx2013yk_everyday.txt'); %Enviroment Temperature
load_hour=xlsread('11.csv','B2:B8761')/55; % User's load
 %load_hour=xlsread('7.csv','B2:B8761')/105; % User's load
% load=xlsread('8.csv','B2:B8761'); % User's load

%^^^^^^^^^^^^^^^^^^^^^input data^^^^^^^^^^^^

%Heat pump specification
w_in=25; %入水溫 C Water temperature
%T_hp_s=zeros(8760,1);
T_hp_s=zeros(8760,1);
mass_water=[100 200 300 400];%水容量 Water capacity
length_mass=length(mass_water);
Time_use=[17 18 19 20 21 22]; %用戶需要用水的時間 單位:國際時間 ex:7pm=19 The time the user needs water unit: international time
length_t=length(Time_use);%算出情境的種類數量  Calculate the number of types of situations
year_use=zeros(8760,length_t); %建立一年用水習慣的矩陣 Establish a matrix of water usage habits for a year
year_water_t=zeros(8760,length_mass);  %一年的水溫變化矩陣  A year's water temperature change matrix
cop_normal=4.45; %COP
cop_winter=4; %COP 
Phpwh=1.416; %熱泵消耗功率  Heat pump power consumption
cp=4.1868; %　加熱一度水的比熱容   Heat capacity of water heated once
T_in=25; %入水溫度input water temperature
T_out_winter=55; %輸出水溫 冬天 output water temperature in winter
T_out_normal=45; %輸出水溫   Output water temperature
Ed_normal=cp*mass_water(1:4)*(T_out_normal-T_in)/3600; %加熱所需熱量  Heat required for heating
Ed_winter=cp*mass_water(1:4)*(T_out_winter-T_in)/3600; %加熱所需熱量  Heat required for heating
Tused=Ed_normal(1:4)/(cop_normal*Phpwh); %加熱所需時間   Heating time
Tused_winter=Ed_winter(1:4)/(cop_winter*Phpwh); %加熱所需時間 Heating time
Tnew=ceil(Tused); %把時間單位變整數     Round the time unit
Tnew_2=ceil(Tused_winter); %把時間單位變整數    Round the time unit

%-----------------------%
E0=3.3;
Qmax=30;
R=0.01;
k=0.007;
A=0.26;
B=125;
%PV module specification
x=0.0155; %parameter of Tc equation
y=0.036;  %parameter of Tc equation
z=0.021;   %parameter of Tc equation
Isc=4.8;    %Short circuit current
Is=0.065*0.01; %short circuit current parameter
%=======================%
PV_cap=80*200;
PV0=80;
PV=PV0:80:PV_cap;
PV_time=PV_cap/PV0;
Ihp=0;
iL=(load_hour*1000)/12;
BTY_cap=720*50;
BTY0=0;
% BTY=2880;
BTY=BTY0:720:BTY_cap;
BTY_time=(BTY_cap/720)+1;
S_min=0.2*BTY;
S_initial=0.6*BTY;
Lh =0.001;
Eb =1;
%Vb=10;

S=zeros(8760,PV_time);
buy=zeros(8760,PV_time);
extra=zeros(8760,PV_time);
save=zeros(8760,PV_time);
Iout=zeros(8760,PV_time);
Ib=zeros(8760,PV_time);
Gnew_hour=zeros(8760,1);
Tc=zeros(8760,1);
Inew=zeros(8760,1);
Cost_operation=zeros(BTY_time,PV_time);

%=========================Cost===================================%
C_pv=50; % 1W 50 NTD
Cost_pv=PV*C_pv; %太陽能成本 Solar cost
Cost_maint=Cost_pv*0.1; %維修成本   Maintenance costs
C_bty=5000; % 720W 5000 NTD  
Cost_bty=(BTY/720)*C_bty*5; %電池成本   Battery cost
C_hpwh=1;
Cost_inv=30000*4; % 5000W 80k NTD 
Cost_hpwh=50000;
Cost_tank=0;
Inv=ceil(PV/5000);%再生合成容量每5KW搭配1台5KW Inv  For every 5KW of regenerative synthesis capacity, 1 set of 5KW Inv


%=========================Cost===================================%

% one year operation

for a1=1:8760
   if G_hour(a1)==0
      Gnew_hour(a1)=1;
   else
      Gnew_hour(a1)=G_hour(a1);
   end
   Gnew_hour=Gnew_hour';
   Tc(a1)=Temp_hour(a1)+(x*(1+y*Temp_hour(a1))*(1-z*10))*Gnew_hour(a1);   %solar cell temperature  %Gnew supposed to same for bpth Tc and Current
   Inew(a1)=(Isc*(1+Is*(Tc(a1)-25)))*(G_hour(a1)/1000);   % PV current at max. point
   if Inew(a1)>Isc
      Inew(a1)=Isc;
   end
      
end
Cost_HP=74900; %74900 78000 86500 89800
%這裡是熱泵計算------------------Here is the heat pump calculation--------------------
for a=1:8760
     
    if a>=1417 && a<=3624  %spring春天
            T_s=(1417+(Time_use(1))-Tnew(1):24:3624);
            t1=length(T_s);
            for j=1:t1
                if a==T_s(j) && Tnew(1)==1
                    T_hp_s(a)=Phpwh;
                elseif a==T_s(j) && Tnew(1)==2
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                end
            end

        elseif a>=3625 && a<=5832 %summer夏天
            T_s=(3625+(Time_use(1))-Tnew(1):24:5832);
            t2=length(T_s);
            for j1=1:t2
                if a==T_s(j1) && Tnew(1)==1
                    T_hp_s(a)=Phpwh;
                elseif a==T_s(j1) && Tnew(1)==2
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                end
            end

        elseif a>=5833 && a<=8016 % autumn秋天
            T_s=(5833+(Time_use(1))-Tnew(1):24:8016);
            t3=length(T_s);
            for j2=1:t3
                if a==T_s(j2) && Tnew(1)==1
                    T_hp_s(a)=Phpwh;
                elseif a==T_s(j2) && Tnew(1)==2
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                end
            end

        elseif a>8017  % winter
            T_s=(8017+(Time_use(1))-Tnew_2(1):24:8760);
            t4=length(T_s);
            for j3=1:t4
                if a==T_s(j3) && Tnew_2(1)==1
                    T_hp_s(a)=Phpwh;
                elseif a==T_s(j3) && Tnew_2(1)==2
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                elseif a==T_s(j3) && Tnew_2(1)==3
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                    T_hp_s(a+2)=Phpwh;
                end
            end

        elseif a<1416  % winter
            T_s=(1+(Time_use(1))-Tnew_2(1):24:1416);
            t5=length(T_s);
            for j4=1:t5
                if a==T_s(j4) && Tnew_2(1)==1
                    T_hp_s(a)=Phpwh;
                elseif a==T_s(j4) && Tnew_2(1)==2
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                elseif a==T_s(j4) && Tnew_2(4)==3
                    T_hp_s(a)=Phpwh;
                    T_hp_s(a+1)=Phpwh;
                    T_hp_s(a+2)=Phpwh;
                end
             end

    end
end
%-------------------------------------------------------------%
Ihp=(T_hp_s*1000)/12;
%=========================TOU====================================%

CE=11.9968; %平均電價  %TW 2.8530 JP 7.6911 GER 11.9968 UK 6.537 USA 3.5191 Average electricity price
CE_rate=load('tou.txt');
E_hour=CE*CE_rate(1:8760);
%=========================TOU====================================%
S_max(1:BTY_time)=0;
 for d=1:BTY_time
     S_max(d)=BTY(d);
    for c=1:PV_time
        if PV(c)>=10000;
            FIT=6.62; %太陽能躉購電價 % TW 6.4190 JP 11.15 GER 6.62 UK 6.2 USA 6.5  Single purchase price of solar energy
        else
            FIT=6.98; %太陽能躉購電價 % TW 7.1602 JP 10.9 GER 6.98 UK 6.68 USA 6.5  Single purchase price of solar energy
        end
      for b=1:8759
          if isnan(S(b,c))
              S(b,c)=0;
          end
        Iout(b,c)=Inew(b)*(PV(c)/80);
        Ib(b,c)=Iout(b,c)-iL(b)-Ihp(b);

%         S_max=BTY;
        u = (S(b,c)/S_max(d));    % 電池目前充電狀態與最大充電之比  The ratio of the battery's current state of charge to the maximum charge
     Rch =6*((0.785+0.1309/(1.06-u)) /(BTY(d)));      %  充電電阻    Charging resistance
       Rdch =6*(((0.19+0.1037)/(u-0.14)) /(BTY(d)));    %  放電電阻    Discharge resistance
        Vch=(2+(0.148*u))*6;%充電電壓    Charging voltage
        Vdch=(1.926+(0.124*u))*6;%放電電壓   Discharge voltage
              if b==1
                  S(b,c)=S_initial(d);
              end 
           if Ib(b,c)>0
                if S(b,c)==0
                    S(b+1,c)=0;
                    save(b+1,c)=iL(b)*12;
                    extra(b+1,c)=Ib(b,c)*12;
                    buy(b+1,c)=0;
                end
%                  if S(b,c)>=S_min && S(b,c)<=S_max
                if S(b,c)<=S_max(d)
                 S(b+1,c) = S(b,c)*(1-Lh)+(Eb*(Vch*Ib(b,c)-Rch*(Ib(b,c)^2)));%蓄電池充電   Battery charging
                 save(b+1,c)=iL(b)*12;
                        if S(b+1,c)>S_max(d)
                           extra(b+1,c)=S(b+1,c)-S_max(d);
                           buy(b+1,c)=0;
                           S(b+1,c)=S_max(d);     
                        end


                end
            elseif Ib(b,c)<0
                  if S(b,c)==0
                        S(b+1,c)=0;
                        buy(b+1,c)=-Ib(b,c)*12;
                        save(b+1,c)=0;
                        extra(b+1,c)=0;
                  end
                    if S(b,c)>S_min(d) && S(b,c)<=S_max(d)
                    S(b+1,c) = S(b,c)*(1-Lh)+(Eb*(Vdch*Ib(b,c)-Rdch*(Ib(b,c)^2))); %蓄電池供電   Battery powered
                         if S(b+1,c)<=S_min(d)
                             buy(b+1,c)=(-Ib(b,c)*12)/1000;
                             extra(b+1,c)=0;
                             S(b+1,c)=S(b,c)*(1-Lh);
                             save(b+1,c)=0;
                         else
                             save(b+1,c)=-Ib(b,c)*12;
                         end
                    elseif S(b,c)<=S_min(d)
                             buy(b+1,c)=(-Ib(b,c)*12)/1000;
                             extra(b+1,c)=0;
                             S(b+1,c)=S(b,c)*(1-Lh);
                             save(b+1,c)=0;

%                     elseif S(b,c)<=0
%                         buy(b+1,c)=-Ib(b,c)*12;
%                         save(b+1,c)=0;                      
                   end
           end

      end
      
total_save(c)=sum((save(1:8760,c)/1000).*E_hour);
total_extra(c)=sum((extra(1:8760,c)/1000));  %除1000 單位 kWh   kWh Divide 1000 kWh
total_buy(c)=sum(buy(1:8760,c).*E_hour);

Cost_operation(d,c)=Cost_bty(d)+(Cost_inv*Inv(c))+Cost_maint(c)+Cost_HP;
C_save(d,c)=total_save(c)*20; %20年 節省電費的供電所得   20 years of electricity income from electricity savings
C_fit(d,c)=total_extra(c)*20*FIT; %20年 FIT費率回賣的售電所得    20-year FIT rate of electricity sales income1
C_buy(d,c)=total_buy(c)*20;   %20年 從市電購電的成本    Cost of purchasing electricity from mains in 20 years1
 

A_PY(d,c)=(Cost_pv(c)+Cost_operation(d,c)+C_buy(d,c))/((C_save(d,c)+C_fit(d,c))/20);

    end
       buy=buy-buy;
       extra=extra-extra;
       save=save-save; 
 end
%========================%

m=min(A_PY);
mm=min(m);
[bty_cap,pv_cap]=find(A_PY==mm);
c_opr=Cost_operation(bty_cap,pv_cap)/1000;
c_sold=C_fit(bty_cap,pv_cap)/1000;
c_bought=C_buy(bty_cap,pv_cap)/1000;

fprintf('最小值位置為The minimum position is:%d %d\n電池和太陽能容量為(w)The battery and solar capacity are(w):%d %d\n回收年限Payback= %2.2f \noperation cost = %5.3f\nExport Tariff = %5.3f\nElectricity Bought = %5.3f\n',bty_cap,pv_cap,(bty_cap-1)*720,pv_cap*80,mm,c_opr,c_sold,c_bought);

fprintf(' %d\t  %d\t%5.3f\t%5.3f\t%5.3f\t%2.2f\n',pv_cap*80,(bty_cap-1)*720,c_opr,c_sold,c_bought,mm);




















toc