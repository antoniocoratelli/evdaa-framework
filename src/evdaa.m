function [mat_Assgn] = evdaa ...
(mat_Commn, mat_Costs, con_Capty, con_Commn, MAX_ITER, ini_Node)
%.
% function:
%
%    solve a Discrete Consensus Problem in a Network with Constrained Capacities
%
% arguments:
%
%    mat_Commn = communication matrix
%    mat_Costs = task costs matrix
%    con_Capty = capacity constraint
%    con_Commn = communication constraint (inf = no constraint)
%    MAX_ITER  = maximum number of iterations
%    ini_Node  = initial node (optional, default = random node)
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
	verbose = true;
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK ARGUMENTS
	
	% check number of arguments
	if (nargin < 5)
		error('all arguments are required except ini_Node');
	end
	
	% check MAX_ITER is not less than one and integer
	if ( MAX_ITER < 1 || mod(MAX_ITER, 1) ~= 0 )
		error('MAX_ITER must be an integer and can''t be less than one');
	end
	
	% calculate number of nodes and number of tasks from costs matrix
	[num_Nodes num_Tasks] = size(mat_Costs);
	
	% check num_Nodes and num_Tasks
	if ( num_Nodes > num_Tasks )
		error('num_Nodes can''t be less than num_Tasks');
	end
	
	% check num_Nodes, num_Tasks and con_Capty
	if (num_Tasks > con_Capty * num_Nodes )
		error('num_Tasks can''t be more than con_Capty*num_Nodes');
	end	

	% check coherence of supplied matrixes
	if ~evdaa_iscoherent(mat_Commn, mat_Costs, con_Capty)
		error('incoherent or invalid arguments');
	end
	
	% initialize fully connected flag
	fully_connected = true;
	
	% check if communication matrix is fully connected
	for i = 1:num_Nodes
		for j = i+1:num_Nodes
			
			% if two nodes at least are unconnected 
			if mat_Commn(i, j) ~= 1
				
				% the graph isn't fully connected
				fully_connected = false;

				% set communication constraint to infinity
				% con_Commn = inf;
			end

		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE

	% initialize time counter
	T = 0;
	
	% initialize assignment matrix
	mat_Assgn = zeros(num_Nodes, num_Tasks);
	
	% initialize previous maximum load vector
	prev_loadmax = Inf(1, num_Nodes);
	
	% initialize previous total load vector
	prev_loadtot = Inf(1, num_Nodes);
	
	% randomly select a node
	if nargin == 5
		% no initial node chosen, generate a random node
		curr_node = randi(num_Nodes);
	else
		% initial node chosen, use it
		curr_node = ini_Node;
	end
	
	% assign all tasks to the current node
	mat_Assgn(curr_node, :) = ones(1, num_Tasks);
	
	% we are including current node in the neighbours set
	con_Commn = con_Commn + 1;

	% #	
	if verbose
	fprintf('\n +-----------------+');
	fprintf('\n | EVDAA ALGORITHM |');
	fprintf('\n +-----------------+\n\n');
	fprintf('\nCommunication Matrix:\n\n');
	disp(mat_Commn);
	fprintf('\nCosts Matrix:\n\n');
	disp(mat_Costs);
	fprintf('\nCapacity Constraint:\n\n');
	disp(con_Capty);
	fprintf('\nCommunication Constraint:\n\n');
	disp(con_Commn);
	fprintf('\nMaximum Number of Iterations:\n\n');
	disp(MAX_ITER);
	end
	
	% check zero-columns in mat_Costs
	for j = 1:num_Tasks
		if isequal( mat_Costs(:,j), zeros(num_Nodes,1) )
			mat_Assgn = zeros(num_Nodes, num_Tasks);
			fprintf('\nZero-column in Costs Matrix. No solution.\n\n');
			return;
		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN LOOP
	
	% start loop
	for T = 1:MAX_ITER

		%#
		if verbose
		fprintf('\n[###] TIME:\n\n')
		disp(T);
		fprintf('\n[%d] Current Node:\n\n', T);
		disp(curr_node);
		fprintf('\n[%d] Current Assignment:\n\n', T);
		disp(mat_Assgn);
		fprintf('\n[%d] Maximum Load Vector\n\n', T);
		disp(prev_loadmax);
		fprintf('\n[%d] Total Load Vector\n\n', T);
		disp(prev_loadtot);
		end	

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% CALCULATE SUB-SETs

		% initialize neighbours sets
		curr_neighbours = [curr_node];

		% calculate set of neighbours looking in the communication matrix
		for i = 1:num_Nodes
			if ( mat_Commn(curr_node, i) == 1 )
				curr_neighbours = [curr_neighbours i];
			end
		end
		curr_neighbours = sort(curr_neighbours);

		%#
		if verbose
		fprintf('\n[%d] Current Neighbours Set [Effective]:\n\n', T);
		disp(curr_neighbours);
		end
		
		% initialize limited neighbours set
		limt_neighbours = [curr_node];
		
		% randomly limit neighbours number according to con_Commn
		while size(limt_neighbours, 2) < min( [con_Commn size(curr_neighbours,2)] )
			
			% extract a node from current neighbours 
			tmp_node = curr_neighbours( randi([1 size(curr_neighbours, 2)]) );
			
			% if the node is not in the limited neighbours set
			if ~ismember(tmp_node, limt_neighbours)
				
				% add it
				limt_neighbours = [limt_neighbours tmp_node];
			end
		end
		limt_neighbours = sort(limt_neighbours);
		
		% replace curr_neighbours with limt_neighbours
		curr_neighbours = limt_neighbours;

		%#
		if verbose
		fprintf('\n[%d] Current Neighbours Set [Limited]:\n\n', T);
		disp(curr_neighbours);
		end
		
		%initialize current tasks subset
		curr_tasks = [];

		% calculate set of tasks looking in the assignment matrix
		for i = curr_neighbours
			for j = 1:num_Tasks
				if ( mat_Assgn(i, j) == 1 )
					curr_tasks = [curr_tasks j];
				end
			end
		end
		
		% sort current task list
		curr_tasks = sort(curr_tasks);

		%#
		if verbose
		fprintf('\n[%d] Current Tasks Set:\n\n', T);
		disp(curr_tasks);
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% EXTRACT SUB-MATRIXES

		% extract costs submatrix for tasks and nodes in the neighbourhood
		sub_costs = mat_Costs(curr_neighbours, curr_tasks);

		% extract assignems submatrix for nodes in the neighbourhood
		sub_assgn = mat_Assgn(curr_neighbours, curr_tasks);

		% extract communication submatrix for nodes in the neighbourhood
		sub_commn = mat_Commn(curr_neighbours, curr_neighbours);

		%#
		if verbose
		fprintf('\n[%d] Costs Sub Matrix:\n\n', T);
		disp(sub_costs);
		fprintf('\n[%d] Assignments Sub Matrix:\n\n', T);
		disp(sub_assgn);
		fprintf('\n[%d] Communication Sub Matrix:\n\n', T);
		disp(sub_commn);
		end
		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% CHECK SUB-MATRIXES SIZE
		
		if size(curr_tasks, 2) == 0
			
			%#
			if verbose
			fprintf('\n[%d] Zero-sized sub-matrixes: Skip Iteration', T);
			end
		else
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% CHECK ASSIGNMENT MATRIX
		
			%#
			if verbose
			fprintf('\n[%d] Checking if Assignment is feasible...\n\n', T);
			end

			% check if previous assignment is feasible
			if evdaa_isfeasibleassgn(sub_commn, sub_costs, con_Capty, sub_assgn)
			
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% FEASIBLE ASSIGMENT -> SOLVE PRIMARY PROBLEM
			
				%#
				if verbose
				fprintf('\n[%d] Solving Primary Problem...\n\n', T);
				end
	
				[new_assgn new_loadmax new_loadtot aborted] = ...
				evdaa_solver(sub_commn, sub_costs, con_Capty, sub_assgn, 1);
		
				% if new maximum local load is less than the previous
				if new_loadmax < prev_loadmax(curr_node)
				
					% use new assignment
					mat_Assgn(curr_neighbours, curr_tasks) = new_assgn;
				
					% set maximum local load
					prev_loadmax(curr_node) = new_loadmax;
				
					% set total local load
					prev_loadtot(curr_node) = new_loadtot;

					%#
					if verbose
					fprintf('\n[%d] Swap? Y: Max Local Load Decreased\n\n', T);
					fprintf('\n[%d] New Assignments Sub Matrix:\n\n', T);
					disp(new_assgn);
					end
	
				% if new maximum local load is equal to the previous, but
				% the new total local load is less than the previous
				elseif ...
				new_loadmax == prev_loadmax(curr_node) && ...
				new_loadtot <  prev_loadtot(curr_node)

					% use new assignment
					mat_Assgn(curr_neighbours, curr_tasks) = new_assgn;
				
					% set maximum local load
					prev_loadmax(curr_node) = new_loadmax;
				
					% set total local load
					prev_loadtot(curr_node) = new_loadtot;
				
					%#
					if verbose
					fprintf('\n[%d] Swap? Y: Tot Local Load Decreased\n\n', T);
					fprintf('\n[%d] New Assignments Sub Matrix:\n\n', T);
					disp(new_assgn);
					end

				else
					%#
					if verbose
					fprintf('\n[%d] Swap? N: Max Local Load Increased\n\n', T);
					end
				end
			
			else
		
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				% UNFEASIBLE ASSIGNMENT -> TRY SOLVING PRIMARY PROBLEM
			
				%#
				if verbose
				fprintf('\n[%d] Trying Primary Problem...\n\n', T);
				end
				
				% start solver
				[new_assgn new_loadmax new_loadtot new_feasb] = ...
				evdaa_solver(sub_commn, sub_costs, con_Capty, sub_assgn, 1);
		
				% check feasibile problem
				if new_feasb
				
					%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					% FEASIBLE -> UPDATE VALUES
			
					%#
					if verbose
					fprintf('\n[%d] Feasible\n\n', T);
					end
	
					% if new maximum local load is less than the previous
					if new_loadmax < prev_loadmax(curr_node)
				
						% use new assignment
						mat_Assgn(curr_neighbours, curr_tasks) = new_assgn;
				
						% set maximum local load
						prev_loadmax(curr_node) = new_loadmax;
				
						% set total local load
						prev_loadtot(curr_node) = new_loadtot;

						%#
						if verbose
						fprintf('\n[%d] Swap? Y: Max Local Load Decreased\n\n', T);
						fprintf('\n[%d] New Assignments Sub Matrix:\n\n', T);
						disp(new_assgn);
						end
	
					% if new maximum local load is equal to the previous, but
					% the new total local load is less than the previous
					elseif ...
					new_loadmax == prev_loadmax(curr_node) && ...
					new_loadtot <  prev_loadtot(curr_node)

						% use new assignment
						mat_Assgn(curr_neighbours, curr_tasks) = new_assgn;
				
						% set maximum local load
						prev_loadmax(curr_node) = new_loadmax;
				
						% set total local load
						prev_loadtot(curr_node) = new_loadtot;
				
						%#
						if verbose
						fprintf('\n[%d] Swap? Y: Tot Local Load Decreased\n\n', T);
						fprintf('\n[%d] New Assignments Sub Matrix:\n\n', T);
						disp(new_assgn);
						end

					else
						%#
						if verbose
						fprintf('\n[%d] Swap? N: Max Local Load Increased\n\n', T);
						end
					end

				else
				
					%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
					% UNFEASIBLE -> SOLVE SECONDARY PROBLEM
			
					%#
					if verbose
					fprintf('\n[%d] Unfeasible, Solving Secondary Problem...\n\n', T);
					end
	
					[new_assgn new_loadmax new_loadtot aborted] = ...
					evdaa_solver(sub_commn, sub_costs, con_Capty, sub_assgn, 2);
				
					% use new assignment
					mat_Assgn(curr_neighbours, curr_tasks) = new_assgn;
				
					% set maximum local load
					prev_loadmax(curr_node) = new_loadmax;
				
					% set total local load
					prev_loadtot(curr_node) = new_loadtot;				
				
					%#
					if verbose
					fprintf('\n[%d] Swap? Y;\n\n', T);
					fprintf('\n[%d] New Assignments Sub Matrix:\n\n', T);
					disp(new_assgn);
					end

				end

			end 

		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% NEW NODE
		
		curr_node = randi(num_Nodes);
				
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CALCULATE OBJECTIVE FUNCTION VALUE

	% initialize vector
	components = [];

	% calculate components
	for i = 1:num_Nodes		
		components(i) = mat_Costs(i,:) * mat_Assgn(i,:)';
	end

	% calculate infinity-norm
	objective_function_value = max(components);

	%#
	if verbose
	fprintf('\n[END] Objective Function Value:\n\n');
	disp(objective_function_value);
	fprintf('\n[END] Final Assignment:\n\n');
	disp(mat_Assgn);
	end
	
end

