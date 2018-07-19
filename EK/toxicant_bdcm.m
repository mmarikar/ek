%Chemical-specific information
%Mohideen Marikar
%July 5, 2018

%Test chemical is bromodichloromethane (BDCM)

mw = 164;%Molecular weight (g/mol) for BDCM = 164
c.dermal_perm = 0.18; % Permeability of chemical into skin (cm/hr) (Xu 2002)

%Partition coefficients
c.Pbl_a = 15.97; % blood:airy 
c.Pl_b = 1;      % liver:blood
c.Pf = 33.2;     % Fat:blood
c.Py = 2.08;     % Bladder:blood
c.Psk = 2.91;    % Skin:blood
c.Pr = 1.93;     % Richly perfused:blood
c.Ps = 0.78;     % Slowly perfused:blood
c.Pgi = 1.93;    % GI tissue:blood

% Metabolized in liver by Michaelis-Menten kinetics
VmaxC = 41.3; %(mg/hr) 
c.Vmax = VmaxC*BW^0.75;%(mg/hr)
c.Km = 0.221; 	% BDCM Michelis Menten const (mg/l)