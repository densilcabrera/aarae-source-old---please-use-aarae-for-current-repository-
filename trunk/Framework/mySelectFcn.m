% The tree-node selection callback
% This function is almost the brains behind the tree's response to
% selection commands, it controls also visibility of some functions
% depending on what type of signal is selected and its contents.
function nodes = mySelectFcn(tree, value)
    selectedNodes = tree.getSelectedNodes; % Get selected leaf
    if ~isempty(selectedNodes)
        
        % Call the 'desktop'
        hMain = getappdata(0,'hMain');
        selectedNodes = selectedNodes(1);
        audiodata = selectedNodes.handle.UserData;
        % Get handles of main window
        mainHandles = guidata(findobj('Tag','aarae'));
        if ~isempty(audiodata) && isfield(audiodata,'audio')% If there's data saved in the leaf...
            audiodatatext = evalc('audiodata');
            set(mainHandles.audiodatatext,'String',['Selected: ' selectedNodes.getName.char audiodatatext]); % Output contents in textbox below the tree
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.IR_btn,'Visible','off'); 
            set(mainHandles.tools_panel,'Visible','on');
            set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','on');
            set(mainHandles.time_popup,'Visible','on','Value',1);
            set(mainHandles.freq_popup,'Visible','on','Value',8);
            set(mainHandles.smoothtime_popup,'Visible','off','Value',1);
            set(mainHandles.smoothfreq_popup,'Visible','on','Value',1);
            set(mainHandles.logtime_chk,'Visible','off','Value',0);
            set(mainHandles.logfreq_chk,'Visible','on','Value',1);
            set(mainHandles.process_panel,'Visible','on');
            set(mainHandles.playback_panel,'Visible','on');
            set(mainHandles.channel_panel,'Visible','off');
            set(mainHandles.procat_box,'Value',1);
            set(mainHandles.proc_box,'Visible','off');
            set(mainHandles.proc_btn,'Visible','off');
            set(mainHandles.analysis_panel,'Visible','on');
            set(mainHandles.funcat_box,'Value',1);
            set(mainHandles.fun_box,'Visible','off');
            set(mainHandles.analyze_btn,'Visible','off');
            setappdata(hMain,'testsignal', audiodata); % Set leaf contents in the 'desktop'
            t = linspace(0,length(audiodata.audio),length(audiodata.audio))./audiodata.fs;
            if ndims(audiodata.audio) > 2
                set(mainHandles.channel_panel,'Visible','on');
                set(mainHandles.IN_nchannel,'String','1');
                set(mainHandles.tchannels,'String',['/ ' num2str(size(audiodata.audio,2))]);
                line(:,:) = audiodata.audio(:,str2double(get(mainHandles.IN_nchannel,'String')),:);
                cmap = colormap(hsv(size(audiodata.audio,3)));
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            else
                line = audiodata.audio;
                cmap = colormap(lines(size(audiodata.audio,2)));
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            end
            plot(mainHandles.axes2,t,line) % Plot signal in time domain
            xlabel(mainHandles.axes2,'Time [s]');
            set(mainHandles.axes2,'XTickLabel',num2str(get(mainHandles.axes2,'XTick').'))
            f = audiodata.fs .* ((1:length(audiodata.audio))-1) ./ length(audiodata.audio);
            level = 10 * log10(abs(fft(line)).^2);
            semilogx(mainHandles.axes3,f,level) % Plot signal in frequency domain
            xlabel(mainHandles.axes3,'Frequency [Hz]');
            xlim(mainHandles.axes3,[20 20000])
            set(mainHandles.axes3,'XTickLabel',num2str(get(mainHandles.axes3,'XTick').'))
            if isfield(audiodata,'audio2') && (strcmp(audiodata.datatype,'measurements') || strcmp(audiodata.datatype,'testsignals') || strcmp(audiodata.datatype,'processed'))
                set(mainHandles.IR_btn,'Visible','on'); % Display process IR button if selection is a measurement based on a sine sweep
            end
        elseif ~isempty(audiodata) && ~isfield(audiodata,'audio')% If there's data saved in the leaf...
            plot(mainHandles.axes2,0,0)
            axis(mainHandles.axes2,[0 10 -1 1]);
            xlabel(mainHandles.axes2,'Time [s]');
            set(mainHandles.axes2,'XTickLabel',num2str(get(mainHandles.axes2,'XTick').'))
            semilogx(mainHandles.axes3,0,0)
            xlabel(mainHandles.axes3,'Frequency [Hz]');
            xlim(mainHandles.axes3,[20 20000])
            set(mainHandles.axes3,'XTickLabel',num2str(get(mainHandles.axes3,'XTick').'))
            set(mainHandles.audiodatatext,'String',[]);
            datatext = evalc('audiodata');
            set(mainHandles.datatext,'Visible','on');
            set(mainHandles.datatext,'String',['Selected: ' selectedNodes.getName.char datatext]); % Output contents in textbox below the tree
            set(mainHandles.IR_btn,'Visible','off');
            set(mainHandles.tools_panel,'Visible','on');
            set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','off')
            set([mainHandles.time_popup mainHandles.freq_popup mainHandles.smoothtime_popup mainHandles.smoothfreq_popup],'Visible','off');
            set(mainHandles.logtime_chk,'Visible','off');
            set(mainHandles.logfreq_chk,'Visible','off');
            set(mainHandles.process_panel,'Visible','off');
            set(mainHandles.analysis_panel,'Visible','off');
            set(mainHandles.playback_panel,'Visible','off');
            set(mainHandles.channel_panel,'Visible','off');
            setappdata(hMain,'testsignal', []);
        else
            % If selection has no data, hide everything and don't display
            % data
            plot(mainHandles.axes2,0,0)
            axis(mainHandles.axes2,[0 10 -1 1]);
            xlabel(mainHandles.axes2,'Time [s]');
            set(mainHandles.axes2,'XTickLabel',num2str(get(mainHandles.axes2,'XTick').'))
            semilogx(mainHandles.axes3,0,0)
            xlabel(mainHandles.axes3,'Frequency [Hz]');
            xlim(mainHandles.axes3,[20 20000])
            set(mainHandles.axes3,'XTickLabel',num2str(get(mainHandles.axes3,'XTick').'))
            set(mainHandles.audiodatatext,'String',[]);
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.IR_btn,'Visible','off');
            set(mainHandles.tools_panel,'Visible','off');
            set(mainHandles.process_panel,'Visible','off');
            set(mainHandles.analysis_panel,'Visible','off');
            set(mainHandles.playback_panel,'Visible','off');
            set(mainHandles.channel_panel,'Visible','off');
            set([mainHandles.time_popup mainHandles.freq_popup mainHandles.smoothtime_popup mainHandles.smoothfreq_popup],'Visible','off');
            set(mainHandles.logtime_chk,'Visible','off');
            set(mainHandles.logfreq_chk,'Visible','off');
            setappdata(hMain,'testsignal', []);
        end
    end
end  % mySelectFcn