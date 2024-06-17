%% Model parameters
Radius_Plate = 30; %mm
Radius_Disk = 2.5; %mm
T = 24 * 60; %min
D = 0.15; %mm^2/min
sourceconc = 1000; %uM

%% X-Y Mesh
num_pts = 101;
dp = 60 / (num_pts - 1);
dx = dp;
dy = dp;

xgrid = [-Radius_Plate:dx:Radius_Plate]; % centers the grid in x around zero
ygrid = [-Radius_Plate:dy:Radius_Plate]; % centers the grid in y around zero
[X,Y] = meshgrid(xgrid, ygrid); % creates the matrix that describes the mesh using meshgrid

%% Discretize time
stability_factor = 0.25; % must be <= 0.25 for FTCS in 2D
dt = stability_factor*(dp^2)/D; % (min) time increment that fulfills the stability criterion (from
%Equation 6)
time = [0:dt:T]; % Time Vector incremented in steps of dt
r = D*dt/(dp^2); % r term in the Finite Difference Equation (i.e. Equation 1)

%% Setting initial values
AHL_Initial = zeros(length(xgrid), length(ygrid));% Set initial AHL concentration to zero across
% the whole plate described by the matrix AHL_Initial
[Disk_Indices_Row, Disk_Indices_Col] = find(sqrt(X.^2+Y.^2)<=Radius_Disk); % the loop below
% sets the initial concentration of the disk

for i = 1:length(Disk_Indices_Row)
AHL_Initial(Disk_Indices_Row(i), Disk_Indices_Col(i)) = sourceconc;
end

% mesh(X,Y,AHL_Initial) % Draws the mesh to visualize initial conditions as a quality control step.

%% Initializing AHL
AHL = AHL_Initial;

% % Initializing edge trackers
% edge_s1 = zeros(length(time));
% edge_s2 = zeros(length(time));
% edge_s3 = zeros(length(time));
% 
% switchpt_s1 = 0.10985411419875594;
% switchpt_s2 = 2.1209508879201926;
% switchpt_s3 = 0.10985411419875594;
% 
% % Assuming the center of the plate is at (0,0) in the grid
% center_index = find(xgrid == 0, 1);
% 
% % Simulation with Plotting at Specific Times
% for t = 1:length(time)
%     % Create padded matrix to handle boundaries (instead of circshift like
%     % last time) - using matrix operations to speed up computation
%     AHL_padded = padarray(AHL,[1 1],0,'both');
%     
%     % Calculate diffusion using matrix operations
%     rshift = AHL_padded(2:end-1, 3:end);   % Right shift
%     lshift = AHL_padded(2:end-1, 1:end-2); % Left shift
%     dshift = AHL_padded(3:end, 2:end-1);   % Down shift
%     ushift = AHL_padded(1:end-2, 2:end-1); % Up shift
% 
%     radial_concentration_profile = AHL(center_index, center_index:end);
% 
%     % Use findEdge function to find the edge distance for each switch point
%     edge_s1(t) = findEdge(radial_concentration_profile, switchpt_s1, xgrid);
%     edge_s2(t) = findEdge(radial_concentration_profile, switchpt_s2, xgrid);
%     edge_s3(t) = findEdge(radial_concentration_profile, switchpt_s3, xgrid);
%     
%     % Update AHL with diffusion effect
%     AHL = AHL + r*(rshift + lshift + ushift + dshift - 4*AHL);
% end
% 
% % Graph 
% figure(1);
% % Find the index where time is 21 hours (1260 minutes)
% end_index = find(time >= 21*60, 1);
% 
% % Plot only up to 21 hours
% plot(time(1:end_index), edge_s1(1:end_index), 'LineWidth', 2); hold on;
% plot(time(1:end_index), edge_s2(1:end_index), 'LineWidth', 2); hold on;
% plot(time(1:end_index), edge_s3(1:end_index), 'LineWidth', 2);
% hold off;
% 
% % Add labels and title
% xlabel('Time (minutes)');
% ylabel('Edge Distance (mm)');
% title('Modeled Edge Distance vs. Time up to 21 hours');
% legend('Strain 1', 'Strain 2', 'Strain 3');
% grid on;

%% Simulation with non-steady state diffeqs
AHL = AHL_Initial;
R = zeros(size(AHL_Initial));
TXGFP = zeros(size(AHL_Initial));
GFP = zeros(size(AHL_Initial));
% Stack matrices along the third dimension instead of concatenating them linearly
curr_concs = cat(3, R, TXGFP, GFP); % Now curr_concs(:,:,1) = R, (:,:,2) = TXGFP, (:,:,3) = GFP
C_LuxR_1 = 0.3;
K_R_12 = 0.4;

m = size(GFP,1);
n = size(GFP,2);

% Calculate number of frames based on 3-hour intervals
totalTime = max(time); % Get the total simulation time in minutes
interval = 180; % 3 hours in minutes
numFrames = ceil(totalTime / interval); % Number of frames to save

% Initialization of allGFP
allGFP = zeros(m, n, numFrames);

% Variables to track saving frames
saveInterval = interval / dt; % Number of time steps between saves
frameIndex = 1; % Index for allGFP

for t = 1:length(time)
    % Create padded matrix to handle boundaries
    AHL_padded = padarray(AHL,[1 1],0,'both');
    
    % Calculate diffusion using matrix operations
    rshift = AHL_padded(2:end-1, 3:end);   % Right shift
    lshift = AHL_padded(2:end-1, 1:end-2); % Left shift
    dshift = AHL_padded(3:end, 2:end-1);   % Down shift
    ushift = AHL_padded(1:end-2, 2:end-1); % Up shift
    
    % Update AHL with diffusion effect
    AHL = AHL + r*(rshift + lshift + ushift + dshift - 4*AHL);

    % Update other matrices using updated fd_model_single_iteration function
    % Now curr_concs is a 3D matrix where each "slice" is a different concentration matrix
    dconcs = fd_model_single_iteration(curr_concs, AHL, C_LuxR_1, K_R_12, dt);
    curr_concs = curr_concs + dconcs; % Update concentrations

    % Check if current time step corresponds to a 3-hour interval
    if mod(t-1, saveInterval) == 0
        % Save current GFP concentration at 3-hour intervals
        allGFP(:,:,frameIndex) = curr_concs(:,:,3); % Correctly access the GFP slice
        frameIndex = frameIndex + 1; % Increment frame index
    end
end


%% Plotting
numFrames = size(allGFP, 3); % Get the number of frames

% Set up the figure
figure;

% Plot each frame as a subplot
for frameIdx = 1:numFrames
    subplot(3, 3, frameIdx); % Adjust subplot layout if necessary
    imagesc(allGFP(:,:,frameIdx)); % Plot heatmap
    colormap('jet'); % Set colormap (optional, for aesthetics)
    colorbar; % Show color scale
    title(sprintf('Time: %d hours', (frameIdx-1)*3)); % Title each subplot with the corresponding time
    axis equal tight; % Adjust axis for better visualization
end

% Adjust layout to prevent subplot titles and labels from overlapping
sgtitle('GFP Concentration Heatmaps at 3-hour Intervals'); % Super title for the entire figure

%% Function Defs
function edge_distance = findEdge(concentration_profile, switch_point, xgrid)
    % Find the index of the point where the concentration profile is closest to the switch point
    [~, idx] = min(abs(concentration_profile - switch_point));
    % Return the corresponding distance from the center to this point
    edge_distance = xgrid(idx);
end

function C_GFP = transfer_func(C_AHL, C_LuxR, K_R) % takes a vector
    % Set Constant Starting Poins
    alp_TXGFP = 0.05; %uM/min
    rho_R = 0.5;
    del_TXGFP = 0.2;
    del_R = 0.0001;
    alp_GFP = 2;
    del_GFP = 4e-4;
    n = 1;

    % Calculation
    int_val = rho_R * (C_LuxR^2) * (C_AHL.^2) / (del_R * K_R);
    num = alp_GFP * alp_TXGFP * int_val.^n;
    denom = del_GFP * del_TXGFP * (1 + int_val).^n;

    C_GFP = num./denom;
end

function dconcs = fd_model_single_iteration(curr_concs, C_AHL, C_LuxR, K_R, dt)
    % Extracting each concentration component
    C_R = curr_concs(:,:,1);     % Concentration of R
    C_TXGFP = curr_concs(:,:,2); % Concentration of TX_GFP
    C_GFP = curr_concs(:,:,2);   % Concentration of GFP

    % Define parameters
    alp_TXGFP = 0.05; % uM/min
    rho_R = 0.5;
    del_TXGFP = 0.2;
    del_R = 0.0001;
    alp_GFP = 2;
    del_GFP = 4e-4;
    n1 = 1;

    % Reaction dynamics equations with element-wise operations
    dRdt = rho_R .* (C_LuxR.^2) .* (C_AHL.^2) - del_R .* C_R; % Eq. 1: Activation of LuxR by AHL
    dTXGFPdt = (alp_TXGFP .* (C_R./K_R).^n1) ./ (1 + (C_R./K_R).^n1) - del_TXGFP .* C_TXGFP;
    dGFPdt = alp_GFP .* C_TXGFP - del_GFP .* C_GFP;

    % Returning the differential concentrations as a matrix similar to input format
    dconcs = cat(3, dRdt .* dt, dTXGFPdt .* dt, dGFPdt .* dt);
end