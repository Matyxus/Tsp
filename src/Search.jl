import TSPLIB
# Super type of all algorithms
abstract type Alg{T <: Representation} end
#  ----------------------- Getters ----------------------- 
get_params(alg::Alg)::Dict = alg.params 
get_tsp(alg::Alg)::TSPLIB.TSP = alg.tsp
get_representation(alg::Alg)::Type{T} where {T <: Representation} = alg.representation
#  -----------------------  Functions, defined for all Algorithms ----------------------- 
initialize(::Type{Alg}, params::Dict, tsp::TSPLIB.TSP)::Union{Alg, Nothing} = throw(ArgumentError("All subtypes of 'Alg' must define method 'initialize' !"))
is_running(::Alg)::Bool = throw(ArgumentError("All subtypes of 'Alg' must define method 'is_running' !"))
step(::Alg)::Union{Representation, Nothing} = throw(ArgumentError("All subtypes of 'Alg' must define method 'step' !"))
# ----------------------- Parameters ----------------------- 
# Utils, checks for basic parameters in algorithm
check_params(::Type{Alg}, params::Dict)::Bool = throw(ArgumentError("All subtypes of 'Alg' must define method 'check_algorithm' !"))

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

# ----------------------- Utils ----------------------- 
Base.show(::Alg)::Nothing = throw(ArgumentError("All subtypes of 'Alg' must define method 'Base.show' !"))


# check_field(alg::Alg, member::Symbol)::Bool = hasfield(typeof(alg), member) ? true : missing_field(alg, member)
# check_alg(alg::Alg)::Bool = all([check_field(alg, member) for member in [:params, :log, :tsp]])

# ------------------- LocalSearch ------------------- 
abstract type LocalSearch{T} <: Alg{T} end
get_perturbation(alg::LocalSearch)::Function = alg.perturbation
get_solution(alg::LocalSearch)::Union{Representation, Nothing} = alg.solution
get_initializer(alg::LocalSearch)::Function = alg.initialization
# ------------------- GeneticAlgorithm ------------------- 
abstract type EvolutionaryAlgorithm{T} <: Alg{T} end
get_mutation(alg::EvolutionaryAlgorithm)::Function = alg.mutation
get_crossover(alg::EvolutionaryAlgorithm)::Function = alg.crossover
# ------------------- MemeticAlgorithm if initializer is not random ------------------- 
get_initializer(alg::EvolutionaryAlgorithm)::Function = alg.initialization
# ------------------- HeuresticAlgorithm ------------------- 
# abstract type HeuresticAlgorithm{T} <: Alg{T} end


export Alg, LocalSearch, EvolutionaryAlgorithm # , HeuresticAlgorithm
export initialize, get_initializer, get_params, get_tsp, is_running, step, check_algorithm





