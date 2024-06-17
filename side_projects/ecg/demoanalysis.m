clear all;
close all;
subject_files = {"Subject1Demo.mat"}; %%, "Subject2Demo.mat", "Subject3Demo.mat"};
% subject_files = {"Subject1_1.mat"}; %%, "Subject2_1.mat", "Subject3_1.mat"};
% subject_files = {"Subject1_2.mat"}; %%, "Subject2_2.mat", "Subject3_2.mat"};
% subject_files = {"Subject1_3.mat"}; %%, "Subject2_3.mat", "Subject3_3.mat"};
% subject_files = {"Subject1_4.mat"}; %%, "Subject2_4.mat", "Subject3_4.mat"};


%% Loading in data
for i = 1:length(subject_files)
    data = load(subject_files{i});
    s = data.data;
    hr = s(:,1);
    rr = s(:,2);
    u = data.units;
    l = data.labels;
    isi = data.isi;
    isiu = data.isi_units;
    start = data.start_sample;

    sampling_rate = 2000; % Hz
    nfft = length(hr);

    %% Subtract mean and plot time/frequency domain
    hr = hr - mean(hr);
    rr = rr - mean(rr);

    getSNR(hr, sampling_rate, 0.5, 60);
    getSNR(rr, sampling_rate, 0, 0.5);

    getEssBW(hr, sampling_rate, 0.95);
    getEssBW(rr, sampling_rate, 0.95);

    getPwrInSegment(hr, sampling_rate, 0.5, 15.9);
    getPwrInSegment(rr, sampling_rate, 0.01, 0.35);

%     disp(length(hr))
%     t = (1:length(hr) - 100*2000)/sampling_rate;
    rnge = 75*2000:135*2000;
    rnge2 = 1:nfft - 100*2000;
    t = rnge/sampling_rate;
    t2 = rnge2/sampling_rate;

    cust_plot(hr(rnge2), t2, ...
        'Mean Subtracted Signal HR', ...
        'Time (s)', ...
        'Voltage (V)')
    cust_plot(rr(rnge), t, ...
        'Mean Subtracted Signal RR', ...
        'Time (s)', ...
        'Voltage (V)')

    getHR(abs(hr(rnge)));
    % rr uses minpk as another arg in order to make sure not to collect
    % respiratory rate when holding breath due to random noise
    minpk = std(rr(100*2000:nfft - 200*2000));
    getRR(abs(rr(rnge)), minpk);

    f = (0:nfft-1)*(sampling_rate/nfft); % Frequency vector

    fft_hr = fft(hr, nfft);
    fft_rr = fft(rr, nfft);

    % Adjust the frequency vector for plotting only one half
    power_spectrum_hr = abs(fft_hr).^2;
    power_spectrum_rr = abs(fft_rr).^2;

    f_range = f(f <= 3);
% 
    cust_plot(power_spectrum_hr(1:length(f_range)), ...
        f_range, ...
        'Power Spectrum HR', ...
        'Frequency (Hz)', ...
        'Power');
    cust_plot(power_spectrum_rr(1:length(f_range)), ...
        f_range, ...
        'Power Spectrum RR', ...
        'Frequency (Hz)', ...
        'Power');

    new_hr = ifft(fft_hr);
    new_rr = ifft(fft_rr);

    getEssBW(new_hr, sampling_rate, 0.95);
    getEssBW(new_rr, sampling_rate, 0.95);

%     cust_plot(new_hr(rnge)-mean(new_hr(rnge)), t, ...
%         'Mean Subtracted Signal HR', ...
%         'Time (s)', ...
%         'Voltage (V)')
% 
    to_plot = new_rr(rnge) - mean(new_rr(rnge));
    cust_plot(smoothdata(to_plot, 'gaussian', 500), t, ...
        'New Mean Subtracted Signal RR', ...
        'Time (s)', ...
        'Voltage (V)')


%     getHR(abs(new_hr(rnge)));
%     rr_to_calc = new_rr(rnge) - mean(new_rr(rnge));
%     getRR(abs(rr_to_calc), minpk);

end

function cust_plot(d1, x, title_str, x_label, y_label)
    figure;
    plot(x, d1);
    title([title_str, ' - Channel 1']);
    xlabel(x_label);
    ylabel(y_label);

%     fontsize(16,"points")
end

function getHR(ecgSignal)
    % Detect R-peaks
    Fs = 2000;
    [~, R_locs] = findpeaks(ecgSignal, 'MinPeakHeight', 3*std(ecgSignal), 'MinPeakDistance', Fs*0.6);
    
    % Calculate r-r durations (time between R peaks)
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
    fprintf('Typical heart rate: %.2f bpm\n', typicalHR);
    fprintf('Uncertainty of heart rate: %.2f bpm\n', uncertaintyHR );
end

function getRR(ecgSignal, minpk)
    % Detect peaks
    Fs = 2000;

    % Smooth to enhance peak finding
    ecgSignal = smoothdata(ecgSignal, 'gaussian', 2500);
    [~, R_locs] = findpeaks(ecgSignal, 'MinPeakHeight', minpk, 'MinPeakDistance', Fs*3);
    
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

function snr = getSNR(signal, Fs, f_low, f_high)
    % Compute the FFT of the signal
    fft_signal = fft(signal);
    
    % Calculate the frequency resolution
    df = Fs / length(signal);
    
    % Identify the frequency indices corresponding to the desired frequency range
    f_indices = round([f_low, f_high] / df) + 1; % Adding 1 to adjust for MATLAB indexing
    
    % Sum the power of the signal within the desired frequency range
    signal_power = sum(abs(fft_signal(f_indices(1):f_indices(2))).^2);
    
    % Sum the power of the noise outside the desired frequency range
    noise_power = sum(abs(fft_signal).^2) - signal_power;
    
    % Calculate SNR in dB
    snr = 10 * log10(signal_power / noise_power);
    fprintf('SNR (ratio): %.2f dB\n', signal_power / noise_power);
    fprintf('SNR: %.2f dB\n', snr);
end

function bw = getEssBW(signal, fs, power_pct)
    fft_signal = fft(signal);
    
    % Frequency interval calculation
    df = fs / length(signal);

    % Convert to power
    power = abs(fft_signal).^2;
    power = power(1:length(signal)/2+1);  
    cumulative_power = cumsum(power);
    threshold_power = power_pct * sum(power);
    essential_idx = find(cumulative_power <= threshold_power, 1, 'last');
    
    % Calculate essential bandwidth
    bw = essential_idx * df;

    fprintf('Essential Bandwidth: %f Hz\n', bw);
end

function pct = getPwrInSegment(signal, fs, start_freq, end_freq)
    fft_signal = fft(signal);
    
    % Frequency interval calculation
    df = fs / length(signal);

    % Convert to power
    power = abs(fft_signal).^2;
    power = power(1:length(signal)/2+1); 

    % Find indices corresponding to start and end frequencies
    start_index = round(start_freq / df) + 1;
    end_index = round(end_freq / df) + 1;

    % Get cumulative power from start to end indices
    cumpower = sum(power(start_index:end_index));

    % Divide by total power
    total_power = sum(power);
    pct = cumpower / total_power;
    
    fprintf('Percentage: %f %%\n', pct*100);
end
