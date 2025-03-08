close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_pso.json');
data = jsondecode(jsonData);

data

monte_carlo_run = length(data.optimal_params_all);

% Boxplot dei parametri ottimali
figure;
boxplot(data.optimal_params_all, ...
    'Labels', {'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'});
xlabel('Parametri');
ylabel('Valori Ottimali');
title('Distribuzione dei parametri ottimali');
grid on;

% Evoluzione dei parametri ottimali tra le simulazioni
figure;
hold on;
num_params = size(data.optimal_params_all, 2);
colors = lines(num_params);
for i = 1:num_params
    plot(data.optimal_params_all(:, i), '-o', 'LineWidth', 1.5, 'Color', colors(i, :));
end
hold off;
xlabel('Simulazione');
ylabel('Valore del parametro');
title('Evoluzione dei parametri ottimali tra le simulazioni');
legend({'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, 'Location', 'best');
grid on;

figure;
hold on;
opt_val = size(data.optimal_values_all, 2);
colors = lines(monte_carlo_run);
x = 1:monte_carlo_run; 

bar(x, data.optimal_values_all);
xticks(x);

hold off;
xlabel('Simulazione');
ylabel('Ottimo determinato');
title('Grafico del miglior valore di fitness');
grid on;

