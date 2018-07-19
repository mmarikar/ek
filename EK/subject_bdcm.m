%Rory Conolly
%Mohideen Marikar
%July 5, 2018
%Much of this code by Elaina Kenyon
%===============================================================================

%Body weight 
BW = 74.0;%(kg) 
%Height
Height = 178; %(cm) @ 5' 10"
%Total skin surface area 
SA = 0.0239*(Height**0.417)*(BW**0.517) ;%(m2)

% Compartment volumes
%Note:  body currently divided up 80/20 for poorly/richly perfused.
FVliver = 0.026;    %Fraction BW as liver
FVf = 0.10;         %Fraction as fat
FVbd = 0.079;       % Fraction of BW as blood (L/kg)
FVrp = 0.20;        % Fraction BW as richly perfusd tissue
FVpp = 0.80;        % Fraction BW as poorly perfusd tissue
FVgi = 0.0165;      % Fraction BW as gi tract
FVy = 0.000643;     % Fraction BW as urinary bladder tissue
Lsk = 0.002;        % skin thickness (meters), 2 mm

c.VB  = FVbd*BW; % Blood volume (L). There is no arterial blood compartment, so
%we assign all the blood volume to the venous compartment
c.VL = FVliver*BW ;% Liver volume (L)                   
c.VF = FVf*BW;% Fat volume (L)  
c.VY = FVy*BW;% Bladder volume (L) 
c.VSK = Lsk*SA*1000;% Skin volume (L). 1000L occupies 1 cubic meter
c.VGI = FVgi*BW;% GI Tract volume
c.VRP = FVrp*BW - c.VL - c.VB - c.VY - c.VGI;% Richly perfused volume
c.VPP = FVpp*BW - c.VF - c.VSK;% Poorly perfused volume

%Eror checking for tissue volumes
total_tissues_vol = c.VL + c.VRP + c.VPP + c.VF + c.VB + c.VGI + c.VY + c.VSK;
printf ('total tissues volume (Kg) = %.3f\n', total_tissues_vol);
Volbalance = BW - c.VB - c.VY -c.VL - c.VGI - c.VF - c.VSK - c.VRP ...
             - c.VPP ; % test for Volume Balance
printf ('Volume balance is %.10e\n', Volbalance);
                % scientifc notation, 10 digits after the dot

%Breathing rate and cardiac output
% Human alveolar ventilation rate
c.QPC = 212.4 ;%(L/H - m^2 SA)
%QPC to Cardiac Output ratio
c.RQPCO = 0.8 ; 
%Deadspace fraction
c.Deadspace = 0.238 ;
%alveolar ventilation rate
c.QP = c.QPC * SA * (1-c.Deadspace) ;%(L/H)
%cardiac output - flow of blood in the entire body
c.QC = c.QP/c.RQPCO;%(L/hr);

%Tissue blood flows as fractions of cardiac output
Fql = 0.09;     % Fraction blood flow to liver
Fqf = 0.05;     % Fraction blood flow to fat
Fqy = 0.00055;  % Fraction blood flow to urinary bladder
Fqrp = 0.75;    % Fraction bld flow to richly perfused
Fqpp = 0.25;    % Fraction bld flow to poorly perfused
Fqg = 0.16;     % Fraction blood flow to GI

%Liver
c.QL = Fql*c.QC;        %(L/hr)
%Fat
c.QF = Fqf*c.QC;        %(L/hr)
%Bladder
c.QY = Fqy*c.QC;        %(L/hr)
%Skin
Qsksa = 0.58;% Bllod flow to skin normalized to surface area (L/min/m2)
c.QSK = Qsksa*SA*60;    %(L/hr)
%Tissue of GI tract
c.QGI = Fqg*c.QC;       %(L/hr)
%Richly perfused
c.QRP = Fqrp*c.QC - c.QL - c.QY - c.QGI;    %(L/hr)
%Poorly perfused
c.QPP = Fqpp*c.QC - c.QF - c.QSK;           %(L/H)

%Error check for specification of flows
Flowbalance = c.QC - c.QL - c.QGI - c.QY - c.QRP - c.QF - c.QSK - c.QPP ; % test for blood flow balance
printf ('Blood flow balance is %.10e\n', Flowbalance);% scientifc notation, 10 digits after the dot

