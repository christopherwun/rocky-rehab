AHL = logspace(-4, 0);
GFP = model(AHL, 0.1);

semilogx(AHL, GFP);
title("GFP v. AHL for [LuxR] = 0.1", "FontSize", 15);
xlabel('Log([AHL] (uM))', 'FontSize', 15);
ylabel('[GFP]', 'FontSize', 15);
grid on
ax = gca;
ax.FontSize = 15;

function C_GFP = model(C_AHL, C_LuxR) % takes a vector
    % Set Constant Starting Poins
    alp_TXGFP = 0.05; %uM/min
    rho_R = 0.5;
    del_TXGFP = 0.2;
    del_R = 0.0231;
    alp_GFP = 2;
    K_R = 1.3e-5;
    del_GFP = 4e-4;
    n = 1;

    % Calculation
    int_val = rho_R * (C_LuxR^2) * (C_AHL.^2) / (del_R * K_R);
    num = alp_GFP * alp_TXGFP * int_val.^n;
    denom = del_GFP * del_TXGFP * (1 + int_val).^n;

    C_GFP = num./denom;
end