function [new_Assgn new_LoadM new_LoadT new_Feasb] = evdaa_solver ...
(mat_Commn, mat_Costs, con_Capty, mat_Assgn, PRB)
%.
%	function:	
%
%    solve [primary/secondary] Local-ILP problem
%
%	arguments:
%
%    mat_Commn = communication matrix (only for coherence-check)
%    mat_Costs = tasks costs matrix
%    con_Capty = capacity constraint
%    mat_Assgn = previous assignment matrix
%    PRB       = 1 solve primary, 2 solve secondary
%
%	returns:
%
%    new_Assgn = new assignment matrix
%    new_LoadM = new maximum local load
%    new_LoadT = new total local load
%    new_Feasb = true if feasible solution 
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
		error('mat_Commn, mat_Costs, con_Capty, mat_Assgn, PRB are required');
	end
	
	% check PRB
	if ( PRB ~= 1 && PRB ~= 2 )
		error('PRB can be only 1 or 2');
	end

	% kind of optimization: 
	%   1 minimize
	%  -1 maximize
	s = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NUMBER OF VARIABLES IN THE PROBLEM

	% calculate number of nodes and number of tasks from costs matrix
	[num_Nodes num_Tasks] = size(mat_Costs);
	
	% set default assignment
	new_Assgn = mat_Assgn;

	% set default maximum local load
	new_LoadM = inf;
	
	% set default total local load
	new_LoadT = inf;		

	% number of variables in the problem is:
	num_variables = num_Nodes * num_Tasks + 1;
	
	% select a dummy node for secondary problem
	if PRB == 2 
		dummy_node = randi( [1 num_Nodes] );
		%#
		if verbose
		fprintf('\nDummy Node: %d\n\n', dummy_node);
		end
	end
	
	% create the vartype 
	% - 'I' integer
	% - 'C' continue
	% - 'B' binary
	vartype(1:num_variables-1, 1) = 'B';
	vartype(    num_variables, 1) = 'I';
	
	% bounds
	lb(1:num_variables,1) = 0;
	ub(1:num_variables,1) = inf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUILD CONSTRAINT MATRIXES

	% - ctype(i) = 'F'  Free (unbounded) variable
	% - ctype(i) = 'U'  "<=" Variable with upper bound
	% - ctype(i) = 'S'  "="  Fixed Variable
	% - ctype(i) = 'L'  ">=" Variable with lower bound
	% - ctype(i) = 'D'  Double-bounded variable 'U'   'S'   

	% calculate number of constraints
	num_constraints = num_Tasks + 3*num_Nodes;
	
	% preallocate matrixes and vectors
	a 		= zeros(num_constraints, num_variables);
	b 		= zeros(num_constraints, 1);
	c 		= zeros(num_variables, 1);
	ctype	=  char(num_variables, 1);

	% one node for each task
	% - sum of all elements in all Assignment matrix columns must be 1
	% --- in the secondary problem it can be 
	% --- 1 if the task is assigned to some node in the sub-problem, else 0
	for i = 1:num_Tasks

		% right-hand side values
		if PRB == 1
			b(i) = 1;
		elseif PRB == 2
			b(i) = sum( mat_Assgn(:,i) );
		end

		% constraint type
		ctype(i) = 'S';

		% coefficients
		for j = 1:num_Nodes
			a(i, i + (j-1)*num_Tasks ) = 1;			
		end

	end
	
	% capacity constraint
	% - sum of all elements in all Assignment matrix rows must be
	%   less than capacity constraint
	for i = num_Tasks+1:num_Tasks+num_Nodes
		
		% right-hand side values
		b(i) = con_Capty;

		% if secondary problem relax capacity constraint 
		% for the dummy node
		if PRB == 2 && (i-num_Tasks) == dummy_node
			b(i) = inf;
		end		
		
		% constraint type
		ctype(i) = 'U';

		% coefficients
		for j = 1:num_Tasks
			a(i, j + num_Tasks*(i-num_Tasks-1) ) = 1;
		end

	end

	% performable assignment
	for i = num_Tasks+num_Nodes+1:num_Tasks+2*num_Nodes
		
		% right-hand side values
		b(i) = 0;

		% constraint type
		ctype(i, 1) = 'S';
		
		% if secondary problem relax performable assignment constraint 
		% for the dummy node
		if PRB == 2 && (i-num_Tasks-num_Nodes) == dummy_node
			continue;
		end
				
		% coefficients
		for j = 1:num_Tasks
			if mat_Costs(i-num_Tasks-num_Nodes, j) == 0
				a(i, j + num_Tasks*(i-num_Tasks-num_Nodes-1) ) = 1;
			else
				a(i, j + num_Tasks*(i-num_Tasks-num_Nodes-1) ) = 0;
			end
		end

	end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
% BUILD OBJECTIVE FUNCTION
	
	% objective function workaround with auxiliary var 
	% for infinity-norm minimization 
	for i = num_Tasks+2*num_Nodes+1:num_constraints
		
		% right-hand side values
		b(i) = 0;
		
		% constraint type
		ctype(i) = 'U';
		
		% coefficients
		% calculate objective function Fi
		if PRB == 1
			for j = 1:num_Tasks
				a(i, j+(i-1-num_Tasks-2*num_Nodes)*num_Tasks) = ...
					mat_Costs(i-num_Tasks-2*num_Nodes, j);
			end
		elseif PRB == 2
			for j = 1:num_Tasks
				a(i, j+(i-1-num_Tasks-2*num_Nodes)*num_Tasks) = 1;
			end
		end
		a(i, num_variables) = -1;
		
	end

	% build objective function vector 
	c(num_variables) = 1;
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USE GLPK SOLVER	
	
	param.scale = 0;
	param.lpsolver = 1;
	param.itcnt = 1;
	param.save = 0;
	
	% solve lp problem
	[xopt fopt status extra] = glpk(c, a, b, lb, ub, ctype, vartype, s, param);
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANALYZE RESULTS
	
	% build assignment matrix
	new_Assgn = vec2mat( xopt(1:num_variables-1), num_Tasks );
	
	% primary problem
	if PRB == 1
		
		% set maximum local load
		new_LoadM = fopt;
		
		% calculate total local load
		new_LoadT = sum(mat_Costs(:) .* new_Assgn(:));
	
	% secodary problem
	elseif PRB == 2
		
		% set maximum local load
		new_LoadM = inf;
		
		% set total local load
		new_LoadT = inf;
	end
	
	if status ~= 5
		% no solution found: set flag
		new_Feasb = false;
		new_LoadM = inf;
		new_LoadT = inf;
	else
		% solution flag: set flag
		new_Feasb = true;
	end
	
end

