function spheregrid(radius,degstep,LineWidth,Color,LineStyle)
% plot a spherical grid in 3D

if ~exist('radius', 'var')
    radius = 1;
end

if ~exist('degstep', 'var')
    degstep = 30;
end
if rem(180,degstep) > 1e-7
    disp('spheregrid degree step does not evenly divide a semicircle');
end

if ~exist('LineWidth','var')
    LineWidth = 0.5;
end

if ~exist('Color','var')
    Color = [0.5,0.5,0.5];
end

if ~exist('LineStyle','var')
    LineStyle = ':';
end

% plot lines of lattitude

numberoflines = floor(180/degstep);
radstep = pi*degstep/180;
az = (0:2*pi/360:2*pi)';
for n = 1:numberoflines
    el = ((n-1)*radstep-pi/2);
    [x,y,z] = sph2cart(az,el*ones(size(az)),radius*ones(size(az)));
    plot3(x,y,z,'Color',Color,'LineWidth',LineWidth,'LineStyle',LineStyle);
    hold on
end


% plot lines of longitude
numberoflines = floor(360/degstep);
el = -pi/2:pi/180:pi/2;
for n = 1:numberoflines
    az = ((n-1)*radstep);
    [x,y,z] = sph2cart(az*ones(size(el)),el,radius*ones(size(el)));
    plot3(x,y,z,'Color',Color,'LineWidth',LineWidth,'LineStyle',LineStyle);
    hold on
end

