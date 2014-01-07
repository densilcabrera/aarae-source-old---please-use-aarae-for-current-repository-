function y = window_audio(in, winchoice, fs)

if isstruct(in)
    data = in.audio;
    fs = in.fs;
else
    data = in;
    doplay = 0;
end

S = size(data); % size of the audio
ndim = length(S); % number of dimensions
switch ndim
    case 1
        len = S(1); % number of samples in audio
        chans = 1; % number of channels
        bands = 1; % number of bands
    case 2
        len = S(1); % number of samples in audio
        chans = S(2); % number of channels
        bands = 1; % number of bands
    case 3
        len = S(1); % number of samples in audio
        chans = S(2); % number of channels
        bands = S(3); % number of bands
end


if isstruct(in)
    %dialog box for settings
    prompt = {'Window function name (text)', ...
        'Half window (-1 | 0 | 1)', ...
        'Play and/or display (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'hann', '0', '1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        winchoice = answer{1,1};
        halfwin = str2num(answer{2,1});
        doplay = str2num(answer{3,1});
    end
    
end

if abs(halfwin) == 1
    wlen = 2*len;
else
    wlen = len;
end

[wf, wtag] = winfun(winchoice, wlen);

switch halfwin
    case -1
        wf = wf(1:len);
    case 1
        wf = flipud(wf(1:len));
end

y = data .* repmat(wf,[1,chans,bands]);

if doplay
    figure('Name', 'Window function applied to wave')
    plot(((1:len)'-1)./fs,mean(mean(data,3),2), 'Color', [0.7 0.7 0.7])
    hold on
    plot(((1:len)'-1)./fs,mean(mean(y,3),2), 'Color', [0.5 0.5 0.5])
    
    plot(((1:len)'-1)./fs,wf, 'r')
    title([wtag 'window function'])
    xlabel('Time (s)')
    ylabel('Value')
    hold off
    
    
    
    % Loop for replaying, saving and finishing
    choice = 0;
    
    % loop until the user presses the 'Done' button
    while choice < 5
        choice = menu('What next?', ...
            'Play audio', 'Plot all channels and bands', ...
            'Plot spectrogram', 'Save wav file', 'Discard', 'Done');
        switch choice
            case 1
                ysumbands = sum(y,3);
                sound(ysumbands./max(max(abs(ysumbands))),fs)
            case 2
                plot_wave_simple(y, fs)
                
            case 3
                spectrogram_simple(y,fs);
            case 4
                [filename, pathname] = uiputfile({'*.wav'},'Save as');
                ysumbands = sum(y,3);
                if max(max(abs(ysumbands)))>1
                    ysumbands = ysumbands./max(max(abs(ysumbands)));
                    disp('Wav data has been normalized to avoid clipping')
                end
                if ischar(filename)
                    audiowrite([pathname,filename], ysumbands, fs);
                end
            case 5
                y = [];
        end
    end
end


function [y, w] = winfun(choice, wlen)
% generate window functions
% check Matlab's help on "window" to understand this function
switch choice
    case {'r', 'R', 'rectangular', 'Rectangular', 'rect','Rect'}
        wFuncChoice = @rectwin;
        w = 'Rectangular ';
    case {'ham', 'Ham', 'hamming', 'Hamming'}
        wFuncChoice = @hamming;
        w = 'Hamming ';
    case {'Barthann', 'barthann', 'Barth', 'barth'}
        wFuncChoice =@barthannwin;
        w = 'Barthann ';
    case {'Bartlett', 'bartlett','Bart', 'bart'}
        wFuncChoice =@bartlett;
        w = 'Bartlett ';
    case {'Blackman', 'blackman','Black', 'black', 'b', 'B'}
        wFuncChoice =@blackman;
        w = 'Blackmnan ';
    case {'Blackman-Harris', 'blackman-harris', 'bh', 'BH'}
        wFuncChoice =@blackmanharris;
        w = 'Blackman-Harris ';
    case {'Bohmanwin', 'Bohman','bohmanwin','bohman'}
        wFuncChoice =@bohmanwin;
        w = 'Bohman ';
    case {'Flat-top', 'flat-top', 'Flattop', 'flattop','Flat', 'flat', 'F','f'}
        wFuncChoice =@flattopwin ;
        w = 'flat-top ';
    case {'Gaussian', 'gaussian', 'Gauss', 'gauss', 'G', 'g', 'Gaus', 'gaus'}
        wFuncChoice =@gausswin;
        w = 'Gaussian ';
    case {'Hann', 'hann', 'H', 'h', 'Hanning', 'hanning'}
        wFuncChoice =@hann;
        w = 'Hann ';
    case {'Triangular','triangular', 'Tri', 'tri', 'T', 't'}
        wFuncChoice = @triang;
        w = 'Triangular ';
    otherwise
        wFuncChoice = @hann;
        w = 'Hann ';
end
y =window(wFuncChoice, wlen);
%y = y ./ mean(y.^2)^0.5; % normalize to rms instead of to max