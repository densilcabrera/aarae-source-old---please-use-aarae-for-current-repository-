function refreshplots(handles,axes)

selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
plottype = get(handles.(genvarname([axes '_popup'])),'Value');
t = linspace(0,length(signaldata.audio),length(signaldata.audio))./signaldata.fs;
f = signaldata.fs .* ((1:length(signaldata.audio))-1) ./ length(signaldata.audio);
if ndims(signaldata.audio) > 2
    line(:,:) = signaldata.audio(:,str2double(get(handles.IN_nchannel,'String')),:);
else
    line = signaldata.audio;
end
set(handles.(genvarname(['smooth' axes '_popup'])),'Visible','off');
if plottype == 1, line = real(line); end
if plottype == 2, line = line.^2; end
if plottype == 3, line = 10.*log10(line.^2); end
if plottype == 4, line = abs(hilbert(real(line))); end
if plottype == 5, line = medfilt1(diff([angle(hilbert(real(line))); zeros(1,size(line,2))])*signaldata.fs/2/pi, 5); end
if plottype == 6, line = abs(line); end
if plottype == 7, line = imag(line); end
if plottype == 8, line = 10*log10(abs(fft(line)).^2);  set(handles.(genvarname(['smooth' axes '_popup'])),'Visible','on'); end %freq
if plottype == 9, line = abs(fft(line)).^2; end
if plottype == 10, line = abs(fft(line)); end
if plottype == 11, line = real(fft(line)); end
if plottype == 12, line = imag(fft(line)); end
if plottype == 13, line = angle(fft(line)); end
if plottype == 14, line = unwrap(angle(fft(line))); end
if plottype == 15, line = angle(fft(line)) .* 180/pi; end
if plottype == 16, line = unwrap(angle(fft(line))) ./(2*pi); end
if plottype == 17, line = -diff(unwrap(angle(fft(line)))).*length(fft(line))/(signaldata.fs*2*pi).*1000; end
if strcmp(get(handles.(genvarname(['smooth' axes '_popup'])),'Visible'),'on')
    smoothfactor = get(handles.(genvarname(['smooth' axes '_popup'])),'Value');
    if smoothfactor == 2, octsmooth = 1; end
    if smoothfactor == 3, octsmooth = 3; end
    if smoothfactor == 4, octsmooth = 6; end
    if smoothfactor == 5, octsmooth = 12; end
    if smoothfactor == 6, octsmooth = 24; end
    if smoothfactor ~= 1, line = octavesmoothing(line, octsmooth, signaldata.fs); end
end
if plottype <= 7
    if ~isreal(line)
        set(handles.(genvarname(['complex' axes])),'Visible','on');
    else
        set(handles.(genvarname(['complex' axes])),'Visible','off');
    end
    set(handles.(genvarname(['log' axes '_chk'])),'Visible','off');
    plot(handles.(genvarname(['axes' axes])),t,real(line)) % Plot signal in time domain
    xlabel(handles.(genvarname(['axes' axes])),'Time [s]');
    set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
end
if plottype >= 8
    set(handles.(genvarname(['complex' axes])),'Visible','off')
    if plottype == 17, semilogx(handles.(genvarname(['axes' axes])),f(1:end-1),line,'Marker','None'); end
    if plottype ~= 17, semilogx(handles.(genvarname(['axes' axes])),f,line); end % Plot signal in frequency domain
    xlabel(handles.(genvarname(['axes' axes])),'Frequency [Hz]');
    xlim(handles.(genvarname(['axes' axes])),[f(2) signaldata.fs/2])
    set(handles.(genvarname(['log' axes '_chk'])),'Visible','on');
    log_check = get(handles.(genvarname(['log' axes '_chk'])),'Value');
    if log_check == 1
        set(handles.(genvarname(['axes' axes])),'XScale','log')
        set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
    else
        set(handles.(genvarname(['axes' axes])),'XScale','linear','XTickLabelMode','auto')
        set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
    end
end