function [OUT, varargout] = Blind_RT_LoellmannJeub2012(IN, fs)
% This function calls Loellmann and Jeub's blind reverberation time
% estimation functions. Use this function to estimate reverberation time
% from reverberant speech (e.g. 60 seconds of speech recording).
%
% Please refer to the following directory for the license and for more
% information on the algorithm:
% Analysers\Reverberation\Release_RT_estimation_MatlabFileExchange
%
% Reference:
% Heinrich W. Löllmann, Emre Yilmaz, Marco Jeub and Peter Vary:
% "An Improved Algorithm for Blind Reverberation Time Estimation"
% International Workshop on Acoustic Echo and Noise Control (IWAENC),
% Tel Aviv, Israel, August 2010.
% (availabel at www.ind.rwth-aachen.de/~bib/loellmann10a)
%
% The algorithm allows to estimate the RT within a range of 0.2s to 1.2s
% and assumes that source and receiver are not within the critical
% distance. A denoising is not performed by this function and has to be
% done in advance.

% Calling function for integration into AARAE by Densil Cabrera
% Version 1.00 (December 2013)



if isstruct(IN) 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
elseif ~isempty(param) || nargin > 1
                       
    audio = IN;
    
end


if ~isempty(audio) && ~isempty(fs)
    dur = size(audio,1) /fs;
    if dur < 15
        disp('This analyser is designed for reverberant speech,')
        disp('for example, 60 duration.')
        disp('(It is not designed to analyse impulse responses.)')
        disp('The input audio must be at least 15 s long for the analyser to run.')
        OUT = [];
        return
    end
    
    
    simpar.fs = fs;
    simpar.block_size = round(20e-3 * simpar.fs);  % block length
    simpar.overlap = round(simpar.block_size/2);   % overlap
    
    [rt_est,rt_est_mean,rt_est_dbg] = ML_RT_estimation(audio(:,1,1)',simpar);
    
    rt_est_median = median(rt_est);
    
    
    
    
    % output table
    f = figure;
    t = uitable('Data',[rt_est_mean rt_est_median],...
                'ColumnName',{'Mean RT estimate (s)' 'Median RT estimate (s)'},...
                'RowName',{'Results'});
    disptables(f,t);
    
%--------------------------------------------------------------------------
% Plot estimated RT and 'true' RT obtained by Schroeder method
%--------------------------------------------------------------------------
fr2sec_idx = linspace(1,length(audio)/simpar.fs,length(rt_est));
figure('Name','Blind Reverberation Time Estimate')
clf
hold on
plot(fr2sec_idx,rt_est,'-r')
line([0 fr2sec_idx(end)],[rt_est_mean rt_est_mean])
line([0 fr2sec_idx(end)],[rt_est_median rt_est_median],'Color', [0,0.5,0])
grid on,box on
xlabel('Time [s]'),ylabel('RT [s]');
legend('Estimated T60',['Mean Estimate ',num2str(rt_est_mean), ' s'], ...
    ['Median Estimate ',num2str(rt_est_median), ' s'],'location','southeast');

%--------------------------------------------------------------------------

    

    if isstruct(IN)
        OUT.rt_est = rt_est; 
        OUT.rt_est_mean = rt_est_mean; 
        OUT.rt_est_dbg = rt_est_dbg;
        OUT.funcallback.name = 'Blind_RT_LoellmannJeub2012.m';
        OUT.funcallback.inarg = {fs}; % not actually needed for callback
    else
        
        OUT = rt_est;
    end
    varargout{1} = rt_est_mean;
    varargout{2} = rt_est_dbg;


else
    
    OUT = [];
end