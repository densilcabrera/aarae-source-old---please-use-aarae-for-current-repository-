function [fitresult, gof] = createFit(analysistimesforfit, diffforfit)
%CREATEFIT(ANALYSISTIMESFORFIT,DIFFFORFIT)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : analysistimesforfit
%      Y Output: diffforfit
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 08-Jul-2013 09:25:33


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( analysistimesforfit, diffforfit );

% Set up fittype and options.
ft = fittype( 'exp2' );
opts = fitoptions( ft );
opts.Display = 'Off';
opts.Lower = [-Inf -Inf -Inf -Inf];
opts.StartPoint = [0.890578807488228 -0.0320196209673671 -0.361263403989793 -6.76286489386832];
opts.Upper = [Inf Inf Inf Inf];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
legend( h, 'diffforfit vs. analysistimesforfit', 'untitled fit 1', 'Location', 'NorthEast' );
% Label axes
xlabel( 'analysistimesforfit' );
ylabel( 'diffforfit' );
grid on

