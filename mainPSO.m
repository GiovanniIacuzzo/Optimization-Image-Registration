close all
clear
clc

fprintf("Inizio codice...\n");

% Caricamento delle immagini MRI 3D
fprintf("Caricamento immagini...\n");
fixedImageStruct = nii_tool('load', 'Task02_Heart/imagesTr/la_007.nii.gz');
movingImageStruct = nii_tool('load', 'Task02_Heart/labelsTr/la_007.nii.gz');

% Conversione in double
fixedImage = double(fixedImageStruct.img);
movingImage = double(movingImageStruct.img);

% Controllo dimensioni
fprintf("Dimensioni immagine fissa: [%d %d %d]\n", size(fixedImage));
fprintf("Dimensioni immagine mobile: [%d %d %d]\n", size(movingImage));

if any(size(fixedImage) ~= size(movingImage))
    error('Le dimensioni delle immagini fissa e mobile non corrispondono!');
end

% Definizione dei limiti per i parametri di trasformazione
lb = [-5, -5, -5, -pi/4, -pi/4, -pi/4, 0.9];  
ub = [5, 5, 5, pi/4, pi/4, pi/4, 1.1];

% Funzione obiettivo
objective = @(params) objective_function(params, fixedImage, movingImage);

% Opzioni per il PSO
options = optimoptions('particleswarm', ...
    'MaxStallIterations', 6, ...
    'SwarmSize', 100, ...
    'MaxIterations', 100, ...
    'Display', 'iter', ...
    'FunctionTolerance', 1e-6);

fprintf("Avvio ottimizzazione PSO...\n");

% Esegui l'ottimizzazione
[optimal_params, optimal_value] = particleswarm(objective, 7, lb, ub, options);

fprintf('Parametri ottimali trovati:\n');
fprintf('tx = %.4f, ty = %.4f, tz = %.4f, theta_x = %.4f, theta_y = %.4f, theta_z = %.4f, scale = %.4f\n', ...
    optimal_params(1), optimal_params(2), optimal_params(3), optimal_params(4), ...
    optimal_params(5), optimal_params(6), optimal_params(7));

fprintf('Valore finale di Mutual Information: %.4f\n', optimal_value);

fprintf("\nOttimizzazione PSO completata.\n");

% Creazione della matrice di trasformazione ottimale
T_final = create_transformation_matrix(optimal_params(1), optimal_params(2), optimal_params(3), ...
                                       optimal_params(4), optimal_params(5), optimal_params(6), ...
                                       optimal_params(7));

% Verifica del determinante della matrice di rotazione
fprintf("Determinante della matrice di rotazione: %.4f\n", det(T_final(1:3,1:3)));

% Creazione della trasformazione affine
tform = affine3d(T_final);

% Applicazione della trasformazione
movingRegistered = imwarp(movingImage, tform, 'OutputView', imref3d(size(fixedImage)));

% Visualizzazione delle immagini registrate
figure; sliceViewer(fixedImage); title('Immagine Fissa');
figure; sliceViewer(movingImage); title('Immagine Mobile');
figure; sliceViewer(movingRegistered); title('Immagine Registrata');

% Calcolo della Mutual Information
mi_value = mutual_information(fixedImage, movingRegistered);
fprintf('Mutual Information tra l''immagine fissa e quella registrata: %.4f\n', mi_value);

% Calcolo del RMSE
rmse_value = rmse(fixedImage, movingRegistered);
fprintf('RMSE tra l''immagine fissa e quella registrata: %.4f\n', rmse_value);

fprintf('\nFine codice\n\n');

%% FUNZIONI AUSILIARIE

function score = objective_function(params, fixedImage, movingImage)
    % Estrazione parametri
    tx = params(1); ty = params(2); tz = params(3);
    theta_x = params(4); theta_y = params(5); theta_z = params(6);
    scale = params(7);

    % Creazione della matrice di trasformazione
    T_final = create_transformation_matrix(tx, ty, tz, theta_x, theta_y, theta_z, scale);
    
    % Creazione della trasformazione affine
    tform = affine3d(T_final);

    movingRegistered = imwarp(movingImage, tform, 'OutputView', imref3d(size(fixedImage)));


    % Calcolo della NCC
    cropSize = round(size(fixedImage) * 0.5);
    fixedCropped = fixedImage(1:cropSize(1), 1:cropSize(2), 1:cropSize(3));
    movingCropped = movingRegistered(1:cropSize(1), 1:cropSize(2), 1:cropSize(3));
    
    ncc_value = normxcorr3(fixedCropped, movingCropped);
    ncc_score = max(ncc_value(:));

    % Calcolo del RMSE
    rmse_score = sqrt(mean((fixedImage(:) - movingRegistered(:)).^2));

    % Funzione obiettivo: NCC alto, RMSE basso
    score = -ncc_score + rmse_score;
end

function T_final = create_transformation_matrix(tx, ty, tz, theta_x, theta_y, theta_z, scale)
    % Matrici di rotazione
    Rz = [
        cos(theta_z), -sin(theta_z), 0;
        sin(theta_z),  cos(theta_z), 0;
        0, 0, 1
    ];

    Ry = [
        cos(theta_y), 0, sin(theta_y);
        0, 1, 0;
        -sin(theta_y), 0, cos(theta_y)
    ];

    Rx = [
        1, 0, 0;
        0, cos(theta_x), -sin(theta_x);
        0, sin(theta_x), cos(theta_x)
    ];

    % Matrice di rotazione combinata
    R = Rz * Ry * Rx;

    % Matrice di scaling UNIFORME (evita distorsioni)
    S = scale * eye(3); 

    % Matrice di trasformazione 4x4
    T_final = eye(4);

    % Assicura che la matrice sia SOLO rotazione e scaling uniforme
    T_final(1:3,1:3) = R * S / det(R * S)^(1/3);

    % Inserisci traslazione
    T_final(1:3, 4) = [tx; ty; tz];
    T_final(1:3, 4) = 0;
    

    % Assicura che l'ultima riga sia [0 0 0 1]
    T_final(4,:) = [0, 0, 0, 1];
end


function mi_val = mutual_information(img1, img2)
    % Calcolo istogramma congiunto
    jointHist = histcounts2(img1(:), img2(:), 256);
    jointProb = jointHist / sum(jointHist(:));

    % Probabilità marginali
    px = sum(jointProb, 2);
    py = sum(jointProb, 1);

    % Entropia
    entropyX = -sum(px .* log2(px + eps));
    entropyY = -sum(py .* log2(py + eps));
    jointEntropy = -sum(jointProb(:) .* log2(jointProb(:) + eps));

    % Mutual Information
    mi_val = entropyX + entropyY - jointEntropy;
end

function rmse_val = rmse(img1, img2)
    diff = img1 - img2;
    rmse_val = sqrt(mean(diff(:).^2));
end
