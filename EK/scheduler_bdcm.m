%Rory Conolly
%July 8, 2018
%Octave code for discrete events
%============================
%Don't mess with this code!!!
%============================
%This code sets up the list of discrete events that specifies the dosing
%scenario. This scenario could be as simple as a single oral dose or
%inhalation exposure or as complicated as dosing repeated daily for weeks
%or months or years. 

%Vector of initial conditions used by LSODE
y0 = [
A_dosed_init                % 1
A_lumen_init                % 2
A_derm_dose_init            % 3
A_exh_init                  % 4
A_RP_init                   % 5
A_PP_init                   % 6
A_met_init                  % 7
A_liver_init                % 8
A_fat_init                  % 9
A_bladder_init              % 10
A_skin_init                 % 11
A_GI_init                   % 12
A_venous_blood_init ];      % 13

%===============================================================================           
%Construct and event list to handle daily exposure, arbitrary number of 
%days/week, for duration up to full lifespan.

%start_exposure_age = 0; %No exposure before this age in hours. This parameter
%enables delay in starting exposure to mimic, for example, growth to a desired
%age.
%exposure_start = 9; % Time of day to start exposure

%Assume first day is a Monday, with the run starting at midnight
%Day 1 = Monday, Day 2 = Tuesday, Day 3 = Wednesday, Day 4 = Thursday, 
%Day 5 = Friday, Day 6 = Saturday, Day 7 = Sunday

%===============================================================================
hours = 0:1:tstop; %vector of all the hours
hod = 0; %Initialize hour of day
hod_counter = 0; %Initialize
dow = 1; %Initialize day of week 
dow_counter = 1; %Initialize

for i = 1:tstop
    hod_counter = hod_counter + 1; %hour of day
    hod = [hod hod_counter];           
    dow = [dow dow_counter];       %day of week
    if hod_counter == 24           %reset
        hod_counter = 0;           
        dow_counter = dow_counter + 1;%increment
        if dow_counter == 8;        %reset
            dow_counter = 1;
        end
    end
end
timekeeper = [hours' hod' dow'];

%Now identify times at which events occur. An event is a time at which dosing 
%is either turned on or off. 
event_timer = [];
for i = start_exposure_age:tstop - 1
    if timekeeper(i,3) < weekend ;%OK to dose if not weekend
        if timekeeper(i,2) == dose_start; %time of day to start dosing
            %time to start dosing
            event_timer = [event_timer; timekeeper(i,1) timekeeper(i,2)];
            %time to stop dosing
            event_timer = [event_timer; timekeeper(i,1)+dose_length ...
                     timekeeper(i,2)+dose_length];
        end
    end
end

%Force the start of event_timer to be (1,1). This is needed so that tspan sets
% up correctly
if event_timer(1,1) > 1
    event_timer = [0 0; event_timer];
endif

%Force the end of event_timer to be (tstop, 0). This is needed so that tspan 
%sets up correctly
if event_timer(end) < tstop
    event_timer = [event_timer; tstop 0];
endif 

%Set the doses
%Inhalation: Dose measure as inhaled concentration (mg/L)
inhdose = inhaled_conc*mw/24450.;  %Convert ppm to mg/l
%Oral: Dose measured as rate of infusion into gut lumen (mg/hr)
odose = oral_dose * BW; % (mg)
oraldose = (oral_dose*BW)/dose_length; % rate of oral infusion (mg/hr)
%iv: Dose measured as rate of infusion into venous blood (mg/hr)
ivdose = (iv_dose*BW)/dose_length; % (mg/hr)
%dermal: Dose measure as initial condition for amount of chemical in dosing 
%solution (mg)
dermdose = dermal_dose_conc * c.dermal_dose_volume; % (mg)

%Now we walk along the event timer turning exposure on and off. tspan is used to 
%define the interval between the discrete events. 
%First, some initializations
%initially, set doses for all routes to zero
c.CI = 0;           %initialize
c.rate_oral = 0;    %initialize
c.rate_IV = 0;      %initialize
simdata= [];        %initialize
all_time = [];      %initialize

for i = 1:length(event_timer) - 1
    if event_timer(i+1, 1) - event_timer(i,1) < cint
        tspan = [event_timer(i,1) event_timer(i+1,1)];
    else
        tspan = [event_timer(i,1):cint:event_timer(i+1,1)];
    endif
    %Collect time vector for plotting
    all_time = [all_time; tspan(2:end)'];
    if event_timer(i,1) >= start_exposure_age
        if event_timer(i,2) == dose_start
            if inhalation
                c.CI = inhdose;         %(mg/L)
            elseif oral
                c.rate_oral = oraldose; % (mg/hr)
            elseif iv
                c.rate_IV = ivdose;     % (mg/hr)
            elseif dermal
                y0(3) = dermdose;       % (mg)
            endif
        endif
    endif
    if event_timer(i,2) == dose_stop
        if inhalation
            c.CI = 0;                   % (mg/L)
        elseif oral
            c.rate_oral = 0;            % (mg/hr)
        elseif iv
            c.rate_IV = 0;              % (mg/hr)
        elseif dermal
            y0(3) = 0;                  % (mg)
        endif
    endif  
    %Run the odes. Simdata holds the results
    simdatax = lsode(odefilename,y0,tspan);
    simdata = [simdata; simdatax(1:end-1,:)];
    y0 = simdatax(end,:); %reset the initial condition vector
 endfor
%End of Discrete_V3