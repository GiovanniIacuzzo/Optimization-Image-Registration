close all
clear
clc

fprintf("Inizio codice...\n");

fprintf("Caricamento immagini...\n");
fixedImageStruct = nii_tool('load', 'Task02_Heart/imagesTr/la_019.nii.gz');
movingImageStruct = nii_tool('load', 'Task02_Heart/labelsTr/la_019.nii.gz');

fixedImage = double(fixedImageStruct.img);
movingImage = double(movingImageStruct.img);

fixedImage = imgaussfilt3(fixedImage, 1);
movingImage = imgaussfilt3(movingImage, 1);

fprintf("Dimensioni immagine fissa: [%d %d %d]\n", size(fixedImage));
fprintf("Dimensioni immagine mobile: [%d %d %d]\n", size(movingImage));

if any(size(fixedImage) ~= size(movingImage))
    error('Le dimensioni delle immagini fissa e mobile non corrispondono!');
end

cb_ref = [floor(size(fixedImage,1)/5), floor(size(fixedImage,2)/5), floor(size(fixedImage,3)/5);
          floor(size(fixedImage,1)/5), floor(size(fixedImage,2)/5*4), floor(size(fixedImage,3)/5*4);
          floor(size(fixedImage,1)/5*4), floor(size(fixedImage,2)/5), floor(size(fixedImage,3)/5);
          floor(size(fixedImage,1)/5*4), floor(size(fixedImage,2)/5*4), floor(size(fixedImage,3)/5*4)];

lb = [-5, -5, -5, -pi/2, -pi/2, -pi/2, 0.9];  
ub = [5, 5, 5, pi/2, pi/2, pi/2, 1.1];

alpha = 0.2;

objective = @(params) objective_function(params, fixedImage, movingImage, alpha, cb_ref);
particles = 200;
sub_interval = 300;
dt = 10;

options = {'particles', particles, ...
    'sub_interval', sub_interval, ...
    'dt', dt, ...
    'Cognitive_constant', 2.05, ...
    'Social_constant', 3.05, ...
    'maxNoChange', 5 ...
};

monte_carlo_run = 5;

fprintf("Avvio ottimizzazione CPSO...\n");

optimal_params_all = zeros(monte_carlo_run, 7);
optimal_values_all = zeros(monte_carlo_run, 1);
execution_times_all = zeros(monte_carlo_run, 1);
convergence_all = cell(monte_carlo_run, 1);
mi_values_all = zeros(monte_carlo_run, 1);
rmse_values_all = zeros(monte_carlo_run, 1);

for i = 1:monte_carlo_run
    [optimal_params, optimal_value, execution_time, convergence] = CPSO(objective, 7, lb, ub, options);
    
    optimal_params_all(i, :) = optimal_params;
    optimal_values_all(i) = optimal_value;
    execution_times_all(i) = execution_time;
    convergence_all{i} = convergence;
    
    fprintf('\n\nIterazione %d:', i);
    fprintf('Parametri ottimali trovati:');
    fprintf('tx = %.4f, ty = %.4f, tz = %.4f, theta_x = %.4f, theta_y = %.4f, theta_z = %.4f, scale = %.4f\n', optimal_params);
    fprintf('Valore finale di Mutual Information: %.7g\n', optimal_value);
    
    fprintf('\nOttimizzazione CPSO completata.\n');
    
    T_final = create_transformation_matrix(optimal_params(1), optimal_params(2), optimal_params(3), optimal_params(4), optimal_params(5), optimal_params(6), optimal_params(7));
    
    fprintf('Determinante della matrice di rotazione: %.7g\n', det(T_final(1:3,1:3)));
    
    tform = affine3d(T_final);
    movingRegistered = imwarp(movingImage, tform, 'OutputView', imref3d(size(fixedImage)));

%     figure; sliceViewer(fixedImage); title('Immagine Fissa');
%     figure; sliceViewer(movingImage); title('Immagine Mobile');
%     figure; sliceViewer(movingRegistered); title('Immagine Registrata');
%     
    mi_value = mutual_information(fixedImage, movingRegistered);
    rmse_value = rmse_control_points(size(fixedImage), optimal_params, cb_ref);
    
    mi_values_all(i) = mi_value;
    rmse_values_all(i) = rmse_value;
    
    fprintf('Mutual Information tra l immagine fissa e quella registrata: %.7g\n', mi_value);
    fprintf('RMSE tra l immagine fissa e quella registrata: %.7g\n', rmse_value);
end

data_struct = struct('Metodo_CPSO', ...
    'lb', lb, ...
    'ub', ub, ...
    'particelle', particles, ...
    'sub_interval', sub_interval, ... 
    'dt', dt, ...
    'optimal_params_all', optimal_params_all, 'optimal_values_all', optimal_values_all, ...
    'execution_times_all', execution_times_all, 'convergence_all', {convergence_all}, ...
    'mi_values_all', mi_values_all, 'rmse_values_all', rmse_values_all);


json_text = jsonencode(data_struct);
fid = fopen('monte_carlo_results.json', 'w');
if fid == -1
    error('Impossibile aprire il file per la scrittura.');
end
fwrite(fid, json_text, 'char');
fclose(fid);

fprintf('\nFine codice\n\n');

function score = objective_function(params, fixedImage, movingImage, alpha, cb_ref)
    rmse_score = rmse_control_points(size(fixedImage), params, cb_ref);
    mi_val = mutual_information(fixedImage, movingImage);
    score = alpha * mi_val + (1 - alpha) * rmse_score;
end

function T_final = create_transformation_matrix(tx, ty, tz, theta_x, theta_y, theta_z, scale)
    Rz = [cos(theta_z), -sin(theta_z), 0; sin(theta_z), cos(theta_z), 0; 0, 0, 1];
    Ry = [cos(theta_y), 0, sin(theta_y); 0, 1, 0; -sin(theta_y), 0, cos(theta_y)];
    Rx = [1, 0, 0; 0, cos(theta_x), -sin(theta_x); 0, sin(theta_x), cos(theta_x)];
    R = Rz * Ry * Rx;
    S = scale * eye(3);
    T_final = eye(4);
    T_final(1:3,1:3) = R * S / norm(R * S, 'inf');
end

function mi_val = mutual_information(img1, img2)
    img1 = img1(:); img2 = img2(:);
    jointHist = histcounts2(img1, img2, 256, 'Normalization', 'probability');
    px = sum(jointHist, 2); py = sum(jointHist, 1);
    entropyX = entropy(px);
    entropyY = entropy(py);
    jointEntropy = -sum(jointHist(jointHist > 0) .* log2(jointHist(jointHist > 0)));
    mi_val = entropyX + entropyY - jointEntropy;
end

function e = rmse_control_points(fixedSize, params, cb_ref)
    T_final = create_transformation_matrix(params(1), params(2), params(3), params(4), params(5), params(6), params(7));
    tform = affine3d(T_final);
    cp_moving = transformPointsForward(tform, cb_ref);
    diff = cp_moving - cb_ref;
    e = sqrt(mean(sum(diff.^2, 2)));
end

%% Ultimo risultato ottenuto 

% Inizio codice...
% Caricamento immagini...
% Dimensioni immagine fissa: [320 320 100]
% Dimensioni immagine mobile: [320 320 100]
% Avvio ottimizzazione CPSO...
% Starting loop...
% -----------------------------------------------
% Iterazione 1
% Migliore posizione: 5.0000 0.8209 -5.0000 0.0121 -0.0228 0.0113 1.1000 
% Ottimo in questo momento: 8.4058
% 
% Iterazione 2
% Migliore posizione: 5.0000 0.8209 -5.0000 0.0121 -0.0228 0.0113 1.1000 
% Ottimo in questo momento: 8.4058
% 
% Iterazione 3
% Migliore posizione: 5.0000 0.8209 -5.0000 0.0121 -0.0228 0.0113 1.1000 
% Ottimo in questo momento: 8.4058
% 
% Iterazione 4
% Migliore posizione: 4.8499 0.8020 -4.8596 0.0007 0.0010 0.0012 1.0982 
% Ottimo in questo momento: -0.2637
% 
% Iterazione 5
% Migliore posizione: 4.8499 0.8020 -4.8596 0.0007 0.0010 0.0012 1.0982 
% Ottimo in questo momento: -0.2637
% 
% Iterazione 6
% Migliore posizione: 4.8499 0.7822 -4.8627 0.0001 -0.0003 -0.0003 1.0983 
% Ottimo in questo momento: -0.6245
% 
% Iterazione 7
% Migliore posizione: 4.8499 0.7822 -4.8627 0.0001 -0.0003 -0.0003 1.0983 
% Ottimo in questo momento: -0.6245
% 
% Iterazione 8
% Migliore posizione: 4.8499 0.7822 -4.8627 0.0001 -0.0003 -0.0003 1.0983 
% Ottimo in questo momento: -0.6245
% 
% Iterazione 9
% Migliore posizione: 4.8528 0.7841 -4.8622 -0.0002 -0.0001 -0.0000 1.0983 
% Ottimo in questo momento: -0.6990
% 
% Iterazione 10
% Migliore posizione: 4.8528 0.7841 -4.8622 -0.0002 -0.0001 -0.0000 1.0983 
% Ottimo in questo momento: -0.6990
% 
% Iterazione 11
% Migliore posizione: 4.8522 0.7853 -4.8642 0.0001 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7497
% 
% Iterazione 12
% Migliore posizione: 4.8523 0.7851 -4.8633 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7629
% 
% Iterazione 13
% Migliore posizione: 4.8520 0.7849 -4.8634 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7715
% 
% Iterazione 14
% Migliore posizione: 4.8520 0.7849 -4.8634 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7715
% 
% Iterazione 15
% Migliore posizione: 4.8520 0.7848 -4.8633 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7733
% 
% Iterazione 16
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7740
% 
% Iterazione 17
% Migliore posizione: 4.8523 0.7850 -4.8636 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7754
% 
% Iterazione 18
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7755
% 
% Iterazione 19
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7768
% 
% Iterazione 20
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7768
% 
% Iterazione 21
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7769
% 
% Iterazione 22
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7771
% 
% Iterazione 23
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7772
% 
% Iterazione 24
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 25
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 26
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 27
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 28
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 29
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 30
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 31
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 32
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 33
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 34
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 35
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 36
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 37
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 38
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 39
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 40
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 41
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 -0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 42
% Migliore posizione: 4.8522 0.7849 -4.8635 0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 43
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 44
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 45
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 46
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 47
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 48
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 49
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 50
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 51
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 52
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 53
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 54
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 55
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 56
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 57
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 58
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 59
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 60
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 61
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% Iterazione 62
% Migliore posizione: 4.8522 0.7849 -4.8635 -0.0000 -0.0000 0.0000 1.0983 
% Ottimo in questo momento: -0.7773
% 
% 
% Max stall iterations...
% 
% -----------------------------------------------
% Ending loop...
% 
% 
% 
% Parametri ottimali trovati:
% tx = 4.8522, ty = 0.7849, tz = -4.8635, theta_x = -0.0000, theta_y = -0.0000, theta_z = 0.0000, scale = 1.0983
% Valore finale di Mutual Information: -0.7773
% 
% Ottimizzazione CPSO completata.
% Determinante della matrice di rotazione: 1.0000
% Mutual Information tra l'immagine fissa e quella registrata: -3.8865
% RMSE tra l'immagine fissa e quella registrata: 0.0000
% 
% Fine codice


