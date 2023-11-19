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
"""
    file_exists(file_path::String; messagge::Bool = true)::Bool

    Checkes whether file exists.

# Arguments
- `file_path::String`: path to file
- `messagge::Bool`: optional parameter, prints messagge about file not existing, true by default

`Returns` True if file exists, false otherwise.
"""
function file_exists(file_path::String; messagge::Bool = true)::Bool
    exists::Bool = isfile(file_path)
    if messagge && !exists
        Base.printstyled("File: '$(file_path)' does not exist!\n"; color = :red, blink = true)
        return false
    end
    return exists
end

# Functions returning full path to file (from its name) corresponding to type
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

# ---------------------- GUI ----------------------

const BUTTON_LABELS::Vector{String} = [
    "Play", 
    "Pause", 
    "Step", 
    "Default",
    "Exit"
]

const LABEL_LABELS::Vector{String} = [
    "Iteration: ", 
    "Current distance: ", 
    "Best distance: "
]

const LABEL_STARTING_VALUES::Vector{Union{Int64, Float64}} = [
    0,
    0.0,
    0.0
]
const WIDTH::Int64 = 1280
const HEIGHT::Int64 = 800
const AXIS_OFFSET::Int64 = 2
const TEXT_OFFSET::Float64 = 0.1
const SLEEP_TIME::Int64 = 150

