function [M] = M_SEIIIS(Lambda,sigma,tau,theta,gamma10,gamma30,nu,b,rho,mu)
%   dS/dt   = \pi - \Lambda S + \rho E + \gamma_1(\rho) I_1 + \rho I_2 + (\nu+\gamma_3(\rho))I_3 - \mu S
% 	dE/dt   = \Lambda S - (\sigma+\rho+\mu) E 
% 	dI_1/dt = \sigma E - (\tau + \gamma_{1}(\rho) + \mu) I_1
% 	dI_2/dt = \tau I_1 - (\theta + \rho +\mu) I_2 
% 	dI_3/dt = \theta I_2  - (\nu + \gamma_3(\rho) + \mu) I_3

    %S,             E,              I1,                     I2,                 I3
    M = [-Lambda-mu,rho,            gamma10+rho,            rho,                (nu+gamma30+rho);...
        Lambda,     -(sigma+rho+mu),0,                      0,                  0 ;...
        0,          sigma,          -(tau+gamma10+mu+rho),  0,                  0;...
        0,          0,              tau,                    -(theta+rho+mu),    0;...
        0,          0,              0,                      theta,              -(nu+gamma30+rho+mu)];
end
