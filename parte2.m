clc;
clear;
close all;

addpath(genpath('EMG-Feature-Extraction-Toolbox'));

% Leer archivo
archivo = 'EMG-data1.csv';
windowSize = 200;
numCanales = 8;

% Leer datos
data = readtable(archivo);

% Inicializar matrices
X = [];
Y = [];

% Extraer características por ventana
for clase = 1:7  % Clases útiles
    datosClase = data(data.class == clase, :);
    numVentanas = floor(height(datosClase) / windowSize);

    for v = 1:numVentanas
        inicio = (v-1)*windowSize + 1;
        fin = v*windowSize;

        featuresVentana = [];

        for canal = 1:numCanales
            canalNombre = ['channel', num2str(canal)];
            ventana = datosClase{inicio:fin, canalNombre};

            mav = jMeanAbsoluteValue(ventana, []);
            wl = jWaveformLength(ventana, []);
            rmsVal = rms(ventana);

            featuresVentana = [featuresVentana, mav, wl, rmsVal];
        end

        X = [X; featuresVentana];
        Y = [Y; clase];
    end
end

% Normalizar
X = normalize(X);

% División entrenamiento/prueba (70% / 30%)
cv = cvpartition(Y, 'HoldOut', 0.3);
Xtrain = X(training(cv), :);
Ytrain = Y(training(cv));
Xtest = X(test(cv), :);
Ytest = Y(test(cv));

% One-hot
Ytrain_onehot = full(ind2vec(Ytrain'));
Ytest_onehot = full(ind2vec(Ytest'));

% Crear y entrenar red
red = patternnet(20);
red.trainFcn = 'trainscg';
red = train(red, Xtrain', Ytrain_onehot);

% Predicción
Y_pred = vec2ind(red(Xtest'));

% Precisión
accuracy = sum(Y_pred' == Ytest) / length(Ytest);
fprintf('\nPrecisión en el conjunto de prueba: %.2f%%\n', accuracy * 100);

% Matriz de confusión
figure;
confusionchart(Ytest, Y_pred');
title('Matriz de Confusión - Conjunto de Prueba');

% Métricas por clase
cm = confusionmat(Ytest, Y_pred');
numClasses = size(cm, 1);
TP = diag(cm);
FN = sum(cm, 2) - TP;
FP = sum(cm, 1)' - TP;
TN = sum(cm(:)) - (TP + FP + FN);

Precision = TP ./ (TP + FP + eps);
Recall = TP ./ (TP + FN + eps);
F1 = 2 * (Precision .* Recall) ./ (Precision + Recall + eps);
TNR = TN ./ (TN + FP + eps);
MCC = (TP .* TN - FP .* FN) ./ sqrt((TP + FP) .* (TP + FN) .* (TN + FP) .* (TN + FN) + eps);

fprintf('\n=== Métricas por clase (evaluación en prueba) ===\n');
fprintf('Clase | Precision | Recall(TPR) | F1 Score | TNR (Spec) | MCC\n');
for i = 1:numClasses
    fprintf('  %d   |   %.4f   |   %.4f    |  %.4f  |   %.4f   | %.4f\n', i, Precision(i), Recall(i), F1(i), TNR(i), MCC(i));
end

fprintf('\nAccuracy total en prueba: %.4f\n', accuracy);

%% Red neuronal para asociar canales a músculos usando todas las características (MAV, WL, RMS por clase)

X_musculo = [];
for canal = 1:numCanales
    featuresCanal = [];
    for clase = 1:7
        datosClase = data(data.class == clase, :);
        numVentanas = floor(height(datosClase) / windowSize);
        temp_mav = 0; temp_wl = 0; temp_rms = 0;
        for v = 1:numVentanas
            inicio = (v-1)*windowSize + 1;
            fin = v*windowSize;
            ventana = datosClase{inicio:fin, ['channel', num2str(canal)]};
            temp_mav = temp_mav + jMeanAbsoluteValue(ventana, []);
            temp_wl = temp_wl + jWaveformLength(ventana, []);
            temp_rms = temp_rms + rms(ventana);
        end
        featuresCanal = [featuresCanal, temp_mav/numVentanas, temp_wl/numVentanas, temp_rms/numVentanas];
    end
    X_musculo = [X_musculo; featuresCanal];
end

X_musculo = normalize(X_musculo);

% Etiquetas estimadas: una por canal (8 canales)
Y_musculo = 1:8;  % Asignar una clase/músculo distinta a cada canal

% Lista de nombres de músculos estimados para cada canal
musculos_est = {
    'Musculo no identificado', 
    'Flexores de dedos (FDS/FDP)',              
    'Flexor carpi radialis',  
    'Extensor carpi radialis7ulnaris',  
    'Flexor/Extensor carpi radialis', 
    'Flexor/Extensor carpi ulnaris',      
    'Extensor digitorum' , 
    'Musculo no identificado', 
};

% Etiquetas one-hot
Y_musculo_onehot = full(ind2vec(Y_musculo));

% Entrenamiento red neuronal
red_musculo = patternnet(10);
red_musculo.trainFcn = 'trainscg';
red_musculo = train(red_musculo, X_musculo', Y_musculo_onehot);

% Predicción
Y_pred_musculo = vec2ind(red_musculo(X_musculo'));

% Mostrar resultados
fprintf('\n=== Asociación Canal ↔ Músculo usando etiquetas estimadas ===\n');
for i = 1:numCanales
    fprintf('Canal %d → %s (Predicho: %s)\n', i, musculos_est{i}, musculos_est{Y_pred_musculo(i)});
end

% Visualización
figure;
bar(X_musculo');
xlabel('Clase de Movimiento');
ylabel('Activación promedio normalizada (MAV, WL, RMS)');
xticks(1:21);
xticklabels(repelem({'MAV','WL','RMS'}, 7));
legend(arrayfun(@(x) ['Canal ', num2str(x)], 1:numCanales, 'UniformOutput', false), 'Location', 'eastoutside');
title('Activación promedio por clase y canal');
grid on;
