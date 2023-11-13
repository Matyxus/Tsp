import TSPLIB: readTSPLIB, TSP
import JSON: parsefile

# Loads problem from TSPLIB package if it exists, else tries to search '/data/problems' directory
function load_problem(problem_name::String)::Union{TSP, Nothing}
    problem_path::String = get_problem_path(problem_name)
    try
        if !file_exists(problem_path; messagge = false)
            return readTSPLIB(Symbol(problem_name))
        else
            return readTSPLIB(findTSP(problem_path))
        end
    catch e
        if e isa Base.SystemError
            println("File: '$(problem_path)' does not exist, neither does problem: '$(problem_name)' in TSPLIB package!")
        else 
            rethrow(e)
        end
    end
    return nothing
end

# Load config file from '/data/config' directory
function load_config(config_name::String)::Union{Dict, Nothing}
    config_path::String = get_config_path(config_name)
    if !file_exists(config_path)
        return nothing
    end
    # Return deepcopy, so that writing into parameters doesnt effect the reference to file
    return deepcopy(parsefile(config_path))
end

# Load log file from '/data/logs' directory
function load_log(log_name::String)::Union{Dict, Nothing}
    log_path::String = get_log_path(log_name)
    if !file_exists(log_path)
        return nothing
    end
    return parsefile(log_path)
end

export load_problem, load_config, load_log


