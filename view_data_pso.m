close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_pso.json');
data = jsondecode(jsonData);

data

monte_carlo_run = length(data.optimal_values_all);

% Parametri ottimali
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


% Grafico della fitness
figure;
bar(data.optimal_values_all, 'FaceColor', 'm');
xlabel('Simulazione');
ylabel('Miglior valore di fitness');
title('Andamento della fitness per ogni simulazione');
grid on;

% Grafico dell'errore
figure;
hold on;
bar(data.rmse_values_all);
hold off;
xlabel('Simulazione');
ylabel('RMSE');
title('Evoluzione del valore di RMSE');
grid on;



