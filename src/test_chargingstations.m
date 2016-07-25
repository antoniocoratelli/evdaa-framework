clear; 
clc;

% type "help chargingstations" in matlab for info

% K = 9 (num. of cars)

carQ  = [    50;    25;    30;    80;    20;    30;    25;    15;    35]

carM  = [   550;   450;   350;   300;   500;   450;   400;   600;   350]

carS  = [    84;    72;    48;    72;   72;     60;    60;    72;    84]

carPx = [ -1500; -3000; +5000; +1000; -6500; -4500; +2000; -3000; +5000];

carPy = [ +6000; +2500; +1000; -2000; -6500; -1000; -5500; +2000; -2000];

carP = [carPx, carPy]

% N = 5 (num. of stations)

staC  = 2

staM  = 2

staK  = [   100;    90;   110;    95;   120]

staPx = [     0; -4000; -4000; +4000; +4000];

staPy = [     0; +4000; -4000; -4000; +4000];

staP = [staPx, staPy]

% safety charge

H = 2 

% evdaa maximum number of iterations

MAX_ITER = 50

chargingstations(carQ, carM, carS, carP, staK, staC, staM, staP, H, MAX_ITER)

