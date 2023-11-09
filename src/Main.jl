import TSPLIB
import Random.seed!
using BenchmarkTools

mutable struct Solver
    config::Dict
    alg::Alg
    log::Log
    iteration::Int64
    Solver(config::Dict, alg::Alg) = new(config, alg, Log(), 0)
end


function standard_run(solver::Union{Solver, Nothing})::Bool
    if isnothing(solver)
        println("Invalid solver, stopping ...")
        return false
    end
    println("Starting to iterate with algorithm: $(solver.config["algorithm"]["name"]), max_iters: $(solver.config["settings"]["max_iter"])")
    # Start running algorithm
    best_dist::Float64 = Inf64
    percent::Int64 = floor(solver.config["settings"]["max_iter"] / 100)
    while (solver.iteration != solver.config["settings"]["max_iter"]) && is_running(solver.alg)
        solution::Representation = step(solver.alg)
        # Erorr happened
        if isnothing(solution)
            println("Error received invalid solution!")
            break
        elseif distance(solution) < best_dist
            best_dist = distance(solution)
            add_result(solver.log, solver.iteration, best_dist, convert(solution))
        end
        solver.iteration += 1
        if (solver.iteration % percent) == 0
            println("Finished iteration: $(solver.iteration)/$(solver.config["settings"]["max_iter"])")
        end
    end
    if best_dist != Inf64
        println("Finished iterating: $(solver.iteration)/$(solver.config["settings"]["max_iter"]) times.")
        println("Best solution: $(get_best(solver.log))")
        println("Improved initial solution: $(length(solver.log.cache)-1) times.")
        println("Optimal solution: $(solver.alg.tsp.optimal)")
    else
        println("Erorr happend while running algorithm, exiting ...")
    end
    return true
end


# ----------------------------- Process functions ----------------------------- 

function process_config(config::Dict, problem::String)::Union{Nothing, Solver}
    println("Processing configuration file, problem: $(problem)")
    # ------------ Check config ------------ 
    # Failed to load
    if isnothing(config)
        return nothing
    end
    println("Loaded configuration file successfully ...")
    tsp::Union{TSPLIB.TSP, Nothing} = process_settings(config, problem)
    if isnothing(tsp)
        return nothing
    end
    alg::Union{Alg, Nothing} = process_algorithm(config, tsp)
    if isnothing(alg)
        return nothing
    end
    return Solver(config, alg)
end


function process_settings(config::Dict, problem::String)::Union{TSPLIB.TSP, Nothing}
    # Check
    if !check_settings(config)
        return nothing
    end
    seed!(config["settings"]["seed"])
    return load_problem(problem)
end


function process_algorithm(config::Union{Dict, Nothing}, tsp::TSPLIB.TSP)::Union{Nothing, Alg}
    # Check
    if !check_key(config, "algorithm", Dict)
        return nothing
    end
    # Load algorithm
    known_algorithms::Dict{String, Any} = Dict{String, Any}(
        "CompleteEnumeration" => CompleteEnumeration,
        "GeneticAlgorithm" => GeneticAlgorithm,
        "SimulatedAnnealing" => SimulatedAnnealing
    )
    if !haskey(known_algorithms, config["algorithm"]["name"])
        println("Uknown algorithm: '$(config["algorithm"]["name"])', possible options are: $(keys(known_algorithms))")
        return nothing
    end
    println("Algorithm name: $(config["algorithm"]["name"])")
    return initialize(known_algorithms[config["algorithm"]["name"]], config["algorithm"], tsp)
end


function process_gui(config::Dict)::Bool
    # Check config
    if !check_key(config, "gui")
        return false
    end
    return true
end

# ----------------------------- Utils ----------------------------- 

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

function prepare_data(solver::Solver, run_time)::Dict
    return Dict(
        "additional_info" => Dict(
            "run_time" => run_time,
            "num_iter" => solver.iteration
        ),
        "input_config" => solver.config,
        # Save results, from best to worst
        "data" => [
            Dict(
                "iteration" => solution[1],
                "distance" => solution[2],
                "sequence" => solution[3]
            ) for solution in reverse(solver.log.cache)
        ],
    )
end


export main
