function [mat_Commn, mat_Costs, con_Capty, con_Commn] = evdatest_random ...
(cfg_nodes_min, cfg_nodes_max, cfg_tasks_min, cfg_tasks_max, ...
cfg_const_add, cfg_costs_min, cfg_costs_max, ...
cfg_commn_min, cfg_commn_max, cfg_commn_pro)
%.
% function:
%
%    generate random matrixes for a Discrete Consensus Problem
%    in a Network with Constrained Capacities
%
% arguments:
%
%    cfg_nodes_min: mimimum number of nodes in the network
%    cfg_nodes_max: maximum number of nodes in the network
%    cfg_tasks_min: mimimum number of tasks to be performed
%    cfg_tasks_max: maximum number of tasks to be performed
%    cfg_costs_min: minimum cost for a task *
%    cfg_costs_max: maximum cost for a task *
%    cfg_commn_pro: communication probability between nodes
%    cfg_commn_min: minimum communication constraint
%    cfg_commn_max: maximum communication constraint
%    cfg_const_add: maximum number of tasks that a node can perform 
%                   (added to the minimum value such that K <= M N)
%
%    * negative values in the costs matrix will be replaced with zeros
%
%	returns:
%
%    mat_Commn = communication matrix
%    mat_Costs = task costs matrix
%    con_Capty = capacity constraint
%
%
% Copyright (c) 2013, Antonio Coratelli
% All rights reserved.
%
% Released under BSD 3-Clause License.
% See `LICENSE` file or `https://opensource.org/licenses/BSD-3-Clause`.
%
	verbose = true;
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK ARGUMENTS

	if (nargin < 10)
		error('All arguments are required');
	end
	
	if cfg_nodes_min < 1 || mod(cfg_nodes_min, 1) ~= 0 
		error('cfg_nodes_min: wrong value');
	end
	
	if cfg_nodes_max < 1 || mod(cfg_nodes_max, 1) ~= 0 
		error('cfg_nodes_max: wrong value');
	end
	
	if cfg_nodes_min > cfg_nodes_max
		error('error: cfg_nodes_min > cg_nodes_max');  
	end
		
	if cfg_tasks_min < 1 || mod(cfg_tasks_min, 1) ~= 0 
		error('cfg_tasks_min: wrong value');
	end
	
	if cfg_tasks_max < 1 || mod(cfg_tasks_max, 1) ~= 0 
		error('cfg_tasks_max: wrong value');
	end
	
	if cfg_tasks_min > cfg_tasks_max
		error('error: cfg_tasks_min > cfg_tasks_max');  
	end
	
	if cfg_tasks_max < cfg_nodes_max
		error('error: cfg_tasks_max < cfg_nodes_max');
	end
	
	if mod(cfg_costs_min, 1) ~= 0 
		error('cfg_costs_min: wrong value');
	end
	
	if cfg_costs_max < 1 || mod(cfg_costs_max, 1) ~= 0 
		error('cfg_costs_max: wrong value');
	end
	
	if cfg_costs_min > cfg_costs_max
		error('error: cfg_costs_min > cg_costs_max');  
	end
	
	if cfg_commn_min < 1 || mod(cfg_commn_min, 1) ~= 0 
		error('cfg_commn_min: wrong value');
	end
	
	if cfg_commn_max < 1 || mod(cfg_commn_max, 1) ~= 0 
		error('cfg_commn_max: wrong value');
	end
	
	if cfg_commn_min > cfg_commn_max
		error('error: cfg_commn_min > cg_commn_max');  
	end
	
	if cfg_commn_pro <= 0 || cfg_commn_pro > 1
		error('cfg_commn_pro: wrong value');  
	end
	
	if cfg_commn_pro < .15
		warning('cfg_commn_pro: you shoul not use values smaller than 0.15');
	end
	
	if cfg_const_add < 0
		error('cfg_const_add: wrong value');  
	end
			
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE NODES AND TASKS
	
	num_Nodes = randi( [ cfg_nodes_min cfg_nodes_max ] );
	num_Tasks = randi( [ max([num_Nodes cfg_tasks_min]) cfg_tasks_max ] );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE CONSTRAINTS

	con_Capty = ceil( num_Tasks / num_Nodes ) + randi( [0 cfg_const_add] );
	con_Commn = randi( [ cfg_commn_min cfg_commn_max ] );
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE COSTS MATRIX

	mat_Costs = randi([cfg_costs_min cfg_costs_max], num_Nodes, num_Tasks);
	mat_Costs( mat_Costs < 0 ) = 0;
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE COMMUNICATION MATRIX

	mat_Commn = zeros(num_Nodes, num_Nodes);
	flag = false;
	
	% force generation of a connected communication matrix
	while ~flag
		for i = 1:num_Nodes
			for j = i+1:num_Nodes
				if rand < cfg_commn_pro
					mat_Commn(i,j) = 1;
				end
				mat_Commn(j,i) = mat_Commn(i,j);
			end
		end
		flag = true;
		% check communication matrix connected
		connected = zeros(num_Nodes, num_Nodes);
		for i = 1: num_Nodes
			connected = connected + mat_Commn^i;
		end
		for i = 1:num_Nodes
			for j = 1:num_Nodes
				if connected(i,j) == 0
					flag = false;
				end
			end
		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINT
	
	%#
	if verbose
	fprintf('\n +------------------------+');
	fprintf('\n | EVDAA RANDOM GENERATOR |');
	fprintf('\n +------------------------+\n\n');
	fprintf('\nNodes Number:\n\n');
	disp(num_Nodes);
	fprintf('\nTasks Number:\n\n');
	disp(num_Tasks);
	fprintf('\nCommunication Matrix:\n\n');
	disp(mat_Commn);
	fprintf('\nCosts Matrix:\n\n');
	disp(mat_Costs);
	fprintf('\nCapacity Constraint:\n\n');
	disp(con_Capty)
	end

end
