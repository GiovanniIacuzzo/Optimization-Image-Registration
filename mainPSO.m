close all
clear
clc

fprintf("Inizio codice...\n");

% Caricamento delle immagini MRI 3D
fprintf("Caricamento immagini...\n");
fixedImageStruct = nii_tool('load', 'Task02_Heart/imagesTr/la_019.nii.gz');
movingImageStruct = nii_tool('load', 'Task02_Heart/labelsTr/la_019.nii.gz');

% Conversione in double
fixedImage = double(fixedImageStruct.img);
movingImage = double(movingImageStruct.img);

fixedImage = imgaussfilt3(fixedImage, 1);
movingImage = imgaussfilt3(movingImage, 1);

% Controllo dimensioni
fprintf("Dimensioni immagine fissa: [%d %d %d]\n", size(fixedImage));
fprintf("Dimensioni immagine mobile: [%d %d %d]\n", size(movingImage));

if any(size(fixedImage) ~= size(movingImage))
    error('Le dimensioni delle immagini fissa e mobile non corrispondono!');
end

% Definizione punti di controllo di riferimento
cb_ref = [floor(size(fixedImage,1)/5), floor(size(fixedImage,2)/5), floor(size(fixedImage,3)/5);
          floor(size(fixedImage,1)/5), floor(size(fixedImage,2)/5*4), floor(size(fixedImage,3)/5*4);
          floor(size(fixedImage,1)/5*4), floor(size(fixedImage,2)/5), floor(size(fixedImage,3)/5);
          floor(size(fixedImage,1)/5*4), floor(size(fixedImage,2)/5*4), floor(size(fixedImage,3)/5*4)];

% Definizione dei limiti per i parametri di trasformazione
lb = [-5, -5, -5, -pi/2, -pi/2, -pi/2, 0.9];  
ub = [5, 5, 5, pi/2, pi/2, pi/2, 1.1];

alpha = 0.2; % Valore all'interno dell'intervallo [0, 1] per pesare l'errore

% Funzione obiettivo
objective = @(params) objective_function(params, fixedImage, movingImage, alpha, cb_ref);

% Opzioni per il CPSO
options =  optimoptions("particleswarm", "Display","iter","MaxStallIterations",3,SwarmSize=200,MaxIterations=300,SocialAdjustmentWeight=3.05,SelfAdjustmentWeight=2.05);

fprintf("Avvio ottimizzazione PSO...\n");

% Esegui l'ottimizzazione
[optimal_params, optimal_value, execution_time] = particleswarm(objective, 7, lb, ub, options);

fprintf('\n\nParametri ottimali trovati:\n');
fprintf('tx = %.4f, ty = %.4f, tz = %.4f, theta_x = %.4f, theta_y = %.4f, theta_z = %.4f, scale = %.4f\n', optimal_params);
fprintf('Valore finale di Mutual Information: %.4f\n', optimal_value);

fprintf("\nOttimizzazione PSO completata.\n");

% Creazione della matrice di trasformazione ottimale
T_final = create_transformation_matrix(optimal_params(1), optimal_params(2), optimal_params(3), optimal_params(4), optimal_params(5), optimal_params(6), optimal_params(7));

% Verifica del determinante della matrice di rotazione
fprintf("Determinante della matrice di rotazione: %.4f\n", det(T_final(1:3,1:3)));

tform = affine3d(T_final);
movingRegistered = imwarp(movingImage, tform, 'OutputView', imref3d(size(fixedImage)));

% Visualizzazione
figure; sliceViewer(fixedImage); title('Immagine Fissa');
figure; sliceViewer(movingImage); title('Immagine Mobile');
figure; sliceViewer(movingRegistered); title('Immagine Registrata');

% Calcolo della Mutual Information
mi_value = mutual_information(fixedImage, movingRegistered);
fprintf('Mutual Information tra l\''immagine fissa e quella registrata: %.4f\n', mi_value);

% Calcolo del RMSE
rmse_value = rmse_control_points(size(fixedImage), optimal_params, cb_ref);
fprintf('RMSE tra l\''immagine fissa e quella registrata: %.4f\n', rmse_value);

fprintf('\nFine codice\n\n');

%% Funzioni ausiliarie

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

%%

% Parametri ottimali trovati:
% tx = 2.2445, ty = 5.0000, tz = -5.0000, theta_x = -0.0719, theta_y = 0.0008, theta_z = 0.2059, scale = 1.1000
% Valore finale di Mutual Information: 59.3230
% 
% Ottimizzazione PSO completata.
% Determinante della matrice di rotazione: 0.5104
% Mutual Information tra l'immagine fissa e quella registrata: -3.9042
% RMSE tra l'immagine fissa e quella registrata: 75.1254
