close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_pso.json');
data = jsondecode(jsonData);

data

monte_carlo_run = length(data.optimal_values_all);
output_folder = 'Risultati';

% Parametri ottimali
fig = figure;
boxplot(data.optimal_params_all, 'Labels', {'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'});
xlabel('Parametri');
ylabel('Valori Ottimali');
grid on;
saveas(fig, fullfile(output_folder, 'distribuzione_parametri_ottimali_pso.png'));
close(fig);

% Evoluzione dei parametri ottimali tra le simulazioni
fig = figure;
hold on;
num_params = size(data.optimal_params_all, 2);
colors = lines(num_params);
for i = 1:num_params
    plot(data.optimal_params_all(:, i), '-o', 'LineWidth', 1.5, 'Color', colors(i, :));
end
hold off;
xlabel('Simulazione');
ylabel('Valore del parametro');
legend({'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, 'Location', 'best');
grid on;
saveas(fig, fullfile(output_folder, 'evoluzione_parametri_ottimali_pso.png'));
close(fig);

% Grafico della fitness
fig = figure;
bar(data.optimal_values_all, 'FaceColor', 'm');
xlabel('Simulazione');
ylabel('Miglior valore di fitness');
grid on;
saveas(fig, fullfile(output_folder, 'andamento_fitness_pso.png'));
close(fig);

% Grafico dell'errore
fig = figure;
hold on;
bar(data.rmse_values_all);
hold off;
xlabel('Simulazione');
ylabel('RMSE');
grid on;
saveas(fig, fullfile(output_folder, 'evoluzione_rmse_pso.png'));
close(fig);

results_table = table((1:monte_carlo_run)', data.optimal_values_all, data.rmse_values_all, ...
    'VariableNames', {'Simulazione', 'ValoreFitness', 'RMSE'});

writetable(results_table, fullfile(output_folder, 'risultati_simulazioni_pso.csv'));

