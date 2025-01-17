%temporal_fit_Winawer_data.m
%
% fits Winawer bightness data, corresponds to figure 2c

clear all; close all

T = readtable('datasets/Winawer2016_data.xlsx');
T.brightness( T.brightness==-1000) = NaN; % weird hack because otherwise brightness stuck as a cell array
eid = find(T.amp~=0 & ~isnan(T.brightness));
T = T(eid, :);
tp = p2p_c.define_temporalparameters();

rng(11171964) % fix the random number generator, used Geoff's birthday in paper

rval = randperm(size(T,1));
rsamp(1).val = rval(1:ceil(length(rval)/2));
rsamp(2).val  = rval(ceil(length(rval)/2)+1:end);

titleStr = {'Training Data', 'Test Data'};
FITFLAG = 0;
if FITFLAG
    Texp = T(rsamp(1).val,:);
    freeParams = {'power', 'tau2'};
    tp = fit('p2p_c.fit_brightness',tp,freeParams,Texp);
end
colorList  = [1 0 0; 0 1 0; 1 .7 0; .3 .3  1; 0 0 1 ]; % roughly match colors to Winawer paper
for r = 1:2 % test and train data
    for site =1:5
        eid = intersect(rsamp(r).val, find(T.electrode==site));
        if ~isempty(eid)
            Texp = T(eid, :);
            trl= p2p_c.loop_convolve_model(tp, Texp);
            subplot(1, 2, r)
            x = [trl.maxresp]; y = [Texp.brightness] ;
            x= reshape(x, length(x), 1);  y = reshape(y, length(x), 1);
            ind = ~isnan(x) & ~isnan(y);
            if sum(ind)>0
                plot(x, y, 'o', 'MarkerFaceColor', colorList(site, :), 'MarkerEdgeColor', 'none'); hold on
                corrval = corr(x(ind), y(ind));
                xlabel('Model Estimate');
                ylabel('Reported Brightness');
                set(gca, 'XLim', [0 25]);
                set(gca, 'YLim', [0 11]);
                t = text(15, site/2, ['corr = ', num2str(round(corrval, 3))]);
                set(t, 'Color',colorList(site, :) )
                title(titleStr{r});
            end
        end
    end

end

