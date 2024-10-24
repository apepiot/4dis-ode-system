no_dis = 1:4;    %numbering the infections
dis = ["HIV","syph","Ct","Ng"];
nbBoxesSICTP  = 7;  %number of boxes in the SICTP model
nbBoxesSEIIS  = 4;  %number of boxes in the SEIIS model
nbBoxesSEIIIS = 5;  %number of boxes in the SEIIIS model

nbCompartments = nbBoxesSICTP^1*nbBoxesSEIIS^2*nbBoxesSEIIIS^1;
% creating all the compartments
% a compartment is defined by a n-tuple (x1,x2,x3,...xnDis)
no_boxesSICTP =  1:nbBoxesSICTP;     %SICTP  1:S,2:I,3:C,4:P,5:Ip,6:Cp,7:T
no_boxesSEIIIS = 1:nbBoxesSEIIIS;    %SEIIIS 1:S,2:E,3:I1,4:I2,5:I3
no_boxesSEIIS =  1:nbBoxesSEIIS;     %SEIIS  1:S,2:E,3:IA,4:IS

boxesSICTP  = ["S","I","C","P","Ip","Cp","T"]; %should be sorted like in the ODE system of ODE_SICTPrEP.m
boxesSEIIIS = ["S","E","I1","I2","I3"];        %should be sorted like in the ODE system of ODESEIIIS.m
boxesSEIIS  = ["S","E","IA","IS"];             %should be sorted like in the ODE system of ODESEIIS.m

%Create the table of compartments
tabComp = createTableComp(2,1,1,boxesSEIIS,boxesSICTP,boxesSEIIIS,dis);
tabComp.no = [1:nbCompartments]';