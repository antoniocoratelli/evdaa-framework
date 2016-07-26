# evdaa-framework
MATLAB framework for distributed load balancing problems simulation.
Based on the [*EVDAA* algorithm][3].

The algorithm solves a multi-agent assignment problem,
in which a group of agents has to reach a consensus on an optimal
distribution of tasks, under communication and assignment constraints,
minimizing the maximum load assigned to each agent.

## Install
- Download the [zip file][1] of the source code
- Extract the zip file to `<some-path>`
- Add `<some-path>/evdaa-framework/src` to the [MATLAB Search Path][2]
- Use `help evdaa` or `help <any-evdaa-function>` in MATLAB to show the
  usage of any function in the framework.

## License
Copyright (c) 2013, Antonio Coratelli.
Released under BSD 3-Clause License. See 'LICENSE' file.

> This software includes [GLPKMEX][4] binaries. GLPKMEX is a MATLAB MEX
> interface for the [GLPK][5] library, which is a set of routines intended
> for solving linear programming (LP), mixed integer programming (MIP),
> and other related problems.
> GLPKMEX and GLPK are released under GPLv2 License, thus a copy of source
> code and license of GLPKMEX is provided in `glpkmex-2.11-src.zip`.

[1]: https://github.com/antoniocoratelli/evdaa-framework/archive/master.zip
[2]: http://mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html
[3]: http://ieeexplore.ieee.org/xpl/articleDetails.jsp?arnumber=6760177
[4]: https://sourceforge.net/projects/glpkmex/
[5]: https://www.gnu.org/software/glpk/glpk.html
