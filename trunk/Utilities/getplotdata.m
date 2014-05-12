function linea = getplotdata

linea.data = get(get(gca,'Children'));
linea.axisproperties = get(gca);
linea.axisproperties.xlabel = get(get(gca,'XLabel'),'String');
linea.axisproperties.ylabel = get(get(gca,'YLabel'),'String');
linea.axisproperties.zlabel = get(get(gca,'ZLabel'),'String');
%linea.axisproperties.xscale = get(gca,'XScale');
%linea.axisproperties.yscale = get(gca,'YScale');
%linea.axisproperties.zscale = get(gca,'ZScale');

end