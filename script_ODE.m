clear all;

% This code generates the ODE system of the SICTPxSEIIISxSEIISxSEIIS model 
% with combined testing.
% It would need to be adapted for another purpose (e.g., generating 
% SICTPxSEIIISxSEIIS).

% calls MToODE, M_SEIIIS, M_SEIIS, M_SICTP, createTableComp

n=1; %number of diseases following the SICTP framework (i.e., HIV)
p=1; %number of diseases following the SEIIIS framework (i.e., syphilis)
m=2; %number of diseases following the SEIIS framework (i.e., Ct, Ng)

syms mu b;
syms Lambdac; syms nuc; syms epsc; syms sigmac; syms gammac;
syms Lambdag; syms nug; syms epsg; syms sigmag; syms gammag;
syms Lambdah thetah sigmah ph eta_h_prep zetah
syms Lambdas sigmas taus thetas gamma1s gamma3s nus

% targeted testing rates
syms rho_h rho_s rho_c rho_g

% testing rates under PrEP
syms eta_c_prep eta_g_prep eta_s_prep

%testing rates under ART
syms eta_c_art eta_g_art eta_s_art

%combined testing rates of 2 diseases and more
syms rho_hs rho_hc rho_hg rho_sc rho_sg rho_cg
syms rho_hsc rho_hsg rho_hcg rho_scg
syms rho_hscg

syms VTunderART %boolean, 1 if VT can be practice under ART, 0 otherwise

nDis = m+n+p;       %number of infections in the model
dis = ["HIV","syph","Ct","Ng"];
dis = dis([n==1,p==1,m>=1,m==2]);

nbBoxesSICTP  = 7;  %number of boxes in the baseline SICTP model
nbBoxesSEIIS  = 4;  %number of boxes in the baseline SEIIS model
nbBoxesSEIIIS = 5;  %number of boxes in the baseline SEIIIS model

nbCompartments = nbBoxesSICTP^n*nbBoxesSEIIS^m*nbBoxesSEIIIS^p;

% creating all the compartments
% a compartment is defined by a n-tuple (x1,x2,x3,...xnDis)
no_boxesSICTP =  1:nbBoxesSICTP;     %SICTP  1:S,2:I,3:C,4:P,5:Ip,6:Cp,7:T
no_boxesSEIIIS = 1:nbBoxesSEIIIS;    %SEIIIS 1:S,2:E,3:I1,4:I2,5:I3
no_boxesSEIIS =  1:nbBoxesSEIIS;     %SEIIS  1:S,2:E,3:IA,4:IS

boxesSICTP  = ["S","I","C","P","Ip","Cp","T"]; %should be the same order than in the ODE_SICTPrEP.m
boxesSEIIIS = ["S","E","I1","I2","I3"];        %should be the same order than in the ODESEIIIS.m
boxesSEIIS  = ["S","E","IA","IS"];             %should be the same order than in the ODESEIIS.m

%Create the table of compartments
tabComp = createTableComp(m,n,p,boxesSEIIS,boxesSICTP,boxesSEIIIS,dis);

tabComp.no = [1:nbCompartments]';


%% Vector pi containing new individuals rates: (pi=b, here)
syms B [nbCompartments 1]; %contains other rate, not variable dependent (e.g., pi)
B(:) = 0;
if n==1
    B(sum(table2array(tabComp(:,1:(n+m+p)))==repmat("S",1,n+m+p),2)==n+m+p) = (1-ph)*b;
    B(sum(table2array(tabComp(:,1:(n+m+p)))==["P",repmat("S",1,m+p)],2)==n+m+p) = ph*b;
else
    B(sum(table2array(tabComp(:,1:(m+p)))==repmat("S",1,n+m+p),2)==n+m+p) = b;
end

%% Fill in the matrix M corresponding to the ODE system dX/dt=MX+B

% Initialization of M
M = sym(zeros(nbCompartments) - mu*eye(nbCompartments));

%Focus on each disease progression
for INF=dis
    otherDis = dis(dis~=INF);
    if contains(INF,'HIV')
        boxesInf = boxesSICTP;
        nHIV=n-1; pSYPH=p; mSTI=m;
    elseif contains(INF,'syph')
        boxesInf = boxesSEIIIS;
        nHIV=n; pSYPH = p-1; mSTI=m;
    elseif contains(INF,'Ct') || contains(INF,'Ng')
        boxesInf = boxesSEIIS;
        nHIV=n; pSYPH = p; mSTI = m-1;
    end
    
%     %find among dis\inf how many disease follow each framework
%     idx  = strfind(otherDis(:,:),'Ct','ForceCellOutput',true);   mSTI=max([find([idx{:}]),0]);
%     idx  = strfind(otherDis(:,:),'Ng','ForceCellOutput',true);   mSTI=mSTI+max([find([idx{:}]),0]);
%     idx  = strfind(otherDis(:,:),'HIV','ForceCellOutput',true);  nHIV=max([find([idx{:}]),0]);
%     idx  = strfind(otherDis(:,:),'syph','ForceCellOutput',true); pSYPH=max([find([idx{:}]),0]);
    otherDiseaseStatesConstant = createTableComp(mSTI,nHIV,pSYPH,boxesSEIIS,boxesSICTP,boxesSEIIIS,otherDis);
    for i=1:size(otherDiseaseStatesConstant,1)
        %for every combination of disease states (other than INF), applies the matrix generating the ODE system of INF
        otherStates = otherDiseaseStatesConstant(i,:);
        T = innerjoin(otherStates,tabComp); %sub-table with otherStates and all the states of HIV

        %makes sure that the order of the states of INF is good (i.e., same that in the ODE system)
        [~, idx] = ismember(table2array(T(:,INF)), boxesInf');
        [~, sortorder] = sort(idx); newT = T(sortorder,:);

        %matrix of the ODE system for INF without including rho, mu, pi.
        if contains(INF,'HIV')
            Mi = M_SICTP(Lambdah,thetah,sigmah,0,zetah,eta_h_prep,0,0,0);
        elseif contains(INF,'syph')
            Mi = M_SEIIIS(Lambdas,sigmas,taus,thetas,0,gamma3s,0,0,0,0);
        elseif contains(INF,'Ct')
            Mi = M_SEIIS(Lambdac,epsc,nuc,gammac,sigmac,0,0,0);
        elseif contains(INF,'Ng')
            Mi = M_SEIIS(Lambdag,epsg,nug,gammag,sigmag,0,0,0);
        end
        M(newT.no,newT.no) = M(newT.no,newT.no) + Mi;
    end
end


%% Adds voluntary testing rates rho_xxx
%Symptomatic individuals for STIs test because of symptoms and not with voluntary testing.
%Individuals on PrEP (P,Ip,Cp) test only routinely, not voluntarily, eta_i_prep.

% For all combination of infections *except if individuals are on PrEP*,
% we need to add combined voluntary testing rate
% e.g., for the given [I(h),E(s),IA(c),E(g)] where X(i) corresponds to the stage X for infection i.
% then, when 
% HIV and syphilis are tested together, diagnosed indiviudals go to S(h)S(s)IA(c)E(g),
% Ct tested alone, targeted testing goes to [I(h),E(s),S(c),E(g)]
% Ng -------------------------------------- [I(h),E(s),IA(c),S(g)]

%The following table displays which kit is suited to diagnose which infection
CVTcomb = table({["HIV"];["syph"];["Ct"];["Ng"];["HIV","syph"];["HIV","Ct"];["HIV","Ng"];["syph","Ct"];["syph","Ng"];["Ct","Ng"];...
    ["HIV","syph","Ct"];["HIV","syph","Ng"];["HIV","Ct","Ng"];["syph","Ct","Ng"];...
    ["HIV","syph","Ct","Ng"]},...
    [1;0;0;0;1;1;1;0;0;0;1;1;1;0;1],...
    [0;1;0;0;1;0;0;1;1;0;1;1;0;1;1],...
    [0;0;1;0;0;1;0;1;0;1;1;0;1;1;1],...
    [0;0;0;1;0;0;1;0;1;1;0;1;1;1;1],...
    [rho_h;rho_s;rho_c;rho_g;rho_hs;rho_hc;rho_hg;rho_sc;rho_sg;rho_cg;rho_hsc;rho_hsg;rho_hcg;rho_scg;rho_hscg],...
    [1:15]',...
    'VariableNames',{'kit','isHIV','issyph','isCt','isNg','rho','kitNo'});

% List of combined testing tools by infections
CVTcombHIV = CVTcomb(logical(CVTcomb.isHIV),:);
CVTcombS = CVTcomb(logical(CVTcomb.issyph),:);
CVTcombCt = CVTcomb(logical(CVTcomb.isCt),:);
CVTcombNg = CVTcomb(logical(CVTcomb.isNg),:);

%We list combined testing kits without Ct and Ng
CVTcombHIV_without_Ct = CVTcombHIV(CVTcombHIV.isCt==0,:);
CVTcombHIV_without_Ng = CVTcombHIV(CVTcombHIV.isNg==0,:);
CVTcombHIV_without_Ct_and_Ng = CVTcombHIV_without_Ct(CVTcombHIV_without_Ct.isNg==0,:);
CVTcombS_without_Ct = CVTcombS(CVTcombS.isCt==0,:);
CVTcombS_without_Ng = CVTcombS(CVTcombS.isNg==0,:);
CVTcombS_without_Ct_and_Ng = CVTcombS_without_Ct(CVTcombS_without_Ct.isNg==0,:);
CVTcombCt_without_Ng = CVTcombCt(CVTcombCt.isNg==0,:);
CVTcombNg_without_Ct = CVTcombNg(CVTcombNg.isCt==0,:);


%Compartments where individuals are not infectious for any infections
if n==1
    compSSSS = tabComp(sum(table2array(tabComp(:,1:n+m+p))==repmat("S",1,n+m+p),2)==n+m+p,:);
    compPSSS = tabComp(sum(table2array(tabComp(:,1:n+m+p))==["P",repmat("S",1,m+p)],2)==n+m+p,:);
    compTSSS = tabComp(sum(table2array(tabComp(:,1:n+m+p))==["T",repmat("S",1,m+p)],2)==n+m+p,:);
else
    error('not done')
end

% Determining for each compartment, if voluntary testing is allowed for each kit 
VT_table = zeros(nbCompartments,size(CVTcomb,1));
%VT_table is a 560x15 matrix with VT_table(i,j)>0 if voluntary testing
%is allowed in the compartment i with the kit j.

for i=1:nbCompartments
    currentComp = tabComp(i,:);
    if sum(currentComp.no==[compSSSS.no,compPSSS.no,compTSSS.no])>0 %fully (non infected/non infectious)
        %do nothing, no VT testing in these compartments
    else
        if currentComp.HIV == "P" || currentComp.HIV == "Ip" || currentComp.HIV == "Cp"
            % no voluntary testing under PrEP
        else
            if currentComp.Ct == "IS" || currentComp.Ng == "IS"        
                %voluntary testing only if individuals are asymptomatic for the kit considered
                if currentComp.Ct == "IS" && currentComp.Ng == "IS"
                    if any(currentComp.HIV==["I","C"])    
                        VT_table(i,CVTcombHIV_without_Ct_and_Ng.kitNo) = VT_table(i,CVTcombHIV_without_Ct_and_Ng.kitNo)+1;
                    end
                    if any(currentComp.syph==["E","I1","I2","I3"])
                        VT_table(i,CVTcombS_without_Ct_and_Ng.kitNo) = VT_table(i,CVTcombS_without_Ct_and_Ng.kitNo)+1;
                    end
                elseif currentComp.Ct == "IS" && ~(currentComp.Ng == "IS")
                    if any(currentComp.HIV==["I","C"])    
                        VT_table(i,CVTcombHIV_without_Ct.kitNo) = VT_table(i,CVTcombHIV_without_Ct.kitNo)+1;
                    end
                    if any(currentComp.syph==["E","I1","I2","I3"])
                        VT_table(i,CVTcombS_without_Ct.kitNo) = VT_table(i,CVTcombS_without_Ct.kitNo)+1;
                    end
                    if any(currentComp.Ng==["E","IA"])
                        VT_table(i,CVTcombNg_without_Ct.kitNo) = VT_table(i,CVTcombNg_without_Ct.kitNo)+1;
                    end        
                elseif ~(currentComp.Ct == "IS") && currentComp.Ng == "IS"
                    if any(currentComp.HIV==["I","C"])    
                        VT_table(i,CVTcombHIV_without_Ng.kitNo) = VT_table(i,CVTcombHIV_without_Ng.kitNo)+1;
                    end
                    if any(currentComp.syph==["E","I1","I2","I3"])
                        VT_table(i,CVTcombS_without_Ng.kitNo) = VT_table(i,CVTcombS_without_Ng.kitNo)+1;
                    end
                    if any(currentComp.Ct==["E","IA"])
                        VT_table(i,CVTcombCt_without_Ng.kitNo) = VT_table(i,CVTcombCt_without_Ng.kitNo)+1;
                    end 
                end
            else
                if any(currentComp.HIV==["I","C"])
                    VT_table(i,CVTcombHIV.kitNo) = VT_table(i,CVTcombHIV.kitNo)+1;
                end
                if any(currentComp.syph==["E","I1","I2","I3"])
                    VT_table(i,CVTcombS.kitNo) = VT_table(i,CVTcombS.kitNo)+1;
                end
                if any(currentComp.Ct==["E","IA"])
                    VT_table(i,CVTcombCt.kitNo) = VT_table(i,CVTcombCt.kitNo)+1;
                end
                if any(currentComp.Ng==["E","IA"])
                    VT_table(i,CVTcombNg.kitNo) = VT_table(i,CVTcombNg.kitNo)+1;
                end
                if any(currentComp.HIV==["T"])
                    VT_table(i,CVTcombHIV.kitNo) = VT_table(i,CVTcombHIV.kitNo)+1000;
                end
            end
        end
    end
end

% Correspondance between the infection stage of HIV and where individuals
% go when they test
HIVflow_hiv = table( ["S";"I";"C";"P";"Ip";"Cp";"T"], ["S";"T";"T";"P";"T";"T";"T"], 'VariableNames',{'outState','inState'});

for i=1:nbCompartments
    currentComp = tabComp(i,:);
    for k=1:15
        if VT_table(i,k)>=1
            % Finding the reception compartment of the rate rho
            currentKit = CVTcomb.kit(k);
            otherFixedStates = currentComp(:,setdiff(dis,currentKit{:}));
            receptComp = otherFixedStates;
            for inf=currentKit{:}
                if inf ~= "HIV"
                    receptComp.(inf) = "S";
                else  %si l'infection est HIV
                    receptComp.HIV = HIVflow_hiv(HIVflow_hiv.outState==currentComp.HIV,:).inState;
                end
            end
            receiverComp = innerjoin(tabComp,receptComp);
            
            if VT_table(i,k)<1000
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no) - min(VT_table(i,k),1)*CVTcomb(k,:).rho ; %min(...,1) to not count twice VT rates
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+min(VT_table(i,k),1)*CVTcomb(k,:).rho;
            else
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no) - VTunderART*min(VT_table(i,k),1)*CVTcomb(k,:).rho ; %min(...,1) to not count twice VT rates
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+VTunderART*min(VT_table(i,k),1)*CVTcomb(k,:).rho;
            end
        end
    end
    disp(i)
end

%% Adding mandatory/recommended testing for STIs under PrEP and ART
%N.B. eta_h_prep already taking into account above
for k=1:nbCompartments
    currentComp = tabComp(k,:);
    if sum(currentComp.no==[compSSSS.no,compPSSS.no,compTSSS.no])==0
        if 1 
            if currentComp.HIV=="P" || currentComp.HIV=="Ip" || currentComp.HIV=="Cp"
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_c_prep;
                recepComp = currentComp(:,1:4); recepComp.Ct ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_c_prep;
                
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_g_prep;
                recepComp = currentComp(:,1:4); recepComp.Ng ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_g_prep;
                
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_s_prep;
                recepComp = currentComp(:,1:4); recepComp.syph ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_s_prep;
                
            elseif currentComp.HIV=="T"
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_c_art;
                recepComp = currentComp(:,1:4); recepComp.Ct ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_c_art;
                
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_g_art;
                recepComp = currentComp(:,1:4); recepComp.Ng ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_g_art;
                
                M(currentComp.no,currentComp.no) = M(currentComp.no,currentComp.no)-eta_s_art;
                recepComp = currentComp(:,1:4); recepComp.syph ="S";
                receiverComp = innerjoin(tabComp,recepComp);
                M(receiverComp.no,currentComp.no) = M(receiverComp.no,currentComp.no)+eta_s_art;
            end
        end
    end
end


[X,dX,eqn,dXright] = MToODE(nbCompartments,M,B);
