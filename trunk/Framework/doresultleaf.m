function [out,leafname] = doresultleaf(varargin)
% Save a copy of the input arguments
input = varargin;
% Assign first input argument to data variable
out.data = varargin{1};
out.datainfo.units = varargin{2};
out.datainfo.dimensions = varargin{3};
% Get the new leaf name
hasleafname = find(strcmp(varargin,'name'));
if ~isempty(hasleafname), leafname = varargin{hasleafname+1}; end

for n = 1:ndims(out.data)
    out.(genvarname(input{3*n+1})) = input{3*n+2};
    out.(genvarname([input{3*n+1} 'info'])).units = input{3*n+3};
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
handles.(genvarname(leafname)) = uitreenode('v0', leafname,  leafname, [], true);
handles.(genvarname(leafname)).UserData = out;
handles.results.add(handles.(genvarname(leafname)));
handles.mytree.reloadNode(handles.results);
handles.mytree.expand(handles.results);
guidata(aarae_fig, handles);
