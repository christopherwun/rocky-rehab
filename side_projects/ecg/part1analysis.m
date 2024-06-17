clear all;
close all;
subject_files = {"Trial2Subject1.mat", "Trial1Subject1.mat", "Trial1Subject3.mat"};

for i = 1:length(subject_files)
    %% Loading in data
    data = load(subject_files{i});
    s = data.data;
    u = data.units;
    l = data.labels;
    isi = data.isi;
    isiu = data.isi_units;
    start = data.start_sample;

    s_1 = s(:, 1);
    s_2 = s(:, 2);
    s_3 = s(:, 3);

    sampling_rate = 2000; % Hz
    nfft = length(s_1);

    %% Subtract mean and plot time/frequency domain
    s_1 = s_1 - mean(s_1);
    s_2 = s_2 - mean(s_2);
    s_3 = s_3 - mean(s_3);
    t = (0:100000)/sampling_rate;

%     plot_3(s_1(1:length(t)), s_2(1:length(t)), s_3(1:length(t)), t, ...
%         'Mean Subtracted Signal', ...
%         'Time (s)', ...
%         'Voltage (V)')
    %     getHR(abs(new_1));
    disp("HR pre-filtering for " + string(i));
    getHR(abs(s_2));
%     getHR(abs(new_3));


    f = (0:nfft-1)*(sampling_rate/nfft); % Frequency vector

    fft_1_0 = fft(s_1, nfft);
    fft_2_0 = fft(s_2, nfft);
    fft_3_0 = fft(s_3, nfft);

    % Adjust the frequency vector for plotting only one half
    power_spectrum_1 = abs(fft_1_0).^2;
    power_spectrum_2 = abs(fft_1_0).^2;
    power_spectrum_3 = abs(fft_1_0).^2;

    f_range = f(f <= 3);

    plot_3(power_spectrum_1(1:length(f_range)), ...
        power_spectrum_2(1:length(f_range)), ...
        power_spectrum_3(1:length(f_range)), ...
        f_range, ...
        'Power Spectrum', ...
        'Frequency (Hz)', ...
        'Power');

    %% Zero out frequencies outside the desired range (high-pass filter, heart rate)
    % Lead 2 good for HR
    fft_1 = fft_1_0;
    fft_2 = fft_2_0;
    fft_3 = fft_3_0;

    fft_1(f < 0.5 | f > 3) = 0;
    fft_2(f < 0.5 | f > 3) = 0;
    fft_3(f < 0.5 | f > 3) = 0;

    power_spectrum_1 = abs(fft_1).^2;
    power_spectrum_2 = abs(fft_2).^2;
    power_spectrum_3 = abs(fft_3).^2;

    % Adjust the frequency vector for plotting only one part
    f_range = f(f <= 70);

%     plot_3(power_spectrum_1(1:length(f_range)), ...
%         power_spectrum_2(1:length(f_range)), ...
%         power_spectrum_3(1:length(f_range)), ...
%         f_range, ...
%         'Power Spectrum HIGH PASS', ...
%         'Frequency (Hz)', ...
%         'Power');

    new_1 = ifft(fft_1);
    new_2 = ifft(fft_2);
    new_3 = ifft(fft_3);

%     plot_3(new_1(1:length(t)), new_2(1:length(t)), new_3(1:length(t)), t, ...
%         'Mean Subtracted Signal HIGH PASS', ...
%         'Time (s)', ...
%         'Voltage (V)')

    % Identify heart rate peak
    [~, idx] = max(power_spectrum_1);
    heart_rate_frequency = f(idx);
    heart_rate_bpm = 60 * heart_rate_frequency; % Convert hz to bpm

    disp(['Estimated Heart Rate (Channel 1, Subject ' num2str(i) '): ' num2str(heart_rate_bpm) ' BPM']);

    [~, idx] = max(power_spectrum_2);
    heart_rate_frequency = f(idx);
    heart_rate_bpm = 60 * heart_rate_frequency; % Convert hz to bpm

    disp(['Estimated Heart Rate (Channel 2, Subject ' num2str(i) '): ' num2str(heart_rate_bpm) ' BPM']);

    [~, idx] = max(power_spectrum_3);
    heart_rate_frequency = f(idx);
    heart_rate_bpm = 60 * heart_rate_frequency; % Convert hz to bpm

    disp(['Estimated Heart Rate (Channel 3, Subject ' num2str(i) '): ' num2str(heart_rate_bpm) ' BPM']);


%     getHR(abs(new_1));
    getHR(abs(new_2));
%     getHR(abs(new_3));

    %% Zero out frequencies outside the desired range (low-pass filter, respiration)
    fft_1 = fft_1_0;
    fft_2 = fft_2_0;
    fft_3 = fft_3_0;

    fft_1(f > 0.5 | f < 0.1) = 0;
    fft_2(f > 0.5 | f < 0.1) = 0;
    fft_3(f > 0.5 | f < 0.1) = 0;

    power_spectrum_1 = abs(fft_1).^2;
    power_spectrum_2 = abs(fft_2).^2;
    power_spectrum_3 = abs(fft_3).^2;

    % Adjust the frequency vector for plotting only one half
    f_range = f(f <= 1);

%     plot_3(power_spectrum_1(1:length(f_range)), ...
%         power_spectrum_2(1:length(f_range)), ...
%         power_spectrum_3(1:length(f_range)), ...
%         f_range, ...
%         'Power Spectrum LOW PASS', ...
%         'Frequency (Hz)', ...
%         'Power');

    new_1 = ifft(fft_1);
    new_2 = ifft(fft_2);
    new_3 = ifft(fft_3);

%     plot_3(new_1(1:length(t)), new_2(1:length(t)), new_3(1:length(t)), t, ...
%         'Mean Subtracted Signal LOW PASS', ...
%         'Time (s)', ...
%         'Voltage (V)')

%     getHR(abs(new_1));
    getRR(abs(new_2));
%     getHR(abs(new_3));


end

function plot_3(d1, d2, d3, x, title_str, x_label, y_label)
    figure;
    subplot(3,1,1);
    plot(x, d1);
    title([title_str, ' - Channel 1']);
    xlabel(x_label);
    ylabel(y_label);

    subplot(3,1,2);
    plot(x, d2);
    title([title_str, ' - Channel 2']);
    xlabel(x_label);
    ylabel(y_label);

    subplot(3,1,3);
    plot(x, d3);
    title([title_str, ' - Channel 3']);
    xlabel(x_label);
    ylabel(y_label);

%     fontsize(16,"points")
end

function getHR(ecgSignal)
    % Detect R-peaks
    Fs = 2000;
    [~, R_locs] = findpeaks(ecgSignal, 'MinPeakHeight', std(ecgSignal), 'MinPeakDistance', Fs*0.6);
    
    % Calculate r-r durations (time between R peaks)
    r_to_r = diff(R_locs) / Fs; % Convert from samples to seconds
    
    % Average the r-r
    meanHBDuration = mean(r_to_r);
    
    % Estimate uncertainty using standard error of the mean
    uncertaintyHBDuration = std(r_to_r) / sqrt(length(r_to_r));
    
    % Calculate heart rate in bpm
    % Divide 60 by the duration of the heart beat to get BPM
    HR = 60 ./ r_to_r; 
    
    % Calculate typical heart rate as the mean of the heart rates
    typicalHR = mean(HR);
    
    % Estimate uncertainty in heart rate using standard error of the mean
    uncertaintyHR = std(HR) / sqrt(length(HR));
    
    % Display results
%     fprintf('Mean R-R duration: %.3f seconds\n', meanHBDuration);
%     fprintf('Uncertainty of R-R duration: %.3f seconds\n', uncertaintyHBDuration);
    fprintf('Typical heart rate: %.2f bpm\n', typicalHR);
    fprintf('Uncertainty of heart rate: %.2f bpm\n', uncertaintyHR );
end

function getRR(ecgSignal)
    % Detect peaks
    Fs = 2000;
    [~, R_locs] = findpeaks(ecgSignal, 'MinPeakHeight', std(ecgSignal), 'MinPeakDistance', Fs*0.6);
    
    % Calculate peak durations (time between R peaks)
    r_to_r = diff(R_locs) / Fs; % Convert from samples to seconds
    
    % Calculate heart rate in bpm
    % Divide 60 by the duration of the heart beat to get BPM
    HR = 60 ./ r_to_r; 
    
    % Calculate typical heart rate as the mean of the heart rates
    typicalHR = mean(HR);
    
    % Estimate uncertainty in heart rate using standard error of the mean
    uncertaintyHR = std(HR) / sqrt(length(HR));
    
    % Display results
%     fprintf('Mean R-R duration: %.3f seconds\n', meanHBDuration);
%     fprintf('Uncertainty of R-R duration: %.3f seconds\n', uncertaintyHBDuration);
    fprintf('Typical breathing rate: %.2f bpm\n', typicalHR);
    fprintf('Uncertainty of breathing rate: %.2f bpm\n', uncertaintyHR );
end