function copytoclipboard
fighandle = gcf;
children = findobj(fighandle,'Type','uitable');

bigone = [];
for i = 1:length(children)
    clear header
    clear table
    child = get(children(i));
    RowName = child.RowName;
    ColName = child.ColumnName;
    Data = child.Data;

    ColName = reshape(ColName',1,[]);
    [m n] = size(ColName);
    header(1:m,1:2:2*n) = {sprintf('\t')};
    header(1:m,2:2:2*n) = ColName;
    Data = num2cell(Data);
    [m n]  = size(Data);
    for k = 1:m
        for j = 1:n
            Data{k,j} = num2str(Data{k,j});
        end
    end
    RowandData = [RowName Data];
    [m n] = size(RowandData);
    table(1:m,1:2:2*n) = RowandData;
    table(1:m,2:2:2*n) = {sprintf('\t')};
    table(1:m,end) = {sprintf('\n')};
    table = reshape(table',1,[]);
    table = [header {sprintf('\n')} table {sprintf('\n')}];
    bigone = [bigone table];
end
t = sprintf('%s', bigone{:});
clipboard('Copy',t)
msgbox('Figure data copied to clipboard!','AARAE info');