function [out,leafname] = doresultleaf(varargin)
% You may output data to be plotted in a variety of charts, including
% lines, mesh, surf, imagesc, loglog, and others depending on the
% number of dimensions of your data using the doresultleaf.m function:
% E.g.:
%
%    doresultleaf(myresultvariable,'Type [units]',{'Time','channels','Frequency'},...
%                 'Time',      t,                's',           true,...
%                 'channels',  chanID,           'categorical', [],...
%                 'Frequency', num2cell(bandfc), 'Hz',          false,...
%                 'name','my_results');
%
% Input arguments:
% #1: Your data variable. It can be multidimensional, make sure you
%     specify what each dimension is.
% #2: What is your data variable representing? is it level? is it
%     reverb time? make sure you label it appropriately and assign
%     units to it, this second argument is a single string.
% #3: This is a cell array where each cell contains the name of each
%     dimension.
%
% #4: Name of your first dimension. (String)
% #5: Matrix that matches your first dimension, in this case time.
% #6: Units of your first dimension. (String)
% #7: Can this dimension be used as a category? (true, false, [])
%
% Replicate arguments 4 to 7 for as many dimensions as your data
% variable has.
%
% The second last input argument is the string 'name', this helps the
% function identify that the last input argument is the name that will
% be displayed in AARAEs categorical tree under the results leaf.

% Save a copy of the input arguments
input = varargin(4:end);
% Assign first input argument to data variable
out.data = varargin{1};
out.datainfo.units = varargin{2};
out.datainfo.dimensions = varargin{3};
% Get the new leaf name
hasleafname = find(strcmp(varargin,'name'));
if ~isempty(hasleafname), leafname = varargin{hasleafname+1}; end

for n = 1:4:4*ndims(out.data)
    out.(genvarname(input{n})) = input{n+1};
    out.(genvarname([input{n} 'info'])).units = input{n+2};
    out.(genvarname([input{n} 'info'])).axistype = input{n+3};
end
out.datatype = 'results';
aarae_fig = findobj('Tag','aarae');
handles = guidata(aarae_fig);
selectedNodes = handles.mytree.getSelectedNodes;
leafname = [char(selectedNodes(handles.nleafs).getName) '_' leafname];
leafnameexist = isfield(handles,genvarname(leafname));
if leafnameexist == 1
    index = 1;
    % This while cycle is just to make sure no signals are
    % overwriten
    if length(genvarname([leafname,'_',num2str(index)])) >= namelengthmax, leafname = leafname(1:round(end/2)); end
    while isfield(handles,genvarname([leafname,'_',num2str(index)])) == 1
        index = index + 1;
    end
    leafname = [leafname,'_',num2str(index)];
end
iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/help_fx.png');

% Save as you go
save([cd '/Utilities/Backup/' leafname '.mat'], 'out');

handles.(genvarname(leafname)) = uitreenode('v0', leafname,  leafname, iconPath, true);
handles.(genvarname(leafname)).UserData = out;
handles.results.add(handles.(genvarname(leafname)));
handles.mytree.reloadNode(handles.results);
handles.mytree.expand(handles.results);
guidata(aarae_fig, handles);
