close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_pso.json');
data = jsondecode(jsonData);

monte_carlo_run = length(data.optimal_values_all);
output_folder = 'Risultati';

% Migliora la leggibilità dei grafici
set(0, 'DefaultAxesFontSize', 14, 'DefaultAxesFontWeight', 'bold');
set(0, 'DefaultLineLineWidth', 2);

% Colore blu uniforme per tutti i grafici
blueColor = [0 0.447 0.741];

% %% Boxplot dei parametri ottimali
% fig = figure;
% boxplot(data.optimal_params_all, 'Labels', {'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, ...
%     'Colors', blueColor);
% xlabel('Parametri', 'FontWeight', 'bold');
% ylabel('Valori Ottimali', 'FontWeight', 'bold');
% grid on;
% % saveas(fig, fullfile(output_folder, 'distribuzione_parametri_ottimali_pso.png'));
% % close(fig);
% 
% %% Evoluzione dei parametri ottimali tra le simulazioni
% fig = figure;
% hold on;
% num_params = size(data.optimal_params_all, 2);
% for i = 1:num_params
%     plot(data.optimal_params_all(:, i), '-o', 'LineWidth', 2, 'Color', blueColor, 'MarkerSize', 6, 'MarkerFaceColor', blueColor);
% end
% hold off;
% xlabel('Simulazione', 'FontWeight', 'bold');
% ylabel('Valore del parametro', 'FontWeight', 'bold');
% legend({'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, 'Location', 'bestoutside');
% grid on;
% % saveas(fig, fullfile(output_folder, 'evoluzione_parametri_ottimali_pso.png'));
% % close(fig);

%% Grafico della fitness
fig = figure;
bar(data.optimal_values_all, 'FaceColor', blueColor);
xlabel('Run', 'FontWeight', 'bold');
ylabel('Fitness value', 'FontWeight', 'bold');
grid on;
% saveas(fig, fullfile(output_folder, 'andamento_fitness_pso.png'));
% close(fig);

%% Grafico dell'errore (RMSE)
fig = figure;
bar(data.rmse_values_all, 'FaceColor', blueColor);
xlabel('Run', 'FontWeight', 'bold');
ylabel('RMSE', 'FontWeight', 'bold');
grid on;
% saveas(fig, fullfile(output_folder, 'evoluzione_rmse_pso.png'));
% close(fig);

%% Salvataggio risultati in CSV
% results_table = table((1:monte_carlo_run)', data.optimal_values_all, data.rmse_values_all, ...
%     'VariableNames', {'Simulazione', 'ValoreFitness', 'RMSE'});
% writetable(results_table, fullfile(output_folder, 'risultati_simulazioni_pso.csv'));
