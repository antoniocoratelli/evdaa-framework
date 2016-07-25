function mat_Assgn = chargingstations ...
(carQ, carM, carS, carP, staK, staC, staM, staP, CHSAFE, MAX_ITER)
%.
% function: 
%
%    solve the assignment problem for a charging stations network
%    using a discrete consensus algorithm (evdaa)
%
%    let N be the number of stations in the network, K be the number of cars
% 
% arguments: 
%
%    carQ = K-sized column vector; INTEGER values in {0, 1, ..., CHMAX}
%           charge level for each car
%                   
%    carM = K-sized column vector; INTEGER values in {1, 2, ...}
%           meters a car can travel 
%           consuming 1 charge point
%                   
%    carS = K-sized column vector; INTEGER values in {1, 2, ...}
%           charging seconds necessary in order to increase by 
%           1 charge point a car's battery using station_1
%              
%    carP = (K x 2)-sized matrix; INTEGER values in ]-inf, +inf[^2
%           absolute position of a charging station in meters
%
%    staK = N-sized column vector; INTEGER values in {1, 2, ...}
%           percentual corrective value for charging time 
%           (normalized on station_1)
%           ex.: staK(1)=100 
%                staK(2)=120 (station 2 is 20% slower than station 1)
%                staK(3)=90 (station 3 is 10% faster than station 1)
%                   
%    staC = INTEGER value in {1, 2, ...}
%           stations capacity constraint
%
%    staM = INTEGER value in {1, 2, ...}
%           stations communication constraint
%
%    staP = (K x 2)-sized matrix; INTEGER values in ]-inf, +inf[^2
%           absolute position of a car in meters
%
%    CHSAFE = minimum safety charge
%
%    MAX_ITER = maximum number of evdaa iterations
%    
% returns: 
%
%    mat_Assgn = assignment matrix
%
%
% Copyright (c) 2013, Antonio Coratelli
% All rights reserved.
%
% Released under BSD 3-Clause License.
% See `LICENSE` file or `https://opensource.org/licenses/BSD-3-Clause`.
%
	CHMAX = 100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK ARGUMENTS

	% check arguments number
	if (nargin < 10)
		error('all arguments are required (10 args)');
	end
	
	% check CHSAFE size
	if ~isequal(size(CHSAFE), [1 1])
		error('CHSAFE: wrong size');
	end

	% check CHSAFE value
	if CHSAFE < 1 || CHSAFE >= CHMAX || mod(CHSAFE, 1) ~= 0
		error('CHSAFE: wrong value');
	end
	
	% check MAX_ITER size
	if ~isequal(size(MAX_ITER), [1 1])
		error('CHSAFE: wrong size');
	end

	% check CHSAFE value
	if MAX_ITER < 1 || mod(MAX_ITER, 1) ~= 0
		error('MAX_ITER: wrong value');
	end
	
	% get station number N from staP
	[N staP_2] = size ( staP );
	
	% control staP size
	if staP_2 ~= 2
		error('staP: wrong size');
	end
	
	% control staK size
	if  ~isequal(size(staK), [N 1])
		error('staK: wrong size');
	end	
	
	% control staC size
	if  ~isequal(size(staC), [1 1])
		error('staC: wrong size');
	end
	
	% control staM size
	if  ~isequal(size(staM), [1 1])
		error('staM: wrong size');
	end
	
	% control staM value
	if staM < 1 || mod(staM, 1) ~= 0
		error('staM: wrong value');
	end
	
	% control staC value
	if staC < 1 || mod(staC, 1) ~= 0
		error('staC: wrong value');
	end
	
	% control sta* values
	for i = 1:N
	
		if staK(i) < 1 || mod(staK(i), 1) ~= 0
			error('staK: wrong value found');
		end
		
		if mod(staP(i, 1), 1) ~= 0
			error('staP: wrong value found in x column');
		end
		if mod(staP(i, 1), 1) ~= 0
			error('staP: wrong value found in y column');
		end
		
	end

	% get car number K from carP
	[K carP_2] = size ( carP );

	% control carP size
	if carP_2 ~= 2
		error('carP: wrong size');
	end
	
	% control carS size
	if ~isequal(size(carS), [K 1])
		error('carS: wrong size');
	end		
	
	% control carM size
	if ~isequal(size(carM), [K 1])
		error('carM: wrong size');
	end
	
	% control carQ size	
	if ~isequal(size(carQ), [K 1])
		error('carQ: wrong size');
	end		
	
	% control car* values
	for i = 1:K
	
		if carQ(i) < 0 || carQ(i) > CHMAX || mod(carQ(i), 1) ~= 0
			error('carQ: wrong value found');
		end
	
		if carM(i) < 1 || mod(carM(i), 1) ~= 0
			error('carM: wrong value found');
		end
	
		if carS(i) < 1 || mod(carS(i), 1) ~= 0
			error('carS: wrong value found');
		end
	
		if mod(carP(i, 1), 1) ~= 0
			error('carP: wrong value found in x column');
		end
		if mod(carP(i, 1), 1) ~= 0
			error('carP: wrong value found in y column');
		end
	
	end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET con_Capty and con_Commn

	con_Capty = staC;
	con_Commn = staM;
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD mat_Commn (fully connected network);

	mat_Commn = ones(N) - eye(N);
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD mat_Costs

	mat_Costs = zeros(N, K);

	d = zeros(N, K);
	q = zeros(N, K);
	r = zeros(N, K);
	m = zeros(N, K);
	t = zeros(N, K);
	
	for i = 1:N
		for j = 1:K
		
			d(i, j) = manhattan(staP, i, carP, j);
			q(i, j) = ceil( d(i, j) / carM(j) );
			r(i, j) = carQ(j) - q(i, j);
			m(i, j) = CHMAX - r(i, j);
			t(i, j) = staK(i) * carS(j) * m(i, j);
			
			if r(i, j) < CHSAFE
					mat_Costs(i, j) = 0;
			else
					mat_Costs(i, j) = t(i, j);
			end
			
		end
	end
	
	d
	q
	r
	m
	t
	mat_Costs	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOLVE PROBLEM USING EVDAA
	
	mat_Assgn = evdaa(mat_Commn, mat_Costs, con_Capty, con_Commn, MAX_ITER, 1);
	
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MANHATTAN DISTANCE

function dist = manhattan(staP, staI, carP, carI)
%
% function: returns manhattan distance between station I and car I 
%
	node1 = carP (carI, :);
	node2 = staP (staI, :);	
	dist = abs( node1(1) - node2(1) ) + abs( node1(2) - node2(2) );
end

