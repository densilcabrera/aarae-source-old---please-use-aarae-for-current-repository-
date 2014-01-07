function y = lifter_audio(in, fs, t1, t2, wl)
% lifters the cepstrum of a wave between t1 and t2 (in milliseconds, in
% the quefrency domain)
% for a wave with sampling frequency fs (in Hz)
% wl is the window length (in millisecods)
%
%
% Code by Densil Cabrera
% version 1.0 (16 October 2013)

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
    prompt = {'Lifter start time (ms)', ...
        'Lifter end time (ms)', ...
        'Cepstrum window length (ms)', ...
        'Play and/or display (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'0','200',num2str(floor(1000*len/fs)),'1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        t1 = str2num(answer{1,1});
        t2 = str2num(answer{2,1});
        wl = str2num(answer{3,1});
        doplay = str2num(answer{4,1});
    end
    
end


nsamples = ceil(wl * 0.001 * fs);

% cepstral window in samples
s1 = round(0.001 * t1 * fs) + 1;
s2 = round(0.001 * t2 * fs) + 1;

% avoid errors
if s1 < 1 || s1 > nsamples-1
    s1 = 1;
end
if s2 < 2 || s2 > nsamples
    s2 = nsamples;
end
if s1 >= s2
    s1 = 1;
    s2 = nsamples;
end

if nsamples < length(data)
    x= data(1:nsamples,:,:);
else
    x = zeros(nsamples,chans,bands);
    x(1:length(data),:,:)=data;
end

% cceps only operates on vectors (not matrices) - hence the following loop
cepstrum = zeros(len,chans,bands);
for ch = 1:chans
    for b = 1:bands
        cepstrum(:,ch,b) = cceps(x(:,ch,b));
    end
end

lifteredcepstrum = zeros(nsamples,chans,bands);
lifteredcepstrum(s1:s2,:,:) = cepstrum(s1:s2,:,:);
lifteredcepstrum(nsamples-s2+1:nsamples-s1+1,:,:) = cepstrum(nsamples-s2+1:nsamples-s1+1,:,:);

y = zeros(size(cepstrum));
for ch = 1:chans
    for b = 1:bands
        y(:,ch,b)=icceps(lifteredcepstrum(:,ch,b));
    end
end

if doplay
    % Loop for replaying, saving and finishing
    choice = 0;
    
    % loop until the user presses the 'Done' button
    while choice < 4
        choice = menu('What next?', ...
            'Play audio', ...
            'Plot spectrogram', 'Save wav file', 'Discard', 'Done');
        switch choice
            case 1
                ysumbands = sum(y,3);
                sound(ysumbands./max(max(abs(ysumbands))),fs)
            case 2
                spectrogram_simple(y,fs);
            case 3
                [filename, pathname] = uiputfile({'*.wav'},'Save as');
                ysumbands = sum(y,3);
                if max(max(abs(ysumbands)))>1
                    ysumbands = ysumbands./max(max(abs(ysumbands)));
                    disp('Wav data has been normalized to avoid clipping')
                end
                if ischar(filename)
                    audiowrite([pathname,filename], ysumbands, fs);
                end
            case 4
                y = [];
        end
    end
end