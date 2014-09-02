function out = swapaudiofields_aarae(in)
% If more than one audio field exists, then the field contents are swapped.
% If more than two audio fields exist, then you can decide how the field
% contents are moved via a dialog box.


% list of possible audio field names
audiofieldnames = {'audio','audio2','audio3','audio4','audio5','audio6',...
    'audio7','audio8','audio9','audio10','audio11','audio12','audio13',...
    'audio14','audio15','audio16'};

% check which audio fields exist
audiofields = [isfield(in,audiofieldnames{1}), ...
    isfield(in,audiofieldnames{2}), ...
    isfield(in,audiofieldnames{3}), ...
    isfield(in,audiofieldnames{4}), ...
    isfield(in,audiofieldnames{5}), ...
    isfield(in,audiofieldnames{6}), ...
    isfield(in,audiofieldnames{7}), ...
    isfield(in,audiofieldnames{8}), ...
    isfield(in,audiofieldnames{9}), ...
    isfield(in,audiofieldnames{10}), ...
    isfield(in,audiofieldnames{11}), ...
    isfield(in,audiofieldnames{12}), ...
    isfield(in,audiofieldnames{13}), ...
    isfield(in,audiofieldnames{14}), ...
    isfield(in,audiofieldnames{15}), ...
    isfield(in,audiofieldnames{16})];

% remove fields that don't exist from the list of field names
audiofieldnames = audiofieldnames(audiofields);

out = in;

if sum(audiofields) == 1
    % if only one audio field exists, then swapping cannot be done
    warndlg('Unable to swap audio fields because only one audio field exists','AARAE info','modal');
    
elseif sum(audiofields) == 2
    % if only two audio fields exist, then swap them without dialog
    out.(audiofieldnames{1}) = in.(audiofieldnames{2});
    out.(audiofieldnames{2}) = in.(audiofieldnames{1});
    out.chanID = cellstr([repmat('Chan',size(out.audio,2),1) num2str((1:size(out.audio,2))')]);
else
    % if more than two audio fields exist, then ask the user how to swap them

    
    param = inputdlg(audiofieldnames,...
        'Swap audio fields',... % window title.
        [1 60],...
        cellstr(num2str(circshift((1:sum(audiofields))',1)))); % defaults
    
    param = str2num(char(param));
    

    
    % the following allows users to, alternatively, write the audio suffix
    % instead of just sorting the outputs (either is ok). However each 
    % value must be unique or the results may be unexpected.
    [~, param] = sort(param);
    
    if length(param) < sum(audiofields), param = []; end
    if ~isempty(param)
        for n = 1:sum(audiofields)
            out.(audiofieldnames{param(n)}) = in.(audiofieldnames{n});
        end
    end

end