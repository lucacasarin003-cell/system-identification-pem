clear variables
close all
clc
% Data generation
N = 8000;
Ts = 1;  % sampling time

% Coefficientes of the actual model
Fden = [1 -0.96 0.97];  
Fnum = [0 2.99 -0.2];    
Gden = [1 -0.96 0.97];
Gnum = 1;

% Generate normalized WGN noise en0
en0 = idinput(N,'rgs');

% Input generation
% interval [pi*alpha1 pi*alpha2]
alpha1 = 0.125;
alpha2 = 0.5;
k_sin = 5; % number of sinusoids
u = 4*idinput(N,'sine',[alpha1 alpha2],[],k_sin);

% noise variance sigma0^2 of e0=sigma_0*en0
noiseVar = 4.6^2;

% Creation of the actual model
m0 = idpoly([],Fnum,Gnum,Gden,Fden,noiseVar,Ts); 

% Creation of the iddata object, we store only the input data u
u = iddata([],u,Ts); 

% Creation of the iddata object, in this case we store only the normalized noise data en0
en0 = iddata([],en0,Ts); 

% Generation of the output data given model, input and noise
y = sim(m0, [u en0]);

% Creation of an iddata object for the output and input data 
data = iddata(y,u);

% Model estimation
% PEM method

% Estimation of an ARX model

% orders of the ARX model
% orders_arx(1) = nA
% orders_arx(2) = nB
% orders_arx(3) = nk
orders_arx = [2 2 1]; 

% ARX model estimation
m_arx = arx(data,orders_arx);

% Plot the coefficients of the estimated model
m_arx.a % A(z)
m_arx.b % B(z)
m_arx.NoiseVariance % sigma^2


% Estimation of an ARMAX model

% orders of the ARMAX model
% orders_armax(1) = nA
% orders_armax(2) = nB
% orders_armax(3) = nC
% orders_armax(4) = nk
orders_armax = [2 2 1 1];

% ARMAX model estimation
m_armax = armax(data,orders_armax);

% Plot the coefficient of the estimated model
m_armax.a % A(z)
m_armax.b % B(z)
m_armax.c % C(z)
m_armax.NoiseVariance % sigma^2


% Estimation of an OE model

% orders of the OE model
% orders_oe(1) = nB
% orders_oe(2) = nF
% orders_oe(3) = nk
orders_oe = [2 1 1]; 

% OE model estimation
m_oe = oe(data,orders_oe);

% Plot the coefficient of the estimated model
m_oe.b % B(z)
m_oe.f % F(z)
m_oe.NoiseVariance % sigma^2


% Estimation of a Box-Jenkins model

% coefficients of the BJ model
% orders_bj(1) = nB
% orders_bj(2) = nC
% orders_bj(3) = nD
% orders_bj(4) = nF
% orders_bj(5) = nk
orders_bj = [2 1 1 2 1];

% BJ model generation
m_bj = bj(data,orders_bj);

% Plot the coefficient of the estimated model
m_bj.b % B(z)
m_bj.c % C(z)
m_bj.d % D(z) 
m_bj.f % F(z)
m_bj.NoiseVariance % sigma^2

% Extract PEM estimators for the models
theta_hat_arx = m_arx.Report.Parameters.ParVector;
theta_hat_armax = m_armax.Report.Parameters.ParVector;
theta_hat_oe = m_oe.Report.Parameters.ParVector;
theta_hat_bj = m_bj.Report.Parameters.ParVector;

% Frequency analysis
% Plot Bode diagram
h = figure;
bodeplot(m0, m_arx, m_armax, m_oe, m_bj);
legend('True','ARX','ARMAX','OE','BJ');
grid on;
title(['Bode Plot Comparison (N = ', num2str(N), ')']);

% Statistical analysis
y_raw = data.y;
u_raw = data.u;
N = length(y_raw);

Psi = zeros(4, N);
for t = 3:N
    Psi(:,t) = [-y_raw(t-1); -y_raw(t-2); u_raw(t-1); u_raw(t-2)];
end

% Calculating P_hat_N
SumPsi = (Psi * Psi') / N;
P_hat_N = m_arx.NoiseVariance * inv(SumPsi);

% Calculating approximation errors
app_err1 = abs(theta_hat_arx(1) + 0.96);
app_err2 = abs(theta_hat_arx(2) - 0.97);
app_err3 = abs(theta_hat_arx(3) - 2.99);
app_err4 = abs(theta_hat_arx(4) + 0.2);

% Calculating confidence intervals
rhs1 = 1.96 * sqrt(P_hat_N(1, 1)/N);
rhs2 = 1.96 * sqrt(P_hat_N(2, 2)/N);
rhs3 = 1.96 * sqrt(P_hat_N(3, 3)/N);
rhs4 = 1.96 * sqrt(P_hat_N(4, 4)/N);

app_err = [app_err1; app_err2; app_err3; app_err4];
rhs = [rhs1; rhs2; rhs3; rhs4];

for i = 1:4
    if app_err(i) <= rhs(i)
        disp(['Parameter ', num2str(i), ': in the interval'])
    else
        disp(['Parameter ', num2str(i), ': Not in the interval'])
    end
end

