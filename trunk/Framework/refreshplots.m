function refreshplots(handles,axes)

selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
%if isa(signaldata.audio,'memmapfile'), signaldata.audio = signaldata.audio.Data; end
if ~ismatrix(signaldata.audio)
    linea(:,:) = signaldata.audio(:,str2double(get(handles.IN_nchannel,'String')),:);
else
    linea = signaldata.audio;
end
if isfield(signaldata,'cal')
    if size(linea,2) == length(signaldata.cal)
        signaldata.cal(isnan(signaldata.cal)) = 0;
        linea = linea.*repmat(10.^(signaldata.cal./20),length(linea),1);
    end
end
plottype = get(handles.(genvarname([axes '_popup'])),'Value');
%if plottype == 4 || plottype == 5 || plottype > 7
    set(handles.(genvarname(['To_' axes])),'Visible','on')
    To_s = str2double(get(handles.(genvarname(['To_' axes])),'String'));
    To = floor(To_s*signaldata.fs)+1;
    if length(signaldata.audio) <= 60*signaldata.fs
        set(handles.(genvarname(['Tf_' axes])),'Visible','on')
    else
        set(handles.(genvarname(['Tf_' axes])),'Visible','on')
    end
    Tf_s = str2double(get(handles.(genvarname(['Tf_' axes])),'String'));
    Tf = floor(Tf_s*signaldata.fs);
    if Tf > length(linea), Tf = length(linea); end
    linea = linea(To:Tf,:);
%else
%    set([handles.(genvarname(['To_' axes])),handles.(genvarname(['Tf_' axes]))],'Visible','off')
%end
fftlength = length(linea);
set(handles.(genvarname(['smooth' axes '_popup'])),'Visible','off');
if plottype == 1, linea = real(linea); end
if plottype == 2, linea = linea.^2; end
if plottype == 3, linea = 10.*log10(linea.^2); end
if plottype == 4, linea = abs(hilbert(real(linea))); end
if plottype == 5, linea = medfilt1(diff([angle(hilbert(real(linea))); zeros(1,size(linea,2))])*signaldata.fs/2/pi, 5); end
if plottype == 6, linea = abs(linea); end
if plottype == 7, linea = imag(linea); end
if plottype == 8, linea = 10*log10(abs(fft(linea,fftlength).*2.^0.5/fftlength).^2);  set(handles.(genvarname(['smooth' axes '_popup'])),'Visible','on'); end %freq
if plottype == 9, linea = (abs(fft(linea,fftlength)).*2.^0.5/fftlength).^2; end
if plottype == 10, linea = abs(fft(linea,fftlength)).*2.^0.5/fftlength; end
if plottype == 11, linea = real(fft(linea,fftlength)).*2.^0.5/fftlength; end
if plottype == 12, linea = imag(fft(linea,fftlength)).*2.^0.5/fftlength; end
if plottype == 13, linea = angle(fft(linea,fftlength)); end
if plottype == 14, linea = unwrap(angle(fft(linea,fftlength))); end
if plottype == 15, linea = angle(fft(linea,fftlength)) .* 180/pi; end
if plottype == 16, linea = unwrap(angle(fft(linea,fftlength))) ./(2*pi); end
if plottype == 17, spec = fft(linea,fftlength); linea = -diff(unwrap(angle(spec))).*length(spec)/(signaldata.fs*2*pi).*1000; end
if strcmp(get(handles.(genvarname(['smooth' axes '_popup'])),'Visible'),'on')
    smoothfactor = get(handles.(genvarname(['smooth' axes '_popup'])),'Value');
    if smoothfactor == 2, octsmooth = 1; end
    if smoothfactor == 3, octsmooth = 3; end
    if smoothfactor == 4, octsmooth = 6; end
    if smoothfactor == 5, octsmooth = 12; end
    if smoothfactor == 6, octsmooth = 24; end
    if smoothfactor ~= 1, linea = octavesmoothing(linea, octsmooth, signaldata.fs); end
end
t = (linspace(To_s,Tf_s,length(linea))).';
f = (signaldata.fs .* ((1:fftlength)-1) ./ fftlength).';
if plottype <= 7
    if ~isreal(signaldata.audio)
        set(handles.(genvarname(['complex' axes])),'Visible','on');
    else
        set(handles.(genvarname(['complex' axes])),'Visible','off');
    end
    set(handles.(genvarname(['log' axes '_chk'])),'Visible','off');
    pixels = get_axes_width(handles.(genvarname(['axes' axes])));
    [t, linea] = reduce_to_width(t, real(linea), pixels, [-inf inf]);
    t = t(:,1);
    plot(handles.(genvarname(['axes' axes])),t,real(linea)); % Plot signal in time domain
    xlabel(handles.(genvarname(['axes' axes])),'Time [s]');
    %xlim(handles.(genvarname(['axes' axes])),[0 length(signaldata.audio)/signaldata.fs])
    xlim(handles.(genvarname(['axes' axes])),[To_s Tf_s])
    set(handles.(genvarname(['axes' axes])),'XScale','linear','XTickLabelMode','auto')
    set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
end
if plottype >= 8
    set(handles.(genvarname(['complex' axes])),'Visible','off')
    pixels = get_axes_width(handles.(genvarname(['axes' axes])));
    log_check = get(handles.(genvarname(['log' axes '_chk'])),'Value');
    if log_check == 0
        [f1, linea1] = reduce_to_width(f(1:length(linea)), linea, pixels, [-inf inf]);
        f1 = f1(:,1);
    else
        [f1, linea1] = reduce_to_width(log10(1:length(linea))', linea, pixels, [-inf inf]);
        f1 = f1(:,1);
        f1 = (10.^f1)./max(10.^f1).*signaldata.fs;
    end
    plot(handles.(genvarname(['axes' axes])),f1,linea1);% Plot signal in frequency domain
    xlabel(handles.(genvarname(['axes' axes])),'Frequency [Hz]');
    xlim(handles.(genvarname(['axes' axes])),[f1(2) signaldata.fs/2])
    set(handles.(genvarname(['log' axes '_chk'])),'Visible','on');
    if log_check == 1
        set(handles.(genvarname(['axes' axes])),'XScale','log')
        set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
    else
        set(handles.(genvarname(['axes' axes])),'XScale','linear','XTickLabelMode','auto')
        set(handles.(genvarname(['axes' axes])),'XTickLabel',num2str(get(handles.(genvarname(['axes' axes])),'XTick').'))
    end
end
