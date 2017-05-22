clear all; close all;
% Plot a_star times

a_star_time_120;
a_star_time_200;
a_star_time_60;

d = fileparts(which('Untitled2.m'));


figure;
histogram(a_star_times_120, 30);
title('120');
saveas(gcf, [d filesep 'images\warehouse_solve_120.png'])

figure;
histogram(a_star_times_200, 30);
title('200');
saveas(gcf, [d filesep 'images\warehouse_solve_200.png'])

figure;
histogram(a_star_times_60, 30);
title('60');
saveas(gcf, [d filesep 'images\warehouse_solve_60.png'])