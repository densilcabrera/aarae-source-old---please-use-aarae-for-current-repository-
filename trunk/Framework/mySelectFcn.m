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
        aarae_fig = findobj('Tag','aarae');
        mainHandles = guidata(aarae_fig);
        if ~isempty(audiodata) && strcmp(audiodata.datatype,'syscal')
            mainHandles.syscalstats = audiodata;
            set(mainHandles.signaltypetext,'String',[selectedNodes.getName.char ' selected']);
            guidata(aarae_fig,mainHandles);
        end
        if ~isempty(audiodata) && isfield(audiodata,'audio')% If there's data saved in the leaf...
            audiodatatext = evalc('audiodata');
            set(mainHandles.audiodatatext,'String',['Selected: ' selectedNodes.getName.char audiodatatext]); % Output contents in textbox below the tree
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.IR_btn,'Visible','off'); 
            set(mainHandles.tools_panel,'Visible','on');
            set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','on');
            set(mainHandles.time_popup,'Visible','on');
            set(mainHandles.freq_popup,'Visible','on');
            set(mainHandles.smoothtime_popup,'Visible','on');
            set(mainHandles.smoothfreq_popup,'Visible','on');
            set(mainHandles.logtime_chk,'Visible','on');
            set(mainHandles.logfreq_chk,'Visible','on');
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
            if isfield(audiodata,'properties'), set(mainHandles.properties_btn,'Visible','on'); else set(mainHandles.properties_btn,'Visible','off'); end
            setappdata(hMain,'testsignal', audiodata); % Set leaf contents in the 'desktop'
            if ndims(audiodata.audio) > 2
                set(mainHandles.channel_panel,'Visible','on');
                set(mainHandles.IN_nchannel,'String','1');
                set(mainHandles.tchannels,'String',['/ ' num2str(size(audiodata.audio,2))]);
                cmap = colormap(hsv(size(audiodata.audio,3)));
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            else
                cmap = colormap(lines(size(audiodata.audio,2)));
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            end
            refreshplots(mainHandles,'time')
            refreshplots(mainHandles,'freq')
            if isfield(audiodata,'audio2') && (strcmp(audiodata.datatype,'measurements') || strcmp(audiodata.datatype,'testsignals') || strcmp(audiodata.datatype,'processed'))
                set(mainHandles.IR_btn,'Visible','on'); % Display process IR button if selection is a measurement based on a sine sweep
            end
        elseif ~isempty(audiodata) && ~isfield(audiodata,'audio')% If there's data saved in the leaf but not audio...
            plot(mainHandles.axestime,0,0)
            axis(mainHandles.axestime,[0 10 -1 1]);
            xlabel(mainHandles.axestime,'Time [s]');
            set(mainHandles.axestime,'XTickLabel',num2str(get(mainHandles.axestime,'XTick').'))
            semilogx(mainHandles.axesfreq,0,0)
            xlabel(mainHandles.axesfreq,'Frequency [Hz]');
            xlim(mainHandles.axesfreq,[20 20000])
            set(mainHandles.axesfreq,'XTickLabel',num2str(get(mainHandles.axesfreq,'XTick').'))
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
            set([mainHandles.complextime mainHandles.complexfreq],'Visible','off')
            if isfield(audiodata,'properties'), set(mainHandles.properties_btn,'Visible','on'); else set(mainHandles.properties_btn,'Visible','off'); end
            setappdata(hMain,'testsignal', []);
        else
            % If selection has no data, hide everything and don't display
            % data
            plot(mainHandles.axestime,0,0)
            axis(mainHandles.axestime,[0 10 -1 1]);
            xlabel(mainHandles.axestime,'Time [s]');
            set(mainHandles.axestime,'XTickLabel',num2str(get(mainHandles.axestime,'XTick').'))
            semilogx(mainHandles.axesfreq,0,0)
            xlabel(mainHandles.axesfreq,'Frequency [Hz]');
            xlim(mainHandles.axesfreq,[20 20000])
            set(mainHandles.axesfreq,'XTickLabel',num2str(get(mainHandles.axesfreq,'XTick').'))
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
            set([mainHandles.complextime mainHandles.complexfreq],'Visible','off')
            set(mainHandles.properties_btn,'Visible','off');
            setappdata(hMain,'testsignal', []);
        end
    end
end  % mySelectFcn