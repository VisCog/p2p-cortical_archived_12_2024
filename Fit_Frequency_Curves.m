%% fitFrequency.m
%
% Fits a variety of frequency data, examining how threshold varies with
% pulse width
%
% Written by GMB & IF 
% 25/02/2023 moved into clean folder (IF)

tp = p2p_c.define_temporalparameters();

% Calculate model response to a standard trial
clear standard_trl;
standard_trl.pw = 0.001; %0.00025;
standard_trl.amp = 3;
standard_trl.dur = 1; %.5 ;
standard_trl.freq = 50;
standard_trl.simdur = 3; %sec
standard_trl = p2p_c.define_trial(tp,standard_trl);
standard_trl= p2p_c.convolve_model(tp, standard_trl);
tp.thresh_resp = standard_trl.maxresp;% use that as the threshold response

% Dobelle 74 only had a limited number of freq/electrodes so including that data has a risk of overfitting
% paperList = {'Dobelle74'; 'Henderson79' ;'Girvin79'};  % Henderson varied both frequency and duration :(
% legStr = {'Dobelle 1974, 0.5 msec pulse width, 1 sec duration',...
%     'Henderson 1979, 0.5 msec pulse width, variable duration',...
%     'Girvin 1979, 0.25 msec pulse width, 0.5 sec duration'};
 
paperList = {'Dobelle74' ;'Girvin79'; 'Fernandez21'};

exList = {{'freq'},{'freq'},{'freq'}};
electrodeList = {{'A1','A2','A3','A4','B2','B3','B4','C1','C2','C3','C4'},{'A'}, {'A'}};
legStr = {'Dobelle 1974, 0.5 msec pulse width, 1 sec duration',...
    'Girvin 1979, 0.25 msec pulse width, 0.5 sec duration', ...
       'Fernandez 0.17 msec pulse width, 0.16 sec duration'};

clear x y1 y2
count = 0;
for i = 1:length(paperList)
    for j=1:length(exList{i})
        T = readtable(['datasets/', paperList{i}, '_data.xlsx']);
        count =count+1;
        x{count} = [];   y1{count} = [];   y2{count} = [];
        for k=1:length(electrodeList{i})
                    disp(sprintf('Paper: %s, experiment: %s, electrode: %s'...
                        ,paperList{i},exList{i}{j},electrodeList{i}{k}))

            eid =strcmp(T.experiment,exList{i}{j}) & strcmp(T.electrode,electrodeList{i}{k});
            if sum(eid)
                Texp = T(eid,:);
                disp(sprintf('%d data points',sum(eid)));
                [err, thresh] = p2p_c.loop_find_threshold(tp,Texp);
                
                Tsim = Texp;
                Tsim.pw = standard_trl.pw*ones(size(Tsim.freq));
                Tsim.dur = standard_trl.dur*ones(size(Tsim.dur));
                
                % get model response to standard stimulus at these pd's
                [err, standard_thresh] = p2p_c.loop_find_threshold(tp,Tsim);
                
                % regression to scale the actual data.
                scFac1 =  standard_thresh'/Texp.amp';
                
                % save results to plot later.
                x{count} = [x{count};log(Texp.freq)];
                y1{count} =[y1{count};Texp.amp*scFac1];
                
                scFac2 = standard_thresh'/thresh';
                y2{count} = [y2{count};thresh*scFac2];
            else
                disp('No data points found.');
            end
        end
    end
end

%% predict smooth freq curve using standard trial parameters.
%  Should go through our standard trial's point: amp = 3 at pw = 1msec and freq = 50Hz

% make fake data table
freqList = exp(linspace(log(8), log(2000), 40));
pw = standard_trl.pw*ones(size(freqList));
dur = standard_trl.dur*ones(size(freqList));

Tstandard = table(pw', freqList', dur');
Tstandard.Properties.VariableNames = {'pw','freq','dur'};
% get thresholds
[err, standard_thresh] = p2p_c.loop_find_threshold(tp,Tstandard);

%% plotting
% (fast after running previous chunks)

sz = 150; % symbol size
xtick = [8,16,32,64,128,256,512,1024];
colList = {'b', 'r', 'c', 'm', 'g'};
alpha = .5;  % transparency
sd = 0.15; % jitter
fontSize = 12;
clear h

figure(1); clf; hold on
plot(log(freqList),standard_thresh,'k-','LineWidth',2);
for i=1:length(x)ct = 1;
    h(i)= scatter(x{i} + 2*sd*(rand(size(x{i}))-0.5),y1{i} + sd*(rand(size(x{i}))-0.5) ,sz , 'MarkerFaceColor', colList{i},...
        'MarkerEdgeColor','none','MarkerFaceAlpha',alpha);
       for j = 1:length(x{i})
        data(ct) =y1{i}(j);
        pred(ct)= interp1(pdList*1000, standard_thresh, exp(x{i}(j)));
        ct = ct+1;
    end
    tmp = corrcoef(data, pred);
    disp([legStr{i}, ' ', num2str(round(tmp(2),3))])
end

set(gca,'XTick',log(xtick)); logx2raw(exp(1),0); ylabel('Threshold'); widen; grid;
xlabel('Frequency (Hz)'); ylabel('Amplitude @ Threshold');
legend(h,legStr,'Location','NorthEast');
set(gca,'YLim',[0,10]);
set(gca,'FontSize',fontSize);

% Figure 2 holds the predicted thresholds for each experiment scaled
% to match the standard stimulus curve.  The curves match perfectly  - the
% effect of frequency is independent of pulse width
sd = 0;
figure(2); clf; hold on
plot(log(freqList),standard_thresh,'k-','LineWidth',2);
for i=1:length(x)
    h(i)= scatter(x{i}+sd*(rand(size(x{i}))-0.5),y2{i}+ sd*(rand(size(x{i}))-0.5),sz , 'MarkerFaceColor', colList{i},...
        'MarkerEdgeColor','none','MarkerFaceAlpha',alpha);
end
set(gca,'XTick',log(xtick)); logx2raw(exp(1),0); ylabel('Threshold'); widen; grid;
xlabel('Frequency (Hz)'); ylabel('Amplitude @ Threshold');
legend(h,legStr,'Location','NorthEast');
set(gca,'YLim',[0,10]);
set(gca,'FontSize',fontSize);
title('Scaled model predictions');



