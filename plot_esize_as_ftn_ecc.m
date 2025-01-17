clear all; close all

eLoc = exp(linspace(log(1), log(25), 10)); % the eccentricitity of the electrode 
r = sqrt(100/pi)/1e+7;
eSize =  exp(linspace(log(.1), log(1), 6)); % esize from teeny tiny to huge
c.I_k = 1000; % high electric field fall off -  only stimulating directly under the electrode

%% generate each cortical surface
% define cortex & retina
c.cortexHeight = [-10,10]; % degrees top to bottom, degrees LR,
c.cortexLength = [-3, 80];
c.pixpermm = 8; % default 6, resolution of electric field sampling, for very small electrodes may need to be decreased
c = p2p_c.define_cortex(c); % define the properties of the cortical map

% transform to visual space
v.visfieldHeight = [-40,40];
v.visfieldWidth= [-40,40];
v.pixperdeg = 8;  %visual field map size and samping
v = p2p_c.define_visualmap(v); % defines the visual map

[c, v] = p2p_c.generate_corticalmap(c, v); % create ocular dominance/orientation/rf size maps on cortical surface
tp = p2p_c.define_temporalparameters(); % define the temporal model

PLOT = 0;
% define pulse train
trl.amp = 50; trl.freq = 50;
trl.pw = 2*10^(-4);   trl.dur= 1;
trl = p2p_c.define_trial(tp,trl);

ct = 1;
% move along the cortex, calulating the size of the percept and it's shift
% in location as one moves foveal to peripheral
 for sz = 1:length(eSize)
     for ecc = 1:length(eLoc)
% for ss = 3
%     for ecc = 5
        c.e.radius = eSize(sz);
        v.e.ecc = eLoc(ecc);
        v.e.ang = 0;
        c = p2p_c.define_electrodes(c, v); % complete properties for each electrode in cortical space
        c = p2p_c.generate_ef(c); % generate map of the electric field for each electrode on cortical surface

        v = p2p_c.generate_corticalelectricalresponse(c, v);  % create rf map for each electrode
        trl = p2p_c.generate_phosphene(v, tp, trl);
        sim_radius(sz, ecc) = mean([trl.ellipse(1).sigma_x trl.ellipse(1).sigma_y]);
%         GEOFF can you fix this? The phosphenes are roughly
%         gaussian so it seems good to find the standard deviation, but
%         it's not working for me.
%          p.mu = 180; 
%         p.sigma = 10;
%         [p, err] = fit('p2p_cfit_phosphene', p, {'mu','sigma'}, trl);
        if PLOT
            figure(1); %subplot(length(eSize), length(eLoc), ct);
            p2p_c.plotcortgrid(c.e.ef*2, c, gray(256), 1,['title(''electric field'')']); drawnow;
            figure(2); %subplot(length(eSize), length(eLoc), ct);
            p2p_c.plotretgrid(trl.maxphos(:, :, 1)*20, v, gray(256), 2,['';]);
            ct = ct + 1;
        end
    end
end

figure(1); clf
plot(sim_radius')
xlabel('Eccentricity');
ylabel('Phosphene size')
legend(num2str(eSize'));
title('Phosphene Size w. Eccentricity')
% this graph makes sense, near the fovea the limiting factor is the size of
% the phosphenes. Only when cortical magnification is small does the size
% of the electrode matter.

% now for each eccentricity, calculate the cortical distance that gives you
% half the phosphene size, basically gives you the minimum useful cortical
% spacing
for ecc = 1:length(eLoc)
    sd = min(sim_radius(:, ecc))/2;
    e1 = eLoc(ecc)-sd/2;
    e2 = eLoc(ecc)+sd/2;
    e3 = eLoc(ecc);
    z1 = e1.*exp(sqrt(-1)*(0)*pi/180);   z2 = e2.*exp(sqrt(-1)*(0)*pi/180);  z3 = e3.*exp(sqrt(-1)*(0)*pi/180);
    cz2 = p2p_c.c2v(c,z2);    cz1 = p2p_c.c2v(c,z1);   cz3 = p2p_c.c2v(c,z3);
    cx1 = real(cz1) ;  cx2 = real(cz2);  cx3 = real(cz3);
    spacing(ecc)= cx2-cx1;
    cortical_location(ecc) = cx3;
end

% GEOFF so this inuitively feels really weird to me. But I think it's right
% Basically in the fovea you need to separate the electrodes by enough
% corttical distance to represent 1.5 degrees - that's a lot of cortex
% In contrast, in the periphery, you need to separate the electrodes by
% enough cortical distance to represent about 4 degrees - but that's
% actually not very far in terms of cortical distance.
% so counterintuitively, electrodes should be spaced wider in the fovea
% then the periphery. 
figure(2)
subplot(1,2,1)
 plot(eLoc, spacing, 'k');
 xlabel('Eccenctricity (degrees');
 ylabel('Minimum Electrode Separation in mm')

 subplot(1,2,2)
 plot(cortical_location, spacing, 'k');
 xlabel('mm from the pole');
 ylabel('Minimum Electrode Separation in mm')





