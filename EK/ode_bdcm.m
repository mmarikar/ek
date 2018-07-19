function integrate = ode_bdcm(stateval, t)

%ODE section for Octave tne compartment model
%Rory Conolly
%Started January 4, 2018
%Last edit July 8, 2018

%June 27, 2018
%Mo Marikar

%In Octave, the results of integrating a differential equation (i.e., the
% simulated data) are stored in the matrix "stateval". In this model, 
% there are ODEs for each compartment
% Each column of stateval describes changes in a state variable
% with time. Each row of stateval holds the simulated data at a given point
% in simulated time.

global c inhalation oral iv dermal 
%integrate = zeros(1,13);

%-----ALGEBRAIC EQUATIONS-------------------------------------------------------
%These algebraic equations convert the amounts provided in stateval by the
%solution of the ODE's and convert to tissue and venous blood concentrations
%that are needed in the ODEs.

% #2 Lumen of GI tract
A_lumen = stateval(2); % (mg)

% #3 Dermal dosing volume
A_dose_volume = stateval(3); % (mg)
conc_dose_volume = A_dose_volume/c.dermal_dose_volume; % (mg/L)

% #5 Richly perfused
A_RP = stateval(5); % (mg)
CRP = A_RP/c.VRP;   % (mg/L)                 
CVRP = CRP/c.Pr;    % (mg/L)

% #6 Poorly perfused
A_PP = stateval(6); % (mg)
CPP = A_PP/c.VPP;   % (mg/L)                 
CVPP = CPP/c.Pr;    % (mg/L)

% #8 Liver 
A_liver = stateval(8); % (mg) 
CL = A_liver/c.VL;     % (mg/L)
CVL = CL/c.Pl_b;       % (mg/L)

% #9 Fat
A_fat = stateval(9); % (mg)
CF = A_fat/c.VF;     % (mg/L)
CVF = CF/c.Pl_b;     % (mg/L)

% #10 Bladder tissue
A_bladder = stateval(10); % (mg)
CY = A_bladder/c.VY;     % (mg/L)
CVY = CY/c.Py;           % (mg/L)

% #11 Skin
A_skin = stateval(11); % (mg)
CSK = A_skin/c.VSK;    % (mg/L)
CVSK = CSK/c.Psk;      % (mg/L)
flux_into_skin = c.dermal_perm * c.SA_exposed * conc_dose_volume * 1.e-3; 
                                   %Flux into skin (mg/hr) note 1.e-3 L/cm^3

% #12 GI tract tissue
A_GI = stateval(12);   % (mg)
CGI = A_GI/c.VGI;      % (mg/L)
CVGI = CGI/c.Pgi;      % (mg/L)

% #13 Venous blood
A_venous_blood = stateval(13); % (mg) 
CV = A_venous_blood/c.VB;      % (mg/L)

%Conc. in arterial blood (steady state)
CA = (c.QC*CV + c.QP*c.CI) / (c.QC + (c.QP / c.Pbl_a)); %(mg/L

% Conc exhaled
CX = CA/c.Pbl_a ;%(mg/L) 

%-------DIFFERENTIAL EQUATIONS--------------------------------------------------

% #1 Dosing
if inhalation
    integrate(1) = c.QP * c.CI; %(mg/hr)
elseif oral
    integrate(1) = c.rate_oral; %(mg/hr)
elseif iv
    integrate(1) = c.rate_IV; %(mg/hr)
elseif dermal % 
    %integrate(1) = flux_into_skin; % (mg/hr)
    integrate(1) = flux_into_skin; % (mg/hr)
endif

% #2 Rate of change of chemical in lumen of GI tract
%This is where an oral dose is deposited
integrate(2) = c.rate_oral - A_lumen * c.k_oral_dose; %(mg/hr)

% #3 Rate of change of chemical in dermal dose volume
integrate(3) = flux_into_skin;

% #4 Rate of chemical exhalation  
integrate(4) = c.QP * CX;%(mg/hr)

% #5 Rate of change of chemical in richly perfused
integrate(5) = c.QRP * (CA - CVRP) ;%(mg/hr)

% #6 Rate of change of chemical in poorlt (slowly) perfused
integrate(6) = c.QPP * (CA - CVPP) ;%(mg/hr)

% #7 Rate of chemical metabolism in liver
RAM = c.Vmax * CVL/(c.Km + CVL); %(mg/hr)
integrate(7) = RAM;%(mg/hr) 

% #8 Rate of change of chemical in liver 
%Note that liver gets venous blood from GI as well as arterial blood
integrate(8) = c.QL*CA + c.QGI*CVGI - (c.QL+c.QGI)*CVL - RAM; %(mg/hr)             

% #9 Rate of change of chemical in fat
integrate(9) = (c.QF * CA) - (c.QF * CVF);%(mg/hr)

% #10 Rate of change of chemical in bladder tissue
integrate(10) = c.QY * (CA - CVY);%(mg/hr)

% #11 Rate of change of chemical in skin
integrate(11) = c.QSK * (CA - CVSK) + flux_into_skin; %(mg/hr)

% #12 Rate of change of chemical in tissue of the GI tract
integrate(12) = c.QGI * (CA - CVGI) + A_lumen * c.k_oral_dose; %(mg/hr)

% #13 Rate of change of chemicalin in venous blood
integrate(13) = [ CVL * (c.QL+c.QGI) + CVRP * c.QRP + CVPP * c.QPP ...
+ CVF * c.QF + CVY * c.QY + CVSK * c.QSK + c.rate_IV - CV * c.QC] ;%(mg/hr)

%End of ode file
