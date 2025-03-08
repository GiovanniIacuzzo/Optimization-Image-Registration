# 3D MRI Image Registration

## Introduzione

Questo progetto riguarda la registrazione di immagini MRI 3D tramite ottimizzazione dei parametri di trasformazione con **Particle Swarm Optimization (PSO)** e **Continuous Particle Swarm Optimization (CPSO)**. Il processo include il calcolo della **Mutual Information (MI)** e del **Root Mean Squared Error (RMSE)** per valutare la qualità della registrazione.

---

## Descrizione

Il codice:
- Carica due immagini MRI in formato **NIfTI (.nii.gz)** (una fissa e una mobile).
- Le converte in formato numerico e applica un **filtro gaussiano**.
- Utilizza **PSO** e **CPSO** per ottimizzare una **trasformazione affine**.
- Calcola e visualizza i risultati di **Mutual Information** e **RMSE**.

---

## Requisiti

- **MATLAB** (versione 2020 o successiva).
- **Image Processing Toolbox**.
- **NIfTI Toolbox** per MATLAB ([link](https://www.mathworks.com/matlabcentral/fileexchange/2887-nifti-toolbox)).
- **CPSO** (implementato nel codice).

---

## File Principali

### 📌 `mainCPSO.m`
Esegue la registrazione utilizzando **CPSO** con:
- Caricamento e pre-processing delle immagini.
- Ottimizzazione dei parametri di trasformazione.
- Calcolo di **Mutual Information** e **RMSE**.

### 📌 `mainPSO.m`
Simile a `mainCPSO.m`, ma utilizza **PSO** invece di **CPSO**.

### 📌 Funzioni ausiliarie
- **`objective_function.m`** → Funzione obiettivo per l'ottimizzazione.
- **`create_transformation_matrix.m`** → Costruisce la matrice di trasformazione affine.
- **`mutual_information.m`** → Calcola la **Mutual Information**.
- **`rmse_control_points.m`** → Calcola **RMSE** usando punti di controllo.
- **`rmse.m`** → Calcola **RMSE** tra le immagini.

---

## 🚀 Come Usare

1. **Configurazione dell'Ambiente**
   - Installare **MATLAB** e i toolbox richiesti.
   - Aggiungere il toolbox **NIfTI** alla cartella di lavoro.

2. **Caricamento delle Immagini**
   - Modificare i percorsi delle immagini nei file `.m`:
     ```matlab
     fixedImageStruct = nii_tool('load', 'Task02_Heart/imagesTr/la_019.nii.gz');
     movingImageStruct = nii_tool('load', 'Task02_Heart/labelsTr/la_019.nii.gz');
     ```

3. **Esecuzione dello Script**
   - Eseguire `mainCPSO.m` o `mainPSO.m` in MATLAB:
     ```matlab
     run('mainCPSO.m');
     ```

4. **Visualizzazione dei Risultati**
   - MATLAB mostrerà le immagini fisse, mobili e registrate.
   - Verranno stampati i valori ottimizzati e le metriche di qualità.

---

## 📊 Analisi dei Risultati

Esempi di output delle ottimizzazioni:

### 🔹 **PSO**
- **Mutual Information:** `59.3230`
- **RMSE:** `75.1254`
- **Determinante Matrice Rotazione:** `0.5104`

### 🔹 **CPSO**
- **Mutual Information:** `-0.7756`
- **RMSE:** `0.0022`
- **Determinante Matrice Rotazione:** `1.0000`

---

## 📈 Visualizzazione Dati

Il file `monte_carlo_results_cpso.json` viene generato per analisi successive.

Per visualizzare i risultati in MATLAB:
```matlab
jsonData = fileread('monte_carlo_results_cpso.json');
data = jsondecode(jsonData);
```

### 🔹 **Grafico della Convergenza**
```matlab
figure;
for i = 1:length(data.execution_times_all)
    plot(data.convergence_all{i}, 'LineWidth', 1.5);
end
xlabel('Iterazioni'); ylabel('Funzione Obiettivo');
title('Convergenza della Funzione Obiettivo');
grid on;
```

### 🔹 **Distribuzione dei Parametri Ottimali**
```matlab
figure;
boxplot(data.optimal_params_all, 'Labels', {'tx', 'ty', 'tz', 'θx', 'θy', 'θz', 'scale'});
title('Distribuzione dei Parametri Ottimali');
grid on;
```

---

## 📌 Conclusione

Il progetto confronta PSO e CPSO per la registrazione di immagini MRI 3D, mostrando i vantaggi dell'ottimizzazione continua sui parametri di trasformazione affine. 

---

### 📩 Contatti
Per domande o suggerimenti, contattare: [iacuzzogiovanni@gmail.com](mailto:iacuzzogiovanni@gmail.com)

