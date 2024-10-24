function [M] = M_SEIIS(Lambda,p,nu,gamma0,sigma,b,rho,mu)

%     dS  = b - lambda*S + rho*E + (gamma0+nu)*IS + (rho+nu)*IA - mu*S;
%     dE  = lambda*S - (sigma+rho)*E - mu*E;
%     dIA = (1-p)*sigma*E - (rho+nu)*IA - mu*IA;
%     dIS = p*sigma*E - (gamma0+nu)*IS - mu*IS;

        %S          %E                  %IA             %IS
    M = [-Lambda-mu, rho,               nu+rho,         gamma0+nu;...
        Lambda,     -(sigma+rho+mu),    0,              0;...
        0,          (1-p)*sigma,        -(nu+rho+mu),   0;...
        0,          p*sigma,            0,              -(gamma0+nu+mu)];
end