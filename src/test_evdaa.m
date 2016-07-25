clear; 
clc;

% type "help evdaa" or "help evdaa_random" in matlab for info

delete('test_evdaa.txt');
diary ('test_evdaa.txt');

% run NUM_TEST evdaa tests
NUM_TEST = 10;

% maximum number of iterations for each evdaa test
MAX_ITER = 50;

% configuration for random generator 
cfg_nodes_min = 3;
cfg_nodes_max = 8;
cfg_tasks_min = 3;
cfg_tasks_max = 10;
cfg_const_add = 2;
cfg_costs_min = -10;
cfg_costs_max = 15;
cfg_commn_min = 2;
cfg_commn_max = 5;
cfg_commn_pro = .30;

tic
for i = 1:NUM_TEST

	fprintf('\n @ TEST: %d of %d\n\n', i, NUM_TEST);

	% generate random maxtrixes	
	[mat_Commn, mat_Costs, con_Capty, con_Commn] = evdaa_random ...
		(cfg_nodes_min, cfg_nodes_max, cfg_tasks_min, cfg_tasks_max, ...
		 cfg_const_add, cfg_costs_min, cfg_costs_max, ...
		 cfg_commn_min, cfg_commn_max, cfg_commn_pro);
	
	% solve random problem using evdaa
	evdaa(mat_Commn, mat_Costs, con_Capty, con_Commn, MAX_ITER)

end
toc

diary off;

