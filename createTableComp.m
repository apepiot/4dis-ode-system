function tableComp = createTableComp(m,n,p,boxesM,boxesN,boxesP,names_mnp)
if ~(sum(ismember(m,0:4)==1) && sum(ismember(n,0:1)==1) && sum(ismember(p,0:1))==1 && (n+p+m>=1))
    error('m, n or p is too low or too big')
end

baseComp=cell(1,m+n+p);

if n==1             %model: HIV x...
    baseComp{1}=boxesN;
    if p==1         %model: HIV x syph. x...
        baseComp{2}=boxesP;
        if m==0     %model: HIV x syph.
            %nothing to add
        else        %model: HIV x syph x STI1 x...x STIm
            for i=1:m
                baseComp{2+i}=boxesM;
            end
        end
    else    
        if m==0     %model: HIV
            %nothing to add
        else        %model: HIV x STI1 x...x STIm
            for i=1:m
                baseComp{1+i}=boxesM;
            end
        end
    end
else
    if p==1         %model: syphilis x... 
        baseComp{1}=boxesP;
        if m==0     %model: syphilis
            %nothing to add
        else        %model: syphilis x STI1...x STIm
            for i=1:m
                baseComp{1+i}=boxesM;
            end
        end
    else            %model: STI1 x...x STIm
        for i=1:m
                baseComp{i}=boxesM;
        end
    end
end

if (n+p+m>1)
    combs = combPerso(baseComp{:});
else
    combs = baseComp{:}';
end

tableComp = array2table(combs,'VariableNames',names_mnp);
            
end

