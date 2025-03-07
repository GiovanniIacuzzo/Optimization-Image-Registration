close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_cpso.json');
data = jsondecode(jsonData);

data

monte_carlo_run = length(data.execution_times_all);

% Grafico della convergenza della funzione obiettivo
figure;
hold on;
for i = 1:monte_carlo_run
    plot(data.convergence_all{i}, 'LineWidth', 1.5);
end
hold off;
xlabel('Iterazioni');
ylabel('Valore della Funzione Obiettivo');
title('Convergenza della funzione obiettivo');
legend(arrayfun(@(x) sprintf('Run %d', x), 1:monte_carlo_run, 'UniformOutput', false));
grid on;

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
colors = lines(num_params); % Crea una palette di colori distinti
for i = 1:num_params
    plot(data.optimal_params_all(:, i), '-o', 'LineWidth', 1.5, 'Color', colors(i, :));
end
hold off;
xlabel('Simulazione');
ylabel('Valore del parametro');
title('Evoluzione dei parametri ottimali tra le simulazioni');
legend({'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, 'Location', 'best');
grid on;

% Bar chart del tempo di esecuzione per ogni simulazione
figure;
bar(data.execution_times_all, 'FaceColor', 'm');
xlabel('Simulazione');
ylabel('Tempo di esecuzione (s)');
title('Tempo di esecuzione per ogni simulazione');
grid on;
