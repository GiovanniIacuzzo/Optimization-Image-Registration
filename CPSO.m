%% CPSO Function

function [bestPosition, bestValue, execution_time, convergence] = CPSO(objectiveFunction, dim, lb, ub, options)
    % Configura le opzioni predefinite
    defaultOptions = struct( ...
        'particles', 100, ...            % numero di particelle
        'sub_interval', 100, ...         % sottointervalli (max_iterations)
        'mu_max', 0.9, ...               % valore massimo di mu
        'mu_min', 0.4, ...               % valore minimo di mu
        'dt', 0.1, ...                   % passo di integrazione
        'interval', 10, ...              % intervalo di integrazione
        'Cognitive_constant', 2.05, ...  % costante cognitiva delle paarticelle
        'Social_constant', 2.05, ...     % costante sociale delle particelle
        'maxNoChange', 10 ...            % massimo numero di stalli per la convergenza
    );

    if iscell(options)
        options = parseOptions(defaultOptions, options);
    elseif isempty(options)
        options = defaultOptions;
    else
        if ~isstruct(options)
            error('Le opzioni devono essere una struttura o una cell array di coppie nome-valore.');
        end
        options = mergeOptions(defaultOptions, options);
    end

    % Estrai parametri
    particles = options.particles;
    sub_interval = options.sub_interval;
    mu_max = options.mu_max;
    mu_min = options.mu_min;
    dt = options.dt;
    interval = sub_interval * dt;
    Cognitive_constant = options.Cognitive_constant;
    Social_constant = options.Social_constant;
    maxNoChange = options.maxNoChange;

    % Imposta limiti di variabili e velocità
    if isscalar(lb)
        VarMin = repmat(lb, [1, dim]);
    else
        VarMin = lb;
    end

    if isscalar(ub)
        VarMax = repmat(ub, [1, dim]);
    else
        VarMax = ub;
    end
    VelMax = 0.1 * (VarMax - VarMin);
    VelMin = -VelMax;

    % Inizializza particelle
    particle = initializeParticles(particles, dim, VarMin, VarMax, objectiveFunction);
    GlobalBest = findGlobalBest(particle);

    % Preparazione per l'ottimizzazione
    BestCost = zeros(sub_interval, 1);
    noChangeCount = 0;

    fprintf("Starting loop...\n");
    fprintf("-----------------------------------------------\n");
    tic; % Avvia il timer

    % Loop principale
    for it = 1:sub_interval
        % Parametri dinamici
        r1 = rand();
        r2 = rand();
        omega = sqrt(Cognitive_constant * r1 + Social_constant * r2);
        mu = mu_max - (((mu_max - mu_min) / interval) * (it - 1) * dt);
        zeta = (1 - mu) / (2 * omega);

        % Aggiornamento delle particelle
        for i = 1:particles
            fk = (Cognitive_constant * particle(i).Best.Position * r1) + ...
                 (Social_constant * GlobalBest.Position * r2);
            fk_omega = fk / omega^2;

            % Aggiorna posizione e velocità usando i coefficienti
            [particle(i).Position, particle(i).Velocity] = updatePositionVelocity( ...
                particle(i), fk_omega, omega, zeta, dt, VarMin, VarMax, VelMin, VelMax);

            % Calcola il costo e aggiorna il migliore
            particle(i).Cost = objectiveFunction(particle(i).Position);
            if particle(i).Cost < particle(i).Best.Cost
                particle(i).Best = struct('Position', particle(i).Position, 'Cost', particle(i).Cost);
                if particle(i).Cost < GlobalBest.Cost
                    GlobalBest = particle(i).Best;
                    noChangeCount = 0;
                end
            end
        end

        % Aggiorna la convergenza
        BestCost(it) = GlobalBest.Cost;

        % Controlla interruzione
        if it > 1 && BestCost(it) == BestCost(it - 1)
            noChangeCount = noChangeCount + 1;
        else
            noChangeCount = 0;
        end
        if noChangeCount >= maxNoChange
            fprintf("\nMax stall iterations...\n");
            break;
        end
        fprintf("Iterazione %d\n", it);
        fprintf("Migliore posizione: ");
        fprintf("%.4f ", GlobalBest.Position);
        fprintf("\n");
        fprintf("Ottimo in questo momento: %.4f\n\n", GlobalBest.Cost);
    end
    % Risultati finali
    execution_time = toc;
    fprintf("\n-----------------------------------------------\n");
    fprintf("Ending loop...\n\n");
    bestPosition = GlobalBest.Position;
    bestValue = GlobalBest.Cost;
    convergence = BestCost(1:it);
end

function particle = initializeParticles(particles, dim, VarMin, VarMax, objectiveFunction)
    % Prealloca struttura array di particelle
    particle(particles) = struct('Position', [], 'Velocity', [], 'Cost', [], 'Best', []);

    % Genera posizioni casuali tra VarMin e VarMax (usando broadcasting)
    Positions = VarMin + (VarMax - VarMin) .* rand(particles, dim);

    % Calcola i costi in modo vettoriale
    Costs = arrayfun(@(i) objectiveFunction(Positions(i, :)), 1:particles);

    % Assegna i valori alle particelle
    for i = 1:particles
        particle(i).Position = Positions(i, :);
        particle(i).Velocity = zeros(1, dim);
        particle(i).Cost = Costs(i);
        particle(i).Best = struct('Position', Positions(i, :), 'Cost', Costs(i));
    end
end



function GlobalBest = findGlobalBest(particle)
    [~, bestIdx] = min([particle.Cost]);
    GlobalBest = particle(bestIdx).Best;
end

function [newPosition, newVelocity] = updatePositionVelocity(p, fk_omega, omega, zeta, dt, VarMin, VarMax, VelMin, VelMax)
    lambda1 = -omega * (zeta + sqrt(zeta^2 - 1));
    lambda2 = -omega * (zeta - sqrt(zeta^2 - 1));
    t = dt;

    if isequal(lambda1, lambda2)
        lambda = lambda1;
        c1k = ((p.Position - fk_omega) * (1 + lambda * t) - p.Velocity * t);
        c2k = p.Velocity - (p.Position - fk_omega) * lambda;
        newPosition = (c1k + c2k * t) * exp(lambda * t) + fk_omega;
        newVelocity = c2k * exp(lambda * t) + (c1k + c2k * t) * exp(lambda * t) * lambda;
    else
        c1k = ((p.Position - fk_omega) * lambda2 - p.Velocity) / (lambda2 - lambda1);
        c2k = (p.Velocity - (p.Position - fk_omega) * lambda1) / (lambda2 - lambda1);
        newPosition = c1k * exp(lambda1 * t) + c2k * exp(lambda2 * t) + fk_omega;
        newVelocity = c1k * exp(lambda1 * t) * lambda1 + c2k * exp(lambda2 * t) * lambda2;
    end

    % Limita posizione e velocità
    newPosition = max(min(newPosition, VarMax), VarMin);
    newVelocity = max(min(newVelocity, VelMax), VelMin);
end

function options = parseOptions(defaultOptions, optionCell)
    if mod(length(optionCell), 2) ~= 0
        error('Le opzioni devono essere specificate come coppie di nome-valore.');
    end

    % Converte la cell array in una struttura
    optionStruct = struct(optionCell{:});

    % Unisce le opzioni con i valori predefiniti
    options = mergeOptions(defaultOptions, optionStruct);
end

function options = mergeOptions(defaultOptions, customOptions)
    % Sovrascrive i valori predefiniti con quelli personalizzati
    options = defaultOptions;
    fields = fieldnames(customOptions);
    for i = 1:length(fields)
        options.(fields{i}) = customOptions.(fields{i});
    end
end
