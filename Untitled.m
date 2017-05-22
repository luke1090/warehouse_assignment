clear all; close all;
output;
o_paths;
o_routeplots;

x_size = 120;
y_size = 120;

x = floor(resolvedroutes / x_size) + 1;
y = rem(resolvedroutes, y_size);

%scatter(y, x);

% Do route definitions
figure;
hold on;

for i=1:length(paths)
    paths_i = cell2mat(paths(i));
    x_path = floor(paths_i / x_size) + 1;
    y_path = rem(paths_i, y_size);
    
    plot(y_path, x_path);
end
title('Route definitions');

% Do route plots
figure;
hold on;

for i=1:length(routeplots)
    routeplots_i = cell2mat(routeplots(i));
    x_path = floor(routeplots_i / x_size) + 1;
    y_path = rem(routeplots_i, y_size);
    
    plot(y_path, x_path);
end
title('Route plots');

figure;
comet(y, x);

clf;
pause;


comet(y, x);