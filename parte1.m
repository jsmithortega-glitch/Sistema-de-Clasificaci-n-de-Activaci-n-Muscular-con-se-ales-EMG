clc;
clear;
close all;

addpath(genpath('EMG-Feature-Extraction-Toolbox'));

% Leer el archivo Excel
data = readtable('EMG-data1.csv');

% Nombres de los canales
canales = {'channel1','channel2','channel3','channel4',...
           'channel5','channel6','channel7','channel8'};

% Diccionario de clases (para usar en los títulos)
nombresClases = {
    '0: sin marcar'
    '1: mano en reposo'
    '2: puño'
    '3: flexión de muñeca'
    '4: extensión de muñeca'
    '5: desviación radial'
    '6: desviación cubital'
    '7: palma extendida'
};

% Recorrer las clases del 1 al 7
for clase = 1:7
    % Filtrar los datos por clase
    idx = data.class == clase;
    datosClase = data(idx, :);
    
    % Crear figura nueva para esta clase
    figure;
    hold on;

    % Graficar cada canal EMG
    for i = 1:length(canales)
        plot(datosClase.time, datosClase{:, canales{i}}, 'DisplayName', canales{i});
    end

    title(['Señales EMG - Clase ', nombresClases{clase + 1}]);  % +1 porque clase 1 es índice 2
    xlabel('Tiempo (s)');
    ylabel('Amplitud de señal EMG');
    legend('show');
    grid on;
end

%%
% Tamaño de ventana en muestras (por ejemplo, 200 ms si sampling rate = 1000 Hz)
windowSize = 200;

% Nombres de los canales
canales = {'channel1','channel2','channel3','channel4',...
           'channel5','channel6','channel7','channel8'};

% Diccionario de clases
nombresClases = {
    '0: sin marcar'
    '1: mano en reposo'
    '2: puño'
    '3: flexión de muñeca'
    '4: extensión de muñeca'
    '5: desviación radial'
    '6: desviación cubital'
    '7: palma extendida'
};

% Recorrer las clases del 1 al 7
for clase = 1:7
    % Filtrar los datos por clase
    idx = data.class == clase;
    datosClase = data(idx, :);

    % Elegir ventana representativa: desde el inicio
    if height(datosClase) >= windowSize
        ventana = datosClase(1:windowSize, :);  % Puedes cambiar esto para tomar del medio, etc.
    else
        ventana = datosClase;  % Si tiene menos datos, usa todo
    end

    % Crear figura para esta clase
    figure;
    hold on;
    
    for i = 1:length(canales)
        plot(ventana.time, ventana{:, canales{i}}, 'DisplayName', canales{i});
    end

    title(['Clase ', nombresClases{clase + 1}, ' (ventana de ', num2str(windowSize), ' muestras)']);
    xlabel('Tiempo (s)');
    ylabel('Amplitud de señal EMG');
    legend('show');
    grid on;
end

%%
% Definir parámetros
windowSize = 200;  % muestras por ventana
canalElegido = 'channel2';  % cambiar si quieres comparar otro canal

% Diccionario de clases
nombresClases = {
    '0: sin marcar'
    '1: mano en reposo'
    '2: puño'
    '3: flexión de muñeca'
    '4: extensión de muñeca'
    '5: desviación radial'
    '6: desviación cubital'
    '7: palma extendida'
};

% Crear figura para comparación
figure;
hold on;

for clase = 1:7  % Omitimos clase 0
    % Filtrar datos de la clase
    idx = data.class == clase;
    datosClase = data(idx, :);

    % Obtener una ventana
    if height(datosClase) >= windowSize
        ventana = datosClase(1:windowSize, :);
    else
        ventana = datosClase;
    end

    % Graficar canal seleccionado
    plot(ventana.time, ventana{:, canalElegido}, 'DisplayName', nombresClases{clase + 1});
end

title(['Comparación de "', canalElegido, '" entre diferentes movimientos']);
xlabel('Tiempo (s)');
ylabel('Amplitud de señal EMG');
legend('show');
grid on;

%%

% Parámetros
numClases = 8;  % de 0 a 7
numCanales = 8;  % channel1 a channel8
metrica = 'RMS';  % Cambia a 'Media' si prefieres media absoluta

% Inicializar matriz de resultados
activaciones = zeros(numClases, numCanales);

% Calcular activación por clase y canal
for clase = 0:7
    % Filtrar filas de esa clase
    datosClase = data(data.class == clase, :);

    for canal = 1:numCanales
        canalNombre = ['channel', num2str(canal)];
        senal = datosClase{:, canalNombre};

        switch metrica
            case 'RMS'
                activacion = rms(senal);  % raíz cuadrada del promedio cuadrado
            case 'Media'
                activacion = mean(abs(senal));  % valor absoluto medio
        end

        activaciones(clase + 1, canal) = activacion;
    end
end

% Nombres para graficar
nombresClases = {
    '0: sin marcar', '1: reposo', '2: puño', '3: flexión',
    '4: extensión', '5: radial', '6: cubital', '7: palma'
};
nombresCanales = strcat('Canal ', string(1:8));

% Visualización: Heatmap
figure;
imagesc(activaciones);
colormap hot;
colorbar;
xlabel('Canales EMG');
ylabel('Clases / Movimientos');
title(['Activación EMG por Clase y Canal - ', metrica]);
set(gca, 'XTick', 1:8, 'XTickLabel', nombresCanales);
set(gca, 'YTick', 1:8, 'YTickLabel', nombresClases);


%% 
% Extracción de caracteristicas 
% Extracción de MAV (Mean Absolute Value) por ventanas y canales

% Leer el archivo CSV
data = readtable('EMG-data1.csv');

windowSize = 200;  % tamaño de la ventana en muestras
numCanales = 8;    % canales EMG
numClases = 8;     % clases de 0 a 7

% Inicializar matriz para guardar promedios de MAV por clase y canal
mavPorClaseYCanal = zeros(numClases, numCanales);

for clase = 0:7
    % Filtrar datos de la clase
    datosClase = data(data.class == clase, :);

    % Dividir en ventanas
    numVentanas = floor(height(datosClase) / windowSize);

    for canal = 1:numCanales
        nombreCanal = ['channel', num2str(canal)];
        valoresMAV = [];

        for v = 1:numVentanas
            % Extraer ventana
            inicio = (v-1)*windowSize + 1;
            fin = v*windowSize;
            ventana = datosClase{inicio:fin, nombreCanal};

            % Calcular MAV usando el toolbox
            mav = jMeanAbsoluteValue(ventana, []);
            valoresMAV = [valoresMAV; mav];
        end

        % Guardar promedio de MAV por canal en esta clase
        if ~isempty(valoresMAV)
            mavPorClaseYCanal(clase+1, canal) = mean(valoresMAV);
        end
    end
end

% Visualización: Heatmap
nombresClases = {
    '0: sin marcar', '1: reposo', '2: puño', '3: flexión',
    '4: extensión', '5: radial', '6: cubital', '7: palma'
};
nombresCanales = strcat('Canal ', string(1:8));

figure;
imagesc(mavPorClaseYCanal);
colormap hot;
colorbar;
xlabel('Canales EMG');
ylabel('Clases / Movimientos');
title('MAV promedio por Clase y Canal');
set(gca, 'XTick', 1:8, 'XTickLabel', nombresCanales);
set(gca, 'YTick', 1:8, 'YTickLabel', nombresClases);

metrica = 'RMS';  % Cambia a 'Media' si prefieres usar el valor absoluto medio

% Inicializar matriz de resultados
activaciones = zeros(numClases, numCanales);

% Calcular activación por clase y canal
for clase = 0:7
    datosClase = data(data.class == clase, :);
    for canal = 1:numCanales
        canalNombre = ['channel', num2str(canal)];
        senal = datosClase{:, canalNombre};

        switch metrica
            case 'RMS'
                activacion = rms(senal);
            case 'Media'
                activacion = mean(abs(senal));
        end

        activaciones(clase + 1, canal) = activacion;
    end
end

% Nombres de clases y canales
nombresClases = {
    '0: sin marcar', '1: reposo', '2: puño', '3: flexión',
    '4: extensión', '5: radial', '6: cubital', '7: palma'
};
nombresCanales = strcat('Canal ', string(1:8));

% Mostrar activaciones por clase y canal
fprintf('\n--- Activación EMG por Clase y Canal (usando %s) ---\n\n', metrica);

% Encabezado
fprintf('%-18s', 'Clase/Movimiento');
for c = 1:numCanales
    fprintf('%12s', nombresCanales{c});
end
fprintf('\n');

% Contenido
for clase = 0:7
    fprintf('%-18s', nombresClases{clase + 1});
    for canal = 1:numCanales
        fprintf('%12.5f', activaciones(clase + 1, canal));
    end
    fprintf('\n');
end

% --- Canal más activo y músculo probable por clase (solo clases 2 a 7) ---
[maxActivacion, canalMasActivo] = max(activaciones, [], 2);

fprintf('\n--- Canal más activo y posible músculo por clase ---\n');
for clase = 2:7
    canal = canalMasActivo(clase + 1);  % +1 porque la fila 1 es clase 0
    switch clase
        case 2
            musculo = 'Flexores de dedos (FDS/FDP)';
        case 3
            musculo = 'Flexor carpi radialis';
        case 4
            musculo = 'Extensor carpi radialis/ulnaris';
        case 5
            musculo = 'Flexor/Extensor carpi radialis';
        case 6
            musculo = 'Flexor/Extensor carpi ulnaris';
        case 7
            musculo = 'Extensor digitorum';
    end
    fprintf('Clase %d (%s): Canal %d → %s\n', clase, nombresClases{clase + 1}, canal, musculo);
end

%% Extracción de Waveform Length (WL) por ventanas y canales

% Inicializar matriz para guardar WL promedio por clase y canal
wlPorClaseYCanal = zeros(numClases, numCanales);

for clase = 0:7
    datosClase = data(data.class == clase, :);
    numVentanas = floor(height(datosClase) / windowSize);

    for canal = 1:numCanales
        nombreCanal = ['channel', num2str(canal)];
        valoresWL = [];

        for v = 1:numVentanas
            inicio = (v-1)*windowSize + 1;
            fin = v*windowSize;
            ventana = datosClase{inicio:fin, nombreCanal};

            % Calcular Waveform Length usando el toolbox
            wl = jWaveformLength(ventana, []);
            valoresWL = [valoresWL; wl];
        end

        % Guardar promedio por canal en esta clase
        if ~isempty(valoresWL)
            wlPorClaseYCanal(clase+1, canal) = mean(valoresWL);
        end
    end
end

% Visualización: Heatmap
figure;
imagesc(wlPorClaseYCanal);
colormap hot;
colorbar;
xlabel('Canales EMG');
ylabel('Clases / Movimientos');
title('Waveform Length promedio por Clase y Canal');
set(gca, 'XTick', 1:8, 'XTickLabel', nombresCanales);
set(gca, 'YTick', 1:8, 'YTickLabel', nombresClases);


[maxVal, idx] = max(wlPorClaseYCanal(:));  
[row, col] = ind2sub(size(wlPorClaseYCanal), idx);
fprintf('Clase con mayor WL: %s, Canal: %s, Valor: %.4f\n', ...
    nombresClases{row}, nombresCanales{col}, maxVal);

[maxVals, canal_maximos] = max(wlPorClaseYCanal, [], 2);
for i = 1:length(canal_maximos)
    fprintf('Clase %s: Canal más activo = %s (WL = %.4f)\n', ...
        nombresClases{i}, nombresCanales{canal_maximos(i)}, maxVals(i));
end

%% --- Sistema experto para clasificación de músculos basado en activación EMG ---

% nombres de clases (por claridad)
nombresClases = {
    '0: sin marcar', '1: reposo', '2: puño', '3: flexión',
    '4: extensión', '5: radial', '6: cubital', '7: palma'
};

% Aplicar sistema experto para clases 2 a 7
fprintf('\n--- Clasificación del músculo por sistema experto ---\n');
for clase = 2:7
    canal = find(activaciones(clase+1, :) == max(activaciones(clase+1, :)));

    switch clase
        case 2  % puño
            if any(canal == [2 3])
                musculo = 'Flexores de dedos (FDS/FDP)';
            else
                musculo = 'Otro músculo involucrado en puño';
            end
        case 3  % flexión muñeca
            if any(canal == [1 2])
                musculo = 'Flexor carpi radialis';
            else
                musculo = 'Otro músculo involucrado en flexión';
            end
        case 4  % extensión muñeca
            if any(canal == [6 7])
                musculo = 'Extensor carpi radialis/ulnaris';
            else
                musculo = 'Otro músculo en extensión';
            end
        case 5  % desviación radial
            if any(canal == [2 5])
                musculo = 'Flexor/Extensor carpi radialis';
            else
                musculo = 'Otro músculo en desviación radial';
            end
        case 6  % desviación cubital
            if any(canal == [6 8])
                musculo = 'Flexor/Extensor carpi ulnaris';
            else
                musculo = 'Otro músculo en desviación cubital';
            end
        case 7  % palma extendida
            if any(canal == [4 7])
                musculo = 'Extensor digitorum';
            else
                musculo = 'Otro músculo en extensión de palma';
            end
        otherwise
            musculo = 'Desconocido o sin clasificación';
    end

    fprintf('Clase %d (%s): Canal más activo = %d → %s\n', ...
        clase, nombresClases{clase + 1}, canal, musculo);
end

% --- Generación de matriz de confusión basada en sistema experto

% Inicializar vectores
trueLabels = [];
predLabels = [];

% Nombres de clases válidas (movimientos)
clasesValidas = 2:7;
numClasesValidas = length(clasesValidas);

% Mapeo simple canal → clase (según observaciones)
canalAClase = [ ...
    3;  % Canal 1 → Clase 3: flexión de muñeca
    2;  % Canal 2 → Clase 2: puño
    2;  % Canal 3 → Clase 2: puño
    7;  % Canal 4 → Clase 7: palma extendida
    5;  % Canal 5 → Clase 5: desviación radial
    4;  % Canal 6 → Clase 4: extensión de muñeca
    7;  % Canal 7 → Clase 7: palma extendida
    6   % Canal 8 → Clase 6: desviación cubital
];

for clase = clasesValidas
    datosClase = data(data.class == clase, :);
    numMuestras = height(datosClase);
    numVentanas = floor(numMuestras / windowSize);
    
    for v = 1:numVentanas
        inicio = (v-1)*windowSize + 1;
        fin = v*windowSize;
        ventana = datosClase(inicio:fin, :);

        % Calcular RMS por canal
        rmsPorCanal = zeros(1, numCanales);
        for canal = 1:numCanales
            nombreCanal = ['channel', num2str(canal)];
            senal = ventana{:, nombreCanal};
            rmsPorCanal(canal) = rms(senal);
        end
        
        % Determinar canal dominante
        [~, canalMax] = max(rmsPorCanal);

        % Clasificación basada en canal dominante
        clasePredicha = canalAClase(canalMax);

        % Guardar etiquetas
        trueLabels(end+1) = clase;
        predLabels(end+1) = clasePredicha;
    end
end

% Convertir a categóricos
nombresCortos = {'2: puño','3: flexión','4: extensión','5: radial','6: cubital','7: palma'};
trueLabelsCat = categorical(trueLabels, clasesValidas, nombresCortos);
predLabelsCat = categorical(predLabels, clasesValidas, nombresCortos);

% --- Visualización ---
figure;
confusionchart(trueLabelsCat, predLabelsCat);
title('Matriz de Confusión - Sistema Experto Basado en Canal Dominante');

% --- Cálculo de precisión ---
numCorrectas = sum(trueLabels == predLabels);
numTotales = length(trueLabels);
precisionPorcentaje = 100 * numCorrectas / numTotales;

fprintf('\nPrecisión del sistema experto: %.2f%%\n', precisionPorcentaje);

% --- Visualización en 2D de la clasificación del sistema experto ---

% Recalcular características por ventana (RMS por canal)
X = [];  % Matriz de características (ventanas x 8)
for clase = clasesValidas
    datosClase = data(data.class == clase, :);
    numMuestras = height(datosClase);
    numVentanas = floor(numMuestras / windowSize);
    
    for v = 1:numVentanas
        inicio = (v-1)*windowSize + 1;
        fin = v*windowSize;
        ventana = datosClase(inicio:fin, :);

        % Calcular RMS por canal
        rmsPorCanal = zeros(1, numCanales);
        for canal = 1:numCanales
            nombreCanal = ['channel', num2str(canal)];
            senal = ventana{:, nombreCanal};
            rmsPorCanal(canal) = rms(senal);
        end

        % Guardar características
        X = [X; rmsPorCanal];
    end
end

% Aplicar PCA
[coeff, score, ~] = pca(X);

% Visualización 2D
figure;
gscatter(score(:,1), score(:,2), trueLabelsCat, 'rgbcmy', 'o', 8);
hold on;

% Añadir clasificación predicha con otro marcador
incorrectos = trueLabels ~= predLabels;
plot(score(incorrectos,1), score(incorrectos,2), 'kx', 'MarkerSize', 8, 'LineWidth', 1.5);

title('Clasificación de Movimientos por Sistema Experto (PCA 2D)');
xlabel('Componente Principal 1');
ylabel('Componente Principal 2');
legend(nombresCortos{:}, 'Errores');
grid on;
