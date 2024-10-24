function [X,dX,eqn,dXright] = MToODE(n,M,B)
    syms X [n 1]  
    syms dXright [n 1] 
    
    dXright = M*X+B;
 
    syms dX [n 1] 
    eqn = dX==dXright; 
end