import Random.seed!
import Dates: format, now

"""
    Solver(config::Union{Dict, String}, problem::String)::Union{Solver, Nothing}

    Initializes Solver structure, holding all neccessarry variables needed to
    solve the TSP.

# Arguments
- `config::Union{Dict, String}`: name of configuration file or loaded configuration
- `problem::String`: name of the TSP problem

`Returns` Solver structure if succesfully loaded, Nothing otherwise.
"""
mutable struct Solver
    config::Dict
    alg::Alg
    log::Log
    iteration::Int64
    Solver(config::Dict, alg::Alg)::Solver = new(config, alg, Log(), 0)
end

function Solver(config::Union{Dict, String}, problem::String)::Union{Solver, Nothing}
    println("Initializing solver for problem: $(problem), processing configuration file ...")
    config::Dict = isa(config, Dict) ? config : load_config(config)
    # Failed to load
    if isnothing(config) || isempty(config)
        println("Invalid configuration file!")
        return nothing
    end
    # Load TSP
    tsp::Union{TSPLIB.TSP, Nothing} = intialize_problem(config, problem)
    if isnothing(tsp)
        return nothing
    end
    # Load algorithm
    alg::Union{Alg, Nothing} = intialize_algorithm(config, tsp)
    if isnothing(alg)
        return nothing
    end
    return Solver(config, alg)
end

# ----------------------------- Init functions ----------------------------- 

# Load the TSP problem, while checing 'settings' in configuration file
function intialize_problem(config::Dict, problem::String)::Union{TSPLIB.TSP, Nothing}
    # Check
    if !check_settings(config)
        return nothing
    end
    seed!(config["settings"]["seed"])
    return load_problem(problem)
end

# Initializes the given algorithm from configuration
function intialize_algorithm(config::Dict, tsp::TSPLIB.TSP)::Union{Nothing, Alg}
    # Check
    if !check_key(config, "algorithm", Dict)
        return nothing
    end
    # All algorithms
    known_algorithms::Dict{String, Any} = Dict{String, Any}(
        "CompleteEnumeration" => CompleteEnumeration,
        "GeneticAlgorithm" => GeneticAlgorithm,
        "SimulatedAnnealing" => SimulatedAnnealing
    )
    # Check if name exists
    if !haskey(known_algorithms, config["algorithm"]["name"])
        println("Uknown algorithm: '$(config["algorithm"]["name"])', possible options are: $(keys(known_algorithms))")
        return nothing
    end
    return initialize(known_algorithms[config["algorithm"]["name"]], config["algorithm"], tsp)
end

# ----------------------------- Utils ----------------------------- 

# Checks 'settings' in cofiguration file
function check_settings(config::Dict)::Bool
    # Check config
    if !check_key(config, "settings", Dict)
        return false
    elseif !check_key(config["settings"], "seed", Int64)
        return false
    # Check iterations
    elseif !check_key(config["settings"], "max_iter", Int64)
        return false
    elseif config["settings"]["max_iter"] <= 0
        println("Expected key 'max_iter' to be larger than 0, got: $(config["settings"]["max_iter"])!")
        return false
    end
    return true
end


"""
    prepare_data(solver::Solver, run_time::Float64, name::String)::Dict

    Prepares dictionary which will be then filled with results and saved in JSON file.

# Arguments
- `solver::Solver`: current solver
- `run_time::Float64`: total run time of algorithm
- `name::String`: name of the configuration file

`Returns` Dictionary contaning additional information about algorithm run.
"""
function prepare_data(solver::Solver, run_time::Float64, name::String)::Dict
    return Dict(
        "additional_info" => Dict(
            "run_time" => round(run_time; digits=3),
            "num_iter" => solver.iteration,
            "problem" => solver.alg.tsp.name,
            "name" => split(name, SEP)[end],
            "date" => format(now(), "Y_m_d H_M_S")
        ),
        "input_config" => solver.config
    )
end

export Solver

