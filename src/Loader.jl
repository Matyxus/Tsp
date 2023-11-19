import TSPLIB: readTSPLIB, TSP
import JSON: parsefile


"""
    function load_problem(problem_name::String)::Union{TSP, Nothing}

    Loads the TSP problem, either directly from the TSPLIB package, or 
    the file must be located in '/data/problems' directory.

# Arguments
- `problem_name::String`: name of the TSP problem

`Returns` TSP structure representing problem or nothing if file does not exist.
"""
function load_problem(problem_name::String)::Union{TSP, Nothing}
    problem_path::String = get_problem_path(problem_name)
    try
        # Check for problem in TSPLIB
        if !file_exists(problem_path; messagge = false)
            return readTSPLIB(Symbol(problem_name))
        else # Check for problem in directory
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

"""
    function load_config(config_name::String)::Union{Dict, Nothing}

    Loads the (JSON) configuration file from '/data/config' directory.

# Arguments
- `config_name::String`: name of the config file

`Returns` Dictionary representing configuration (JSON) file or nothing if file does not exist
"""
function load_config(config_name::String)::Union{Dict, Nothing}
    config_path::String = get_config_path(config_name)
    if !file_exists(config_path)
        return nothing
    end
    # Return deepcopy, so that writing into parameters 
    # doesnt effect the reference to file when using Revise
    return deepcopy(parsefile(config_path))
end

"""
    function load_config(config_name::String)::Union{Dict, Nothing}

    Loads the (JSON) result/log file from '/data/logs' directory.

# Arguments
- `log_name::String`: name of the results (log) file

`Returns` Dictionary representing saved result (JSON) file or nothing if file does not exist
"""
function load_log(log_name::String)::Union{Dict, Nothing}
    log_path::String = get_log_path(log_name)
    if !file_exists(log_path)
        return nothing
    end
    return parsefile(log_path)
end

export load_problem, load_config, load_log


