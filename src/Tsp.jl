# using Revise

module Tsp
#
include("Constants.jl")
include("Loader.jl")
# TypeDefs of Representation
include("Representation.jl")
include("Log.jl")
# --------- Functions --------- 
include("Initializations.jl")
include("Mutation.jl")
include("Crossover.jl")
# --------- Algorithms --------- 
include("Search.jl")  # Defintion of Structure's, functions for all algorithms
include("SimulatedAnnealing.jl")
include("GeneticAlgorithm.jl")
include("CompleteEnumeration.jl")
# --------- Main functin --------- 
include("Main.jl")

function main(config::String, problem::String, log_name::String = "", gui::Bool = false)::Bool
    println("Main function, got config: $(config), problem: $(problem), log: '$(log_name)', gui: $(gui)")
    solver::Union{Solver, Nothing} = process_config(load_config(config), problem)
    println("Successfully initialized solver -> $(!isnothing(solver))!")
    if isnothing(solver)
        return false
    end
    run_time = @elapsed standard_run(solver)
    println("Run time: $(run_time)")
    if !isempty(log_name)
        save_result(log_name, prepare_data(solver, run_time))
    end
    return true
end

export main

end


