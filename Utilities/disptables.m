function fighandle = disptables(fig,tables)

if length(fig) ~= length(tables), window = 'single'; end
if length(fig) == length(tables), window = 'multi'; end
figpos = get(fig,'Position');
ntables = length(tables);
if ntables == 1
    window = 'multi';
    temp = figpos;
    clear figpos
    figpos{1,1} = temp;
end
switch window
    case 'multi'
        for i = 1:ntables
            %fig(i) = figure;
            set(tables(i),'Parent',fig(i))
            s = get(tables(i),'Extent');
            set(fig(i),'Position',[figpos{i,1}(1) figpos{i,1}(2) s(3) s(4)],'WindowButtonDownFcn','copytoclipboard')
            set(tables(i),'Position',s)
        end
    case 'single'
        %f = figure;
        set(tables,'Parent',fig)
        s = get(tables,'Extent');
        s = flipud(s);
        tables = fliplr(tables);
        set(tables(1),'Position',s{1,1})
        y = s{1,1}(1,4);
        x = s{1,1}(1,3);
        for i = 2:ntables
            set(tables(i),'Position',[s{i,1}(1,1) y+10 s{i,1}(1,3) s{i,1}(1,4)])
            y = y + s{i,1}(1,4) + 10;
            if s{i,1}(1,3) > x, x = s{i,1}(1,3); end
        end
        set(fig,'Position',[figpos(1) figpos(2) x y],'WindowButtonDownFcn','copytoclipboard')
end
fighandle = fig;