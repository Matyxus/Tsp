<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <h3 align="center">Traveling Salesman Problem</h3>

  <p align="center">
    HW 1 of Evolutionary Optimization Algorithms (EOA).
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#packages">Packages</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
   <li>
      <a href="#algorithms">Algorithms</a>
    </li>
    <li>
      <a href="#usage">Usage</a>
      <ul>
        <li><a href="#description">Description</a></li>
        <li><a href="#example">Example</a></li>
        <li><a href="#visualization">Visualization</a></li>
      </ul>
    </li>
  </ol>
</details>


<!-- ABOUT THE PROJECT -->
## About The Project

This project is the implementation of first homework: https://cw.fel.cvut.cz/wiki/courses/a0m33eoa/start and <a href="#example">example</a> of how to use the project
is provided.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these example steps,
program was made for [Julia 1.9](https://julialang.org/).

### Packages

1) [GLMakie](https://docs.makie.org/stable/)
2) [JSON](https://github.com/JuliaIO/JSON.jl)
3) [Plots](https://docs.juliaplots.org/latest/) 
4) [Random](https://docs.julialang.org/en/v1/stdlib/Random/) 
5) [TSPLIB](https://github.com/matago/TSPLIB.jl) 

### Installation

Use [Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/) to install project from GitHub.
```julia
(env) pkg> add https://github.com/Matyxus/Tsp
```
<p align="right">(<a href="#top">back to top</a>)</p>

<!-- Scenario -->
## Algorithms
Short description of algorithms implemented for solving TSP, details can be found
in their individual julia files:

<details>
  <summary>SimulatedAnnealing</summary>
  SimulatedAnnealing is probabilist local search algorithm, which starts by initializing solution. In the next steps it is randomly changed by one of the mutation operators. New solution is compared against the best one and based on
  probability it is replaced.
</details>

<details>
  <summary>GeneticAlgorithm</summary>
  Classical implementation of genetic algorithms, where we first initialize 
  the population by the given method, then use one of the crossover operators to
  generate new population. Afterwards one of the mutation operators is used to 
  randomly change individuals. Elitism is used to perserve the best solutions
  throughout the evolution of population.
</details>

<details>
  <summary>CompleteEnumeration</summary>
  CompleteEnumration is brute force solution, which generates all the permutations.
  As helping heurestic to reduce the search space distance of the best solution is
  kept, and compared at all steps when the permutation is being generated.
</details>

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage
To use the project, run the following command:
```julia
using Tsp
config_name::String = "ga"
problem_name::String = "att48"
log_name::String = "result"
gui::Bool = false
main(config_name, problem_name, log_name, gui)
```

### Description
Function which is used to run the project is callo "main", it requires the following arguments:
1) config name: name of the configuration file defined in [tsp/data/config](https://github.com/Matyxus/Tsp/tree/main/data/config)
2) problem name: name of the TSP problem, the ones in project are listed [here](https://github.com/matago/TSPLIB.jl/tree/master/data/TSPLIB95/tsp), otherwise downloaded TSP problem files can be put inside tsp/data/problems directory.
3) log name: (optional, default empty), name of file in which we want to save the results. (Empty for no file), will be saved by default in: tsp/data/logs
4) gui: (optinal, default false) boolean value, if GUI should be used.

### Example
Configuration files contain information about the algorithms, these configuration files should not be modified (by adding, removing values from the JSON file), only names of certain parameters can be changed, for example:
```julia
{   
    # Here we define the seed for algorithm (to be reproducible),
    # and maximum number of iterations (for GUI this option is ignored)
    "settings" : {
        "seed": 42,
        "max_iter": 30000
    },
    # This section defined the algorithm and its parameters
    "algorithm": {
        # Name of the algorithm we want to use
        "name": "SimulatedAnnealing",
        # Representation of TSP
        "representation": "Sequence",
        # Parameters of algorithm
        "params": {
            "temperature": 10000,
            "cooling_rate": 0.0003,
            # Initialization function
            "init": "random",
            # Mutation operator
            "mutation": {
                "name": "psm",
                "chance": 1.0
            }
        }
    },
    # This is optinal setting, it is not needed in the configuration file,
    # GUI has default values (1280, 800).
    "gui" : {
        "width": 1920,
        "height": 1080
    },
}
```

### Visualization
There are two types of visualization provided for this work,
first one being [static](https://github.com/Matyxus/Tsp/blob/main/src/Vizualization.jl), where we can visualize results of algorithms runs:
```julia
using Tsp
log_name::String = "result"
plot_solution(log_name)
```
Or we can visualize how algorithms performed over the entire run: 
```julia
using Tsp
log_name::String = "result"
plot_convergence(log_name)

```

```julia
using Tsp
# (If we use multiple, they must be on the same TSP problem)
log_names::Vector{String} = ["result", "result2"]
plot_convergence(log_names)
```

Second one being [dynamic](https://github.com/Matyxus/Tsp/blob/main/src/Gui.jl)
with GUI:
```julia
using Tsp
config_name::String = "ga"
problem_name::String = "att48"
log_name::String = "result"
gui::Bool = true
main(config_name, problem_name, log_name, gui)
```

<p align="right">(<a href="#top">back to top</a>)</p>
