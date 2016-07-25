function [value] = evdaa_iscoherent (mat_Commn, mat_Costs, con_Capty, mat_Assgn)
%.
% function:	
%
%    check if supplied matrixes could represent a Discrete Consensus Problem
%
% arguments:
%
%    mat_Commn = communication matrix
%    mat_Costs = task costs matrix
%    con_Capty = capacity constraint
%    mat_Assgn = assignment matrix [optional: default value = matrix of 0s]
%
% returns:	
%
%    value = if data is coherent: true, otherwise: false
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

	if (nargin < 3)
		error('mat_Commn, mat_Costs and con_Capty are required arguments');
	end
	
	% calculate number of nodes and number of tasks from costs matrix
	[num_Nodes num_Tasks] = size(mat_Costs);
	
	% if blank mat_Assgn creates a default matrix of 0s
	if (nargin == 3)
		mat_Assgn = zeros(num_Nodes, num_Tasks);
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK MATRIX SIZES

	% initialize return value
	value = true;
	
	% check communication matrix size
	if ~isequal( [num_Nodes num_Nodes], size(mat_Commn) )
		%#
		if verbose
		fprintf('\nmat_Commn and mat_Costs sizes are incoherent\n\n');
		end
		value = false; return;
	end
	
	% check assignment matrix size
	if ~isequal( [num_Nodes num_Tasks], size(mat_Assgn) )
		%#
		if verbose
		fprintf('\nmat_Assgn and mat_Costs sizes are incoherent\n\n');
		end
		value = false; return;
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK COMMUNICATION MATRIX
	
	% check communication matrix elements
	for i = 1:num_Nodes
	
		% check diagonal
		if ( mat_Commn(i,i) ~= 0 )
			%#
			if verbose
			fprintf('\nmat_Commn must have 0s on the diagonal\n\n');
			end
			value = false; return;
		end
		
		for j = 1:num_Nodes
		
			% check binary matrix
			if ( mat_Commn(i,j) ~= 0 && mat_Commn(i,j) ~= 1 )
				%#
				if verbose
				fprintf('\nmat_Commn must be a binary matrix\n\n');
				end
				value = false; return;
			end
			
			% check symmetrical matrix
			if ( mat_Commn(i,j) ~= mat_Commn(j,i) )
				%#
				if verbose
				fprintf('\nmat_Commn must be a symmetrical matrix\n\n');
				end
				value = false; return;
			end
		end
		
	end
	
	% check communication matrix connected
	connected = zeros(num_Nodes, num_Nodes);
	for i = 1: num_Nodes
		connected = connected + mat_Commn^i;
	end
	for i = 1:num_Nodes
		for j = 1:num_Nodes
			if connected(i,j) == 0
				%#
				if verbose
				fprintf('\nmat_Commn graph must be connected\n\n'); 
				end
				value = false; return;
			end
		end
	end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK ASSIGNMENT MATRIX
	
	% check assignment matrix elements
	for i = 1:num_Nodes
		for j = 1:num_Tasks
		
			% check binary matrix
			if ( mat_Assgn(i,j) ~= 0 && mat_Assgn(i,j) ~= 1 )
				%#
				if verbose
				fprintf('\nmat_Assgn must be a binary matrix\n\n');
				end
				value = false; return;
			end
		end
	end
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK COSTS MATRIX
	
	% check task costs matrix elements
	for i = 1:num_Nodes
		for j = 1:num_Tasks
		
			% check positive values
			if ( mat_Costs(i,j) < 0 )
				%#
				if verbose
				fprintf('\nmat_Costs can''t have negative values\n\n');
				end
				value = false; return;
				
			% check integer values
			elseif mod(mat_Costs(i,j), 1) ~= 0
				%#
				if verbose
				fprintf('\nmat_Costs must have integer values\n\n');
				end
				value = false; return;
			end
			
		end
	end

end
