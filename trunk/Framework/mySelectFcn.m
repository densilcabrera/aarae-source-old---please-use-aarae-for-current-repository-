% The tree-node selection callback
% This function is almost the brains behind the tree's response to
% selection commands, it controls also visibility of some functions
% depending on what type of signal is selected and its contents.
function nodes = mySelectFcn(tree, value)
    pause on
    % Get handles of main window
    aarae_fig = findobj('Tag','aarae');
    mainHandles = guidata(aarae_fig);
    selectedNodes = tree.getSelectedNodes; % Get selected leaf
    if length(selectedNodes) > 1
        set(mainHandles.compare_btn,'Visible','on')
    else
        set(mainHandles.compare_btn,'Visible','off')
    end
    if ~isempty(selectedNodes)
        % Call the 'desktop'
        hMain = getappdata(0,'hMain');
        selectedNodes = selectedNodes(1);
        audiodata = selectedNodes.handle.UserData;
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
            set(mainHandles.data_panel1,'Visible','off');
            set(mainHandles.data_panel2,'Visible','off');
            set(mainHandles.IR_btn,'Visible','off'); 
            set(mainHandles.tools_panel,'Visible','on');
            if ~strcmp(audiodata.datatype,'syscal')
                set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','on');
            else
                set(mainHandles.edit_btn,'Enable','on');
                set(mainHandles.cal_btn,'Enable','off');
            end
            set(mainHandles.axestime,'Visible','on');
            set(mainHandles.axesfreq,'Visible','on');
            plot(mainHandles.axesdata,0,0)
            set(mainHandles.axesdata,'Visible','off');
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
                if ndims(audiodata.audio) == 3, cmap = colormap(hsv(size(audiodata.audio,3))); end
                if ndims(audiodata.audio) >= 4, cmap = colormap(copper(size(audiodata.audio,4))); end
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            else
                cmap = colormap(lines(size(audiodata.audio,2)));
                set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
            end
            pause(0.1)
            refreshplots(mainHandles,'time')
            refreshplots(mainHandles,'freq')
            if isfield(audiodata,'audio2') && ~isempty(audiodata.audio2)%(strcmp(audiodata.datatype,'measurements') || strcmp(audiodata.datatype,'testsignals') || strcmp(audiodata.datatype,'processed'))
                set(mainHandles.IR_btn,'Visible','on'); % Display process IR button if selection is a measurement based on a sine sweep
            end
            pause(0.1)
        elseif ~isempty(audiodata) && ~isfield(audiodata,'audio')% If there's data saved in the leaf but not audio...
            plot(mainHandles.axestime,0,0)
            semilogx(mainHandles.axesfreq,0,0)
            set(mainHandles.axestime,'Visible','off');
            set(mainHandles.axesfreq,'Visible','off');
            set(mainHandles.axesdata,'Visible','on');
            set(mainHandles.audiodatatext,'String',[]);
            datatext = evalc('audiodata');
            set(mainHandles.datatext,'Visible','on');
            set(mainHandles.datatext,'String',['Selected: ' selectedNodes.getName.char datatext]); % Output contents in textbox below the tree
            cla(mainHandles.axesdata)
            if isfield(audiodata,'lines')
                set(mainHandles.data_panel1,'Visible','on');
                set(mainHandles.nchart_popup,'String',[' ';fieldnames(audiodata.lines)])
                %set(mainHandles.nchart_popup,'Value',1)
            else
                set(mainHandles.data_panel1,'Visible','off');
            end
            if isfield(audiodata,'tables')
                set(mainHandles.data_panel2,'Visible','on');
                %set(mainHandles.Xvalues_sel,'SelectedObject',mainHandles.radiobutton1);
                set(mainHandles.ntable_popup,'String',cellstr(num2str((1:length(audiodata.tables))')));
                %set(mainHandles.ntable_popup,'Value',1);
                ntable = get(mainHandles.ntable_popup,'Value');
                Xvalues = get(mainHandles.Xvalues_sel,'SelectedObject');
                Xvalues = get(Xvalues,'tag');
                switch Xvalues
                    case 'radiobutton1'
                        if size(audiodata.tables(ntable).Data,2) < get(mainHandles.Yvalues_box,'Value'), set(mainHandles.Yvalues_box,'Value',1); end
                        bar(mainHandles.axesdata,audiodata.tables(ntable).Data(:,get(mainHandles.Yvalues_box,'Value')),'FaceColor',[0 0.5 0.5])
                        set(mainHandles.axesdata,'Xtick',1:length(audiodata.tables(ntable).RowName),'XTickLabel',audiodata.tables(ntable).RowName)
                        set(mainHandles.Xvalues_box,'String',audiodata.tables(ntable).RowName,'Value',1)
                        set(mainHandles.Yvalues_box,'String',audiodata.tables(ntable).ColumnName)
                    case 'radiobutton2'
                        if size(audiodata.tables(ntable).Data,1) < get(mainHandles.Yvalues_box,'Value'), set(mainHandles.Yvalues_box,'Value',1); end
                        bar(mainHandles.axesdata,audiodata.tables(ntable).Data(get(mainHandles.Yvalues_box,'Value'),:),'FaceColor',[0 0.5 0.5])
                        set(mainHandles.axesdata,'Xtick',1:length(audiodata.tables(ntable).ColumnName),'XTickLabel',audiodata.tables(ntable).ColumnName)
                        set(mainHandles.Xvalues_box,'String',audiodata.tables(ntable).ColumnName,'Value',1)
                        set(mainHandles.Yvalues_box,'String',audiodata.tables(ntable).RowName)
                end
                %set(mainHandles.axesdata,'XTickLabel',audiodata.tables(1).RowName)
            else
                set(mainHandles.data_panel2,'Visible','off');
            end
            pause(0.000001)
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
            pause(0.000001)
        else
            % If selection has no data, hide everything and don't display
            % data
            plot(mainHandles.axestime,0,0)
            semilogx(mainHandles.axesfreq,0,0)
            plot(mainHandles.axesdata,0,0)
            set(mainHandles.axestime,'Visible','off');
            set(mainHandles.axesfreq,'Visible','off');
            set(mainHandles.axesdata,'Visible','off');
            set(mainHandles.audiodatatext,'String',[]);
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.data_panel1,'Visible','off');
            set(mainHandles.data_panel2,'Visible','off');
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
            pause(0.000001)
        end
    end
    pause off
end  % mySelectFcn