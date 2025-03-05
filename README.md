# 3D MRI image registration

Questo progetto si concentra su 3D image registration tramite l'ottimizzazione dei parametri di trasformazione, utilizzando il Particle Swarm Optimization (PSO) e CPSO (Continuous Particle Swarm Optimization). Le immagini MRI 3D vengono registrate (allineate) con l'ausilio di algoritmi di ottimizzazione e calcolo della **Mutual Information** e **RMSE**.

## Descrizione

Il codice carica due immagini MRI (una "fissa" e una "mobile") in formato NIfTI (`.nii.gz`), le converte in formato numerico, le pre-elabora applicando un filtro gaussiano, e poi applica una trasformazione affine per registrare l'immagine mobile sull'immagine fissa. L'ottimizzazione avviene mediante **PSO** e **CPSO**. Dopo l'ottimizzazione, le immagini vengono visualizzate e viene calcolata la **Mutual Information** e il **Root Mean Squared Error (RMSE)** per verificare la qualità della registrazione.

## Requisiti

- MATLAB (versione 2020 o successiva)
- **Image Processing Toolbox** per la gestione delle immagini.
- **NIfTI Toolbox** per il caricamento e la gestione dei file NIfTI (è necessario scaricare il toolbox NIfTI per MATLAB).
- **CPSO**.

## File Principali

### 1. **mainCPSO.m**
Questo script applica la registrazione delle immagini 3D utilizzando CPSO. Le immagini vengono caricate, pre-processate e successivamente ottimizzate con un algoritmo CPSO.

### 2. **mainPSO.m**
Questo script esegue una registrazione delle immagini utilizzando PSO (Particle Swarm Optimization) e applica la stessa metodologia di trasformazione affine, ma con un diverso algoritmo di ottimizzazione rispetto al CPSO.

### 3. **Funzioni ausiliarie**
Le seguenti funzioni ausiliarie sono utilizzate all'interno degli script principali:

- `objective_function`: Calcola la funzione obiettivo che combina **Mutual Information** e **RMSE** tra le immagini fissa e mobile.
- `create_transformation_matrix`: Crea una matrice di trasformazione affine basata sui parametri ottimizzati.
- `mutual_information`: Calcola la **Mutual Information** tra due immagini.
- `rmse_control_points`: Calcola l'**RMSE** utilizzando i punti di controllo definiti.
- `rmse`: Calcola l'**RMSE** tra due immagini.

## Come Usare

1. **Preparazione dell'ambiente**:
   - Assicurati di avere **MATLAB** installato.
   - Installa la **Image Processing Toolbox**.
   - Scarica e aggiungi alla tua cartella di lavoro il toolbox **NIfTI** per MATLAB.
   
2. **Caricamento delle Immagini**:
   - Sostituisci i percorsi delle immagini NIfTI (file `.nii.gz`) all'interno degli script:
     ```matlab
     fixedImageStruct = nii_tool('load', 'Task02_Heart/imagesTr/la_019.nii.gz');
     movingImageStruct = nii_tool('load', 'Task02_Heart/labelsTr/la_019.nii.gz');
     ```

3. **Esecuzione dello Script**:
   - Esegui uno degli script nel tuo ambiente MATLAB (es. `RegistrazioneMRI_CPSO.m` o `RegistrazioneMRI_PSO.m`).
   - Lo script avvierà il processo di registrazione delle immagini e l'ottimizzazione.
   
4. **Visualizzazione dei Risultati**:
   - Dopo che il processo di ottimizzazione è completato, le immagini saranno visualizzate:
     - **Immagine fissa**
     - **Immagine mobile**
     - **Immagine registrata**

5. **Output**:
   - I parametri ottimali della trasformazione affine saranno stampati sulla console.
   - Il valore della **Mutual Information** e dell'**RMSE** tra l'immagine fissa e quella registrata sarà calcolato e mostrato.

## Dipendenze

- **NIfTI Toolbox** (necessario per caricare i file `.nii.gz`)
  - [NIfTI Toolbox](https://www.mathworks.com/matlabcentral/fileexchange/2887-nifti-toolbox)

## Esempio di Output

Quando esegui uno degli script, vedrai in console i parametri ottimali trovati, ad esempio:

