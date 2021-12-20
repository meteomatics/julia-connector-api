# julia-connector-api

## installation 
In a Julia REPL hit the `]` key to enter Package Manager mode. Then type `add https://github.com/meteomatics/julia-connector-api`.
Alternatively, in a Julia script or REPL, type `using Pkg` to import the Package Manager module. Then execute `Pkg.add(url="https://github.com/meteomatics/julia-connector-api").

## usage
Import the module by executing `using MeteomaticsAPI`. The `querygrid`, `querytimeseries`, `queryinitdatetime` and `querytimeranges` functions should all now be available to you. To read the docstrings for any of these, enter help mode by typing `?`, then enter the name of the function you want help on. If you want to see the possible implementations of a function (including the arguments and their expected data types) execute `methods(<function>)`.
