% The tree-node selection callback
% This function is almost the brains behind the tree's response to
% selection commands, it controls also visibility of some functions
% depending on what type of signal is selected and its contents.
function mySelectFcn(tree, ~)
    pause on
    % Get handles of main window
    aarae_fig = findobj('Tag','aarae');
    mainHandles = guidata(aarae_fig);
    selectedNodes = tree.getSelectedNodes; % Get selected leaf
    if ~isempty(selectedNodes)
        % Call the 'desktop'
        hMain = getappdata(0,'hMain');
        selectedNodes = selectedNodes(1);
        audiodata = selectedNodes.handle.UserData;
        if ~isfield(audiodata,'audio')
            set(mainHandles.compare_btn,'Enable','off')
        else
            set(mainHandles.compare_btn,'Enable','on')
        end
        if ~isempty(audiodata) && strcmp(audiodata.datatype,'syscal')
            mainHandles.syscalstats = audiodata;
            set(mainHandles.signaltypetext,'String',[selectedNodes.getName.char ' selected']);
        end
        if ~isempty(audiodata) && isfield(audiodata,'audio')% If there's data saved in the leaf...
            Details = audiodata;
            if isfield(Details,'datatype'), Details = rmfield(Details,'datatype'); end
            if isfield(Details,'funcallback'), Details = rmfield(Details,'funcallback'); end
            if isfield(Details,'properties'), Details = rmfield(Details,'properties'); end %#ok : used in lines 30 and 31
            audiodatatext = evalc('Details');
            clear('Details')
            set(mainHandles.audiodatatext,'String',['Selected: ' selectedNodes.getName.char audiodatatext]); % Output contents in textbox below the tree
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.data_panel1,'Visible','off');
            set(mainHandles.data_panel2,'Visible','off'); 
            set(mainHandles.tools_panel,'Visible','on');
            if ~strcmp(audiodata.datatype,'syscal')
                set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','on');
            else
                set(mainHandles.edit_btn,'Enable','on');
                set(mainHandles.cal_btn,'Enable','off');
            end
            set(mainHandles.axestime,'Visible','on');
            set(mainHandles.axesfreq,'Visible','on');
            cla(mainHandles.axesdata)
            set(mainHandles.axesdata,'Visible','off');
            set(mainHandles.time_popup,'Visible','on');
            set(mainHandles.freq_popup,'Visible','on');
            set([mainHandles.text16,mainHandles.text17,mainHandles.text18,mainHandles.text19,mainHandles.text20,mainHandles.text21],'Visible','on')
            set([mainHandles.To_time,mainHandles.To_freq],'String','0')
            mainHandles.To_time_IN = 0;
            mainHandles.To_freq_IN = 0;
            if length(audiodata.audio) <= mainHandles.Preferences.maxtimetodisplay*audiodata.fs
                set([mainHandles.Tf_time,mainHandles.Tf_freq],'String',num2str(length(audiodata.audio)/audiodata.fs))
                mainHandles.Tf_time_IN = length(audiodata.audio)/audiodata.fs;
                mainHandles.Tf_freq_IN = length(audiodata.audio)/audiodata.fs;
            else
                set([mainHandles.Tf_time,mainHandles.Tf_freq],'String',num2str(mainHandles.Preferences.maxtimetodisplay))
                mainHandles.Tf_time_IN = mainHandles.Preferences.maxtimetodisplay;
                mainHandles.Tf_freq_IN = mainHandles.Preferences.maxtimetodisplay;
            end
            set([mainHandles.text20,mainHandles.text21],'String',[num2str(length(audiodata.audio)/audiodata.fs) ' s'])
            %set(mainHandles.smoothtime_popup,'Visible','on');
            %set(mainHandles.smoothfreq_popup,'Visible','on');
            %set(mainHandles.logtime_chk,'Visible','on');
            %set(mainHandles.logfreq_chk,'Visible','on');
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
            if ~ismatrix(audiodata.audio)
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
            pause(0.001)
            refreshplots(mainHandles,'time')
            pause(0.001)
            refreshplots(mainHandles,'freq')
            if isfield(audiodata,'audio2') && ~isempty(audiodata.audio2) && ismatrix(audiodata.audio)%(strcmp(audiodata.datatype,'measurements') || strcmp(audiodata.datatype,'testsignals') || strcmp(audiodata.datatype,'processed'))
                set(mainHandles.IR_btn,'Enable','on');
            else
                set(mainHandles.IR_btn,'Enable','off');% Display process IR button if selection is a measurement based on a sine sweep
            end
            pause(0.001)
        elseif ~isempty(audiodata) && ~isfield(audiodata,'audio')% If there's data saved in the leaf but not audio...
            plot(mainHandles.axestime,0,0)
            plot(mainHandles.axesfreq,0,0)
            set(mainHandles.axestime,'Visible','off');
            set(mainHandles.axesfreq,'Visible','off');
            set([mainHandles.text16,mainHandles.text17,mainHandles.text18,mainHandles.text19,mainHandles.text20,mainHandles.text21],'Visible','off')
            set(mainHandles.axesdata,'Visible','on');
            set(mainHandles.audiodatatext,'String',[]);
            datatext = evalc('audiodata');
            set(mainHandles.datatext,'Visible','on');
            set(mainHandles.datatext,'String',['Selected: ' selectedNodes.getName.char datatext]); % Output contents in textbox below the tree
            cla(mainHandles.axesdata)
            if isfield(audiodata,'data')
                set(mainHandles.data_panel1,'Visible','on');
                if ~ismatrix(audiodata.data)
                    if ndims(audiodata.data) == 3, cmap = colormap(hsv(size(audiodata.data,3))); end
                    if ndims(audiodata.data) >= 4, cmap = colormap(copper(size(audiodata.data,4))); end
                    set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
                else
                    cmap = colormap(lines(size(audiodata.data,2)));
                    set(mainHandles.aarae,'DefaultAxesColorOrder',cmap)
                end
                filltable(audiodata,mainHandles)
                doresultplot(mainHandles)
                mainHandles.tabledata = get(mainHandles.cattable,'Data');
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
            pause(0.001)
            set(mainHandles.tools_panel,'Visible','on');
            set([mainHandles.edit_btn mainHandles.cal_btn],'Enable','off')
            set([mainHandles.time_popup,mainHandles.freq_popup,mainHandles.smoothtime_popup,mainHandles.smoothfreq_popup,mainHandles.To_freq,mainHandles.Tf_freq,mainHandles.To_time,mainHandles.Tf_time],'Visible','off');
            set(mainHandles.logtime_chk,'Visible','off');
            set(mainHandles.logfreq_chk,'Visible','off');
            set(mainHandles.process_panel,'Visible','off');
            set(mainHandles.analysis_panel,'Visible','off');
            set(mainHandles.playback_panel,'Visible','off');
            set(mainHandles.channel_panel,'Visible','off');
            set([mainHandles.complextime mainHandles.complexfreq],'Visible','off')
            if isfield(audiodata,'properties'), set(mainHandles.properties_btn,'Visible','on'); else set(mainHandles.properties_btn,'Visible','off'); end
            setappdata(hMain,'testsignal', []);
            pause(0.001)
        else
            % If selection has no data, hide everything and don't display
            % data
            plot(mainHandles.axestime,0,0)
            semilogx(mainHandles.axesfreq,0,0)
            plot(mainHandles.axesdata,0,0)
            set(mainHandles.axestime,'Visible','off');
            set(mainHandles.axesfreq,'Visible','off');
            set(mainHandles.axesdata,'Visible','off');
            set([mainHandles.text16,mainHandles.text17,mainHandles.text18,mainHandles.text19,mainHandles.text20,mainHandles.text21],'Visible','off')
            set(mainHandles.audiodatatext,'String',[]);
            set(mainHandles.datatext,'Visible','off');
            set(mainHandles.datatext,'String',[]);
            set(mainHandles.data_panel1,'Visible','off');
            set(mainHandles.data_panel2,'Visible','off');
            set(mainHandles.tools_panel,'Visible','off');
            set(mainHandles.process_panel,'Visible','off');
            set(mainHandles.analysis_panel,'Visible','off');
            set(mainHandles.playback_panel,'Visible','off');
            set(mainHandles.channel_panel,'Visible','off');
            set([mainHandles.time_popup,mainHandles.freq_popup,mainHandles.smoothtime_popup,mainHandles.smoothfreq_popup,mainHandles.To_freq,mainHandles.Tf_freq,mainHandles.To_time,mainHandles.Tf_time],'Visible','off');
            set(mainHandles.logtime_chk,'Visible','off');
            set(mainHandles.logfreq_chk,'Visible','off');
            set([mainHandles.complextime mainHandles.complexfreq],'Visible','off')
            set(mainHandles.properties_btn,'Visible','off');
            setappdata(hMain,'testsignal', []);
            pause(0.001)
        end
    end
    pause off
    guidata(aarae_fig,mainHandles);
end  % mySelectFcn

function filltable(audiodata,handles)
fields = fieldnames(audiodata);
fields = fields(3:end-1);
categories = fields(mod(1:length(fields),2) == 1);
catdata = cell(size(categories));
catunits = cell(size(categories));
catorcont = cell(size(categories));
for n = 1:length(categories)
    catunits{n,1} = audiodata.(genvarname([categories{n,1} 'info'])).units;
    catorcont{n,1} = audiodata.(genvarname([categories{n,1} 'info'])).axistype;
    if islogical(catorcont{n,1}) && catorcont{n,1} == true
        catdata{n,1} = ':';
    else
        catdata{n,1} = '[1]';
    end
end
dat = [categories,catdata,catunits,catorcont];
set(handles.cattable, 'Data', dat);
naxis = length(find([catorcont{:}] == true));
switch naxis
    case 0
        set(handles.chartfunc_popup,'String',{'distributionPlot','boxplot'},'Value',1)
    case 1
        set(handles.chartfunc_popup,'String',{'plot','semilogx','semilogy','loglog','distributionPlot','boxplot'},'Value',1)
    case 2
        set(handles.chartfunc_popup,'String',{'mesh','surf','imagesc'},'Value',1)
    otherwise
        set(handles.chartfunc_popup,'String',{[]},'Value',1)
end
end % End of function filltable