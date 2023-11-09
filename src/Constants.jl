import JSON: print as j_print
import Dates: format, now
const SEP::String = Base.Filesystem.pathsep()
# -------------------- Data directory -------------------- 
const DATA_PATH::String = "data"
const CONFIG_PATH::String = DATA_PATH * SEP * "config"
const LOGS_PATH::String  = DATA_PATH * SEP * "logs"
const PROBLEMS_PATH::String = DATA_PATH * SEP * "problems"
# -------------------- Extensions -------------------- 
const JSON_EXTENSION::String = ".json"
const TSPLIB_EXTENSION::String = ".tsplib"
# -------------------- File functions -------------------- 
function file_exists(file_path::String; messagge::Bool = true)::Bool
    exists::Bool = isfile(file_path)
    if messagge && !exists
        Base.printstyled("File: '$(file_path)' does not exist!\n"; color = :red, blink = true)
        return false
    end
    return exists
end

function save_result(file_name::String, data::Dict)::Bool
    # Move to "logs" folder and add suffix + extension
    suffix::String =  "_" * replace(format(now(), "HH:MM:SS"), ":" => "_")
    file_name = isempty(file_name) ? "log" : file_name
    file_name = (LOGS_PATH * SEP * file_name * suffix * JSON_EXTENSION)
    # Checks
    if isempty(data)
        println("Cannot save empty log!")
        return false
    elseif file_exists(file_name; messagge=false)
        println("File: '$(file_name)' already exists!")
        return false
    end
    println("Saving log to file: '$(file_name)'")
    # Save data to file
    open(file_name, "w") do f
        j_print(f, data, 2)
    end
    return true 
end

get_problem_path(problem_name::String)::String = (PROBLEMS_PATH * SEP * problem_name * TSPLIB_EXTENSION)
get_config_path(config_name::String)::String = (CONFIG_PATH * SEP * config_name * JSON_EXTENSION)
get_log_path(log_name::String)::String = (LOGS_PATH * SEP * log_name * JSON_EXTENSION)

# -------------------- Util functions -------------------- 
# Helper function for checking key existence and type
function check_key(mapping::Dict, key::String, type::Type = String)::Bool
    # Check key
    if !haskey(mapping, key)
        println("Missing key: '$(key)' in dictionary!")
        return false
    # Check type
    elseif !isa(mapping[key], type)
        println("Expected key: '$(key)' to be type: $(nameof(type)) in dictionary, got: $(typeof(mapping[key]))")
        return false
    end
    return true
end

export file_exists, get_problem_path, get_config_path, check_key, save_result
