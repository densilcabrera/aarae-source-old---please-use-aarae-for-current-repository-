function indices = partial_selection(in)

audiosize = size(in.audio);
prompt = cell(1,ndims(in.audio));
def = cell(1,ndims(in.audio));
dlgtitle = 'Data selection';

for i = 1:ndims(in.audio)
    prompt{1,i} = ['Dim' num2str(i)];
    def{1,i} = ['1:' num2str(audiosize(1,i))];
end

prompt{1,1} = 'Time in samples';
prompt{1,2} = 'Channels';
prompt{1,3} = 'Bands';

answer = inputdlg(prompt,dlgtitle,[1 50],def);

if any(cellfun(@isempty,answer)) || isempty(answer)
    warndlg('Invalid selection, process will be applied to the whole audio file.','AARAE info','modal')
    indices = def;
    indices = cellfun(@eval,indices,'UniformOutput',false);
else
    indices = cell(size(answer));
    for i = 1:length(answer), indices{i,1} = ['[' answer{i,1} ']']; end
    indices = cellfun(@eval,indices,'UniformOutput',false);
    try
        in.audio(indices{:});
    catch
        warndlg('Invalid selection, process will be applied to the whole audio file.','AARAE info','modal')
        indices = def;
        indices = cellfun(@eval,indices,'UniformOutput',false);
    end
end