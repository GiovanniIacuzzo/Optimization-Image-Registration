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
    'maxNoChange', 3 ...
};

monte_carlo_run = 10;

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

    mi_value = mutual_information(fixedImage, movingRegistered);
    rmse_value = rmse_control_points(size(fixedImage), optimal_params, cb_ref);
    
    mi_values_all(i) = mi_value;
    rmse_values_all(i) = rmse_value;
    
    fprintf('Mutual Information tra l immagine fissa e quella registrata: %.7g\n', mi_value);
    fprintf('RMSE tra l immagine fissa e quella registrata: %.7g\n', rmse_value);
end

data_struct = struct('lb', lb, ...
    'ub', ub, ...
    'particelle', particles, ...
    'sub_interval', sub_interval, ... 
    'dt', dt, ...
    'optimal_params_all', optimal_params_all, 'optimal_values_all', optimal_values_all, ...
    'execution_times_all', execution_times_all, 'convergence_all', {convergence_all}, ...
    'mi_values_all', mi_values_all, 'rmse_values_all', rmse_values_all);


json_text = jsonencode(data_struct);
fid = fopen('monte_carlo_results_cpso.json', 'w');
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
