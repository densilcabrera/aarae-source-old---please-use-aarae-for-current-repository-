function setaxeslimits
compplot = gcf;
iplots = findobj(compplot,'Type','axes');
xlims = cell2mat(get(iplots,'Xlim'));
ylims = cell2mat(get(iplots,'Ylim'));
prompt = {'Xmin','Xmax','Ymin','Ymax'};
dlg_title = 'Axes limits';
num_lines = 1;
def = {num2str(min(xlims(:,1))),num2str(max(xlims(:,2))),num2str(min(ylims(:,1))),num2str(max(ylims(:,2)))};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if ~isempty(answer)
    xmin = str2num(answer{1});
    xmax = str2num(answer{2});
    ymin = str2num(answer{3});
    ymax = str2num(answer{4});
    if ~isempty(xmin) && ~isempty(xmax) && ~isempty(ymin) && ~isempty(ymax)
        set(iplots,'Xlim',[xmin xmax])
        set(iplots,'Ylim',[ymin ymax])
    else
        warndlg('Invalid entry','AARAE info')
    end
end
