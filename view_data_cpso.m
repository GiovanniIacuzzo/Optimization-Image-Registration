close all;
clear;
clc;

jsonData = fileread('monte_carlo_results_cpso.json');
data = jsondecode(jsonData);

monte_carlo_run = length(data.execution_times_all);
output_folder = 'Risultati';

% Migliora la leggibilità dei grafici
set(0, 'DefaultAxesFontSize', 14, 'DefaultAxesFontWeight', 'bold');
set(0, 'DefaultLineLineWidth', 2);

% Colore blu uniforme per tutti i grafici
blueColor = [0 0.447 0.741];

% %% Grafico della convergenza della funzione obiettivo
% fig = figure;
% hold on;
% colors = lines(monte_carlo_run);
% for i = 1:monte_carlo_run
%     plot(data.convergence_all{i}, 'Color', colors(i, :), 'LineWidth', 2);
% end
% hold off;
% xlabel('Iterazioni', 'FontWeight', 'bold');
% ylabel('Valore della Funzione Obiettivo', 'FontWeight', 'bold');
% legend(arrayfun(@(x) sprintf('Run %d', x), 1:monte_carlo_run, 'UniformOutput', false), 'Location', 'bestoutside');
% grid on;
% %saveas(fig, fullfile(output_folder, 'convergenza_funzione_obiettivo_cpso.png'));
% %close(fig);
% 
% %% Boxplot dei parametri ottimali
% fig = figure;
% boxplot(data.optimal_params_all, 'Labels', {'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, ...
%     'Colors', blueColor);
% xlabel('Parametri', 'FontWeight', 'bold');
% ylabel('Valori Ottimali', 'FontWeight', 'bold');
% grid on;
% % saveas(fig, fullfile(output_folder, 'distribuzione_parametri_ottimali_cpso.png'));
% % close(fig);
% 
% %% Evoluzione dei parametri ottimali tra le simulazioni
% fig = figure;
% hold on;
% num_params = size(data.optimal_params_all, 2);
% colors = lines(num_params);
% for i = 1:num_params
%     plot(data.optimal_params_all(:, i), '-o', 'LineWidth', 2, 'Color', colors(i, :), 'MarkerSize', 6, 'MarkerFaceColor', colors(i, :));
% end
% hold off;
% xlabel('Simulazione', 'FontWeight', 'bold');
% ylabel('Valore del parametro', 'FontWeight', 'bold');
% legend({'tx', 'ty', 'tz', 'theta_x', 'theta_y', 'theta_z', 'scale'}, 'Location', 'bestoutside');
% grid on;
% %saveas(fig, fullfile(output_folder, 'evoluzione_parametri_ottimali_cpso.png'));
% %close(fig);
% 
% %% Tempo di esecuzione per ogni simulazione
% fig = figure;
% bar(data.execution_times_all, 'FaceColor', blueColor);
% xlabel('Simulazione', 'FontWeight', 'bold');
% ylabel('Tempo di esecuzione (s)', 'FontWeight', 'bold');
% grid on;
% % saveas(fig, fullfile(output_folder, 'tempo_esecuzione_cpso.png'));
% % close(fig);

%% Grafico della fitness
fig = figure;
bar(data.optimal_values_all, 'FaceColor', blueColor);
xlabel('Run', 'FontWeight', 'bold');
ylabel('Fitness value', 'FontWeight', 'bold');
grid on;
% saveas(fig, fullfile(output_folder, 'andamento_fitness_cpso.png'));
% close(fig);

%% Grafico dell'errore (RMSE)
fig = figure;
bar(data.rmse_values_all, 'FaceColor', blueColor);
xlabel('Run', 'FontWeight', 'bold');
ylabel('RMSE', 'FontWeight', 'bold');
grid on;
% saveas(fig, fullfile(output_folder, 'evoluzione_rmse_cpso.png'));
% close(fig);

%% Salvataggio risultati in CSV
% results_table = table((1:monte_carlo_run)', data.execution_times_all, data.optimal_values_all, data.rmse_values_all, ...
%     'VariableNames', {'Simulazione', 'TempoEsecuzione', 'ValoreFitness', 'RMSE'});
% writetable(results_table, fullfile(output_folder, 'risultati_simulazioni_cpso.csv'));
