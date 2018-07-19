%PBPK model for exposure routes of inhalation, oral, iv, dermal 
% and the combination of dermal andinhalation exposures
%Coded in Octave
%Rory Conolly
%Started January 4, 2018
%Last edit July 8, 2018                
%Mo Marikar
%July 16, 2018
%Added checks for unimplemented routes of exposure for BDCM

%===============================================================================

%INITIAL

%Octave setup
clear all
start_time = clock;
clc
global c inhalation oral iv dermal
format compact
format short e
more off;
disp(["OCTAVE_VERSION " num2str(OCTAVE_VERSION)]);
disp('Starting...')

%LSODE is the algorithm that solves the differential equations
lsode_options("absolute tolerance",1e-12);
lsode_options("relative tolerance",1e-3);%Usually le-3
lsode_options("integration method","stiff");
lsode_options("maximum order", 5);
lsode_options("maximum step size", 0.01);
lsode_options("minimum step size", 1.e-15);

odefilename = 'ode_bdcm';

%===============================================================================
%Chemical-specific information
subject_bdcm % bromodichloromethane

%Physiological data for human
toxicant_bdcm



%===============================================================================
%Design of experiment

%Length of simulation (tstop) and interval for saving simulated
% data (cint)
tstop = 336;% (hr) - 2 weeks, no inhalation on week-ends
cint = 0.01;% (hr) 

%Routes of exposure
% Rory has implemented the combination route 
% of inhalation and dermal for BDCM
% on an Elaina Kenyon request 


disp"For BDCM the routes of exposure implemented are the following:"
disp"Inhalation, Oral, IV, Dermal, and the combination of Dermal with Inhalation"
disp"Set the route(s) of exposure selected to 1"

inhalation = 1;     % 1 for inhalation exposure, 0 if not
oral = 0;           % 1 oral exposure, 0 if not
iv = 0;             % 1 for iv exposure, 0 if not
dermal = 1;         % 1 for dermal exposure, 0 if not
if (inhalation) && (oral) && (iv) || (inhalation) && (oral) && (dermal) || (inhalation) && (oral) && (iv) && (dermal)
  error ("Exposure routes combination selected of more than 2 is not implemented");
elseif (inhalation) && (oral) || (inhalation) && (iv) 
  error ("Exposure routes combination selected of inhalation with oral or iv is not implemented");
elseif (oral) && (iv) || (oral) && (dermal)
  error ("Exposure routes combination selected of oral with iv or dermal is not implemented");
elseif (iv) && (dermal) 
  error ("Exposure routes combination selected of iv with dermal is not implemented");
elseif (inhalation) && (dermal)
  disp"Exposure routes selected are both inhalation and dermal. "  
elseif (inhalation) 
  disp"Exposure route selected is inhalation"
elseif (oral) 
  disp"Exposure route selected is oral"
elseif (iv)
  disp"Exposure route selected is iv"
elseif (dermal)
  disp"Exposure route selected is dermal"
endif  

%Set dose and duration of exposure
%Inhalation
inhaled_conc = 10;  % ppm
derm_or_inh_duration = 4;   %Duration of exposure (hr). Use for both inhaltion 
%and dermal exposures

%Oral
%Oral dosing is coded as a brief (10 sec) infusions into the lumen of the GI
%tract. 
oral_dose = 1; % (mg/kg)
tinf = 2.7778e-3;    % Duration of infusion in hr (10 s) 
c.k_oral_dose = 0.1;  % first-order absorption (1/hr)

%iv dosing is coded as a brief (10 sec) infusions into venous blood
iv_dose = 1;        % (mg/kg) 

%Dermal
%Dermal dosing involves contact of the skin with chemical of interest
%Typically, the chemical is dissolved in a carrier such as water or some
%appropriate solvent.
%Need to specify the volume of the dosing solution, the concentration of 
%chemical in the dosing solution, the contact area of the dosing solution
%with the skin, and the duration of the dermal exposure. 
%A large contact area (e.g., entire body surface area) is used to simulate
%swimming or showering. For swimming the volume of dosing solution is also
%large. Since chemical moves from the dosing solution into the skin, using a
%large volume of dosing solution ensures that the concentration in the dosing 
%solution does not decrease significantly during the exposure.
%Specification of a small contact area (a few cm^2) and a small volume of 
%dosing solution (a few ml) is used for dermal penetration experiments.
%In this code, dermal dosing is turned on by setting the amount of chemical in 
%the dosing solution to a nonzero value and turned off by setting the amount
%to zero.
dermal_dose_conc = 1; % (mg/L)
c.dermal_dose_volume = 1.e6; %Large for swimming (L)
c.SA_exposed = SA*10^4; % (cm^2) whole body is exposed

%If simulation starts on day of birth, specify age for exposures to start (hr)
%For example, might start at age 3 months for a rat (730 hr)
start_exposure_age = 1; %(hr) {note that 0 causes a crash} 
dose_start = 9; %Time of day to start exposure in 24-hr day (9 AM)

if inhalation || dermal
    dose_length = derm_or_inh_duration; % usually a few hours
elseif oral || iv
    dose_length = tinf; % 10s infusion
endif

%Specify times of day to stop dosing
dose_stop = dose_start + dose_length;
    
%Setting weekend to 6 means that days 6 and 7 of 7-day week are the weekend and
%there is no exposure. Can change to any value > 1
weekend = 6; %day of week for start of weekend.

%Initial conditions for ODEs
A_dosed_init = 0;           % #1 Amount dosed (inhalation, oral, iv, dermal) (mg)
A_lumen_init = 0;           % #2 Lumen of GI tract (mg)
A_derm_dose_init = 0;       % #3 Dermal dose (mg)
A_exh_init= 0;              % #4 Exhaled (mg)
A_RP_init = 0;              % #5 Richly perfused(mg)
A_PP_init = 0;              % #6 Poorly perfused(mg)
A_met_init = 0;             % #7 Hepatic metabolism(mg)
A_liver_init = 0;           % #8 Liver(mg)
A_fat_init = 0;             % #9 Fat(mg)
A_bladder_init = 0;         % #10 Bladder tissue(mg) 
A_skin_init = 0;            % #11 Skin(mg) 
A_GI_init = 0;              % #12 Tissue of GI tract(mg)
A_venous_blood_init = 0;    % #13 Venous Blood (mg)

%Discrete events
scheduler_bdcm; %Schedules discrete events - turning dosing on and off. Also calls
% ode file to solve ODEs from t = 0 to t = tstop

%END of Dynamic
%===============================================================================

%Postprocessing

%{
ODEs
#1 Amount dosed
#2 GI lumen
#3 Conc in dermal dose
#4 Exhaled
#5 Richly perfused
#6 Poorly perfused
#7 Amount metabolized
#8 Liver
#9 Fat
#10 Bladder tissue
#11 Skin
#12 GI tissue
#13 Venous_blood
%}

%Extract data from simdata and postprocess as needed for plotting
% #1 Amount dosed
dose = simdata(:,1); % (mg)
% #2 Lumen of GI tract
Amount_lumen = simdata(:,2); % (mg)
% #3 Dermal dose volume
A_dermal_dose_vol = simdata(:,3); % (mg)
% #4 Amount exhaled
Amount_exh = simdata(:,4); % (mg)
% #5 Rapdily perfused
ARP = [simdata(:,5)];%(mg)
CRP = ARP/c.VRP;% mg/L
% #6 Poorly (slowly) perfused
APP = [simdata(:,6)];%(mg)
CPP = APP/c.VPP;% mg/L
% #7 Hepatic metabolism
A_met = simdata(:,7);%(mg)
% #8 Liver
Amount_liver = simdata(:,8);%(mg)
CL = Amount_liver/c.VL;%(mg/L)
% #9 Fat
Amount_fat = simdata(:,9);%(mg)
CF = Amount_fat/c.VF;%(mg/L)
% #10 Bladder tissue
Amount_bladder = simdata(:,10);%(mg)
CY = Amount_bladder/c.VY;%(mg/L)
% #11 Skin 
Amount_skin = simdata(:,11); % (mg)
CSK = Amount_skin/c.VSK;%(mg/L)
% #12 GI tract tissue
Amount_gi = simdata(:,12); %(mg)
CGI = Amount_gi/c.VGI ;%(mg/L)
% #13 Venous Blood
Amount_venous_blood = simdata(:,13);% (mg) 
CV = Amount_venous_blood/c.VB;% (mg/L)

% Arterial blood (mg/L
CA = ((c.QC * CV) + (c.QP * c.CI)) / (c.QC + (c.QP / c.Pbl_a));

%MASS BALANCE
%Amount dosed  = amounts in tissues + metabolized + exhaled 
xx = simdata(:,2:end);
MB = simdata(:,1) - sum(xx,2) + simdata(:,3);

%Time used for plotting
time = all_time;
if tstop >= 40
    time = time/24;
endif

%Plots
subplot(3,3,1), plot(time, MB)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Mass balance')
title('Mass Balance')

subplot(3,3,2), plot(time, dose)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
if inhalation
    ylabel('Amount inhaled (mg)')
    title('Amount Inhaled')  
elseif oral
    ylabel('Oral dose (mg)')
    title('Oral dose')
elseif iv
    ylabel('IV dose (mg)')
    title('IV dose')
elseif dermal
    ylabel('Dermal dose (mg)')
    title('Dermal dose')
endif
if inhalation && dermal
    ylabel('Dose Inh + Dermal (mg)')
    title('Dose Inhalation + Dermal') 
endif

subplot (3,3,3),plot(time, CV)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Venous blood (mg/L)')
title('Conc. Venous Blood')

subplot(3,3,4), plot(time, CPP )
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Poorly  perfused (mg/L)')
title('Conc. Poorly Perfused')

if oral
    subplot(3,3,5), plot(time, Amount_lumen)
    if tstop < 48
        xlabel('Hours')
    else
        xlabel('Days')
    endif
    ylabel('Amount GI lumen (mg)')
    title('Amount in GI lumen')
else
    subplot(3,3,5),plot(time, CGI)
    if tstop < 48
        xlabel('Hours')
    else
        xlabel('Days')
    endif
    ylabel('Conc. GI tissue (mg/L)')
    title('Conc. GI Tissue')
endif

subplot(3,3,6), plot(time, A_met)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Amount metabolized(mg)')
title('Amount metabolized')

subplot(3,3,7), plot(time, CL)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Conc. liver (mg/L)')
title('Conc. liver')

subplot(3,3,8), plot(time, CF)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Conc. fat (mg/L)')
title('Conc. Fat')

subplot(3,3,9), plot(time, CSK)
if tstop < 48
    xlabel('Hours')
else
    xlabel('Days')
endif
ylabel('Conc. skin (mg/L)')
title('Conc. Skin')

disp(['Mass balance = ' num2str(MB(end))])
disp(['Elapsed time in seconds = ' num2str(etime(clock,start_time))])
disp('Done')
beep

%END of program