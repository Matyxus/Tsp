import TSPLIB
# Super type of all algorithms
abstract type Alg{T <: Representation} end
#  ----------------------- Getters ----------------------- 
get_params(alg::Alg)::Dict = alg.params 
get_tsp(alg::Alg)::TSP = alg.tsp
get_representation(alg::Alg)::Type{T} where {T <: Representation} = alg.representation
get_alg_sliders(::Alg)::Dict = throw(ArgumentError("All subtypes of 'Alg' must define method 'get_alg_sliders' !"))
#  -----------------------  Functions, defined for all Algorithms ----------------------- 
"""
    initialize(::Type{Alg}, params::Dict, tsp::TSP)::Union{Nothing, Alg}

    Main function for initializing algorithms from configuration file.

# Arguments
- `::Type{Alg}`: the type of algorithm
- `params::Dict`: parameters of algorithm
- `tsp::TSP`: structure representing tsp problem

`Returns` Algorithm instance if successfull, nothing otherwise
"""
initialize(::Type{Alg}, params::Dict, tsp::TSP)::Union{Nothing, Alg} = throw(ArgumentError("All subtypes of 'Alg' must define method 'initialize' !"))
is_running(::Alg)::Bool = throw(ArgumentError("All subtypes of 'Alg' must define method 'is_running' !"))
step(::Alg)::Union{Representation, Nothing} = throw(ArgumentError("All subtypes of 'Alg' must define method 'step' !"))
update_params(::Alg, params::Dict{String, Union{Int64, Float64}})::Nothing = throw(ArgumentError("All subtypes of 'Alg' must define method 'update_params' !"))
# ----------------------- Parameters ----------------------- 
# Utils, checks for basic parameters in algorithm
check_params(::Type{Alg}, params::Dict)::Bool = throw(ArgumentError("All subtypes of 'Alg' must define method 'check_algorithm' !"))

# Checks the based definition of algorithm in configuration file
function check_algorithm(params::Dict)::Bool
    if !check_key(params, "name")
        return false
    elseif !check_key(params, "representation")
        return false
    elseif !check_key(params, "params", Dict)
        return false
    end
    return true
end

# ------------------- LocalSearch ------------------- 
abstract type LocalSearch{T} <: Alg{T} end
get_perturbation(alg::LocalSearch)::Function = alg.perturbation
get_solution(alg::LocalSearch)::Union{Representation, Nothing} = alg.solution
get_initializer(alg::LocalSearch)::Function = alg.initialization
# ------------------- GeneticAlgorithm ------------------- 
abstract type EvolutionaryAlgorithm{T} <: Alg{T} end
get_mutation(alg::EvolutionaryAlgorithm)::Function = alg.mutation
get_crossover(alg::EvolutionaryAlgorithm)::Function = alg.crossover
