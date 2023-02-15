w = 85000*2*pi;
L1=353.68*10^-6;
L2=216.02*10^-6;
M=66*10^-6;
R1=0.483;
R2=0.281;
Us=400/2^(1/2);
Rs=0.1;
RL=10;

C1 = 1/(w^2*L1);
C2 = 1/(w^2*L2);

Z1 = R1 + Rs;
Z2 = RL + R2;

I1 = Us/(Z1 + (w*M)^2/Z2);
I2 = abs(1i*w*M*Us/(Z1*Z2+(w*M)^2));

UL = I2*RL;

Q1 = w*L1/R1;
Q2 = w*L2/R2;

Pin = Us*I1;
Pout = I2^2*RL;
effi = Pout/Pin;