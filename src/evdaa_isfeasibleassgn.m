function [value] = evdaa_isfeasibleassgn ...
(mat_Commn, mat_Costs, con_Capty, mat_Assgn)
%.
% function:	
%
%    checks if a given assignment matrix is feasible in a
%    Discrete Consensus Problem
%
% arguments:
%
%    mat_Commn = communication matrix
%    mat_Costs = task costs matrix
%    con_Capty = capacity constraint
%    mat_Assgn = assignment matrix
%
% returns:
%
%    value = if the assignment is feasible: true, otherwise: false
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
	if (nargin < 4)
		error('mat_Commn, mat_Costs, con_Capty and mat_Assgn are required');
	end
	
	% initialize return value
	value = true;

	% check coherence of supplied matrixes
	if ~evdaa_iscoherent(mat_Commn, mat_Costs, con_Capty, mat_Assgn)
		%#
		if verbose
		fprintf('\nincoherent arguments\n\n');
		end
		value = false; return;
	end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK IF ASSIGNMENT IS FEASIBLE
	
	% calculates number of nodes and number of tasks from costs matrix
	[num_Nodes num_Tasks] = size(mat_Costs);
	
	% check if each task is assigned to one node only
	for j = 1:num_Tasks
		% sum all elements in a column
		if ( sum( mat_Assgn(:, j) ) ~= 1 )
			%#
			if verbose
			fprintf('\neach task must be assigned to one node exacly: ');
			fprintf('mat_Assgn(:,%d)\n\n', j);
			end
			value = false; return;
		end
	end
	
	% check if all nodes can perform their assignments
	for i = 1:num_Nodes
		for j = 1:num_Tasks
			if( mat_Assgn(i,j) == 1 && mat_Costs(i,j) == 0)
				%#
				if verbose
				fprintf('\ninvalid assignment: ');
				fprintf('mat_Assgn(%d,%d)\n\n',i,j);
				end
				value = false; return;
			end
		end
	end
	
	% check capacity constraint
	for i = 1:num_Nodes
		% sum elements in each row
		if ( sum( mat_Assgn(i, :) )  > con_Capty )
			%#
			if verbose
			fprintf('\ncapacity constraint broken: ');
			fprintf('mat_Assgn(%d,:)\n\n', i);
			end
			value = false; return;
		end	
	end
	
end

