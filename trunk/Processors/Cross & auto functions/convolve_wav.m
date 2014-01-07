function y = convolve_wav(in)
% This function convolves the selected audio data with a user-selected 
% wav file, using the frequency domain multiplication method.
%
% Code by Densil Cabrera
% version 1.01 (15 December 2013)

wave1 = squeeze(sum(in.audio(:,:,:),3)); % sum the 3rd dimension if it exists
fs = in.fs;
[len1, chans1] = size(wave1);

% Use a dialog box to select a wav file.
% The variable speechrec is used to store the file name.
selection = choose_audio;

if ~isempty(selection)
    wave2 = selection.audio;
    fs2 = selection.fs;
    
    if ~(fs2 == fs)
        wave2 = resample(wave2,fs,fs2);
    end

    [len2, chans2] = size(wave2);

    outputlength = len1 + len2 - 1;
    %times = ((1:outputlength)-1) ./ fs;

    if chans1 == chans2
        y = ifft(fft(wave1, outputlength) .* fft(wave2, outputlength));
    elseif chans1 ==1
        y = ifft(fft(repmat(wave1,[1, chans2]), outputlength) ...
            .* fft(wave2, outputlength));
    elseif chans2 ==1
        y = ifft(fft(wave1, outputlength) ...
            .* fft(repmat(wave2,[1,chans1]), outputlength));
    else
        % in this case only the first channel of the wav file's audio is used
        y = ifft(fft(wave1, outputlength) ...
            .* fft(repmat(wave2(:,1),[1,chans1]), outputlength));
    end

    % Loop for replaying, saving and finishing
    choice = 0;

    % loop until the user presses the 'Done' button
    while choice < 4
        choice = menu('What next?', ...
            'Play', ...
            'Save wav file', 'Adjust gain', 'Discard', 'Done');
        switch choice

            case 1
                sound(y ./ max(max(abs(y))),fs)

            case 2
                [filename, pathname] = uiputfile({'*.wav'},'Save as');
                if ischar(filename)
                    if max(max(abs(y))) <= 1
                        audiowrite([pathname,filename], y, fs);
                    else
                        audiowrite([pathname,filename], y./ max(max(abs(y))), fs);
                        disp('The saved audio has been normalized to prevent clipping.')
                    end
                end
            case 3
                Lmax = 20*log10(max(max(abs(y))));
                prompt = {['Gain (dB) or ''n'' (max is ',num2str(Lmax), ' dBFS)']};
                dlg_title = 'Gain';
                num_lines = 1;
                def = {num2str(-Lmax)};
                answer = inputdlg(prompt,dlg_title,num_lines,def);
                gain = answer{1,1};
                if ischar(gain)
                    % normalize each channel individually
                    maxval = max(abs(y));
                    y = y ./ repmat(maxval,[outputlength,1]);
                else
                    gain = str2num(gain);
                    y = y * 10.^(gain/20);
                end

            case 4
                y = [];
        end
    end
    OUT = in; % replicate input structure, to preserve fields
    OUT.audio = y;
else
    OUT = [];
end