import JSON: print as j_print
"""
Structure saving results of algorithms
in vector of tuples: (iteration, distance, permutation)
"""
mutable struct Log
    cache::Vector{Tuple{Int64, Float64, Vector{Int64}}}
    Log() = new([])
end

"""
    add_result(log::Log, iteration::Int64, distance::Float64, solution::Vector{Int64})

    Stores the current result inside Log structure.

# Arguments
- `log::Log`: structure saving results
- `iteration::Int64`: iteration at which result was found
- `distance::Float64`: lenght of city tour
- `solution::Vector{Int64}`: permutation of city indexes

`Returns` the current stored results
"""
add_result(log::Log, iteration::Int64, distance::Float64, solution::Vector{Int64}) = push!(log.cache, (iteration, distance, solution))

"""
    get_best(log::Log)::Union{Tuple{Int64, Float64, Vector{Int64}}, Nothing}

# Arguments
- `log::Log`: structure saving results

`Returns` the best sroted result (always at the end), if empty returns Nothing
"""
get_best(log::Log)::Union{Tuple{Int64, Float64, Vector{Int64}}, Nothing} = (length(log.cache) == 0) ? nothing : log.cache[end]


"""
    save_log(file_name::String, data::Dict, log::Log)::Bool

    Creates JSON file inside 'data/logs' directory.

# Arguments
- `file_name::String`: name of file solution will be saved in
- `data::Dict`: additional data to be saved (can be empty)
- `log::Log`: structure saving results

`Returns` true on success, false otherwise
"""
function save_log(file_name::String, data::Dict{String, Any}, log::Log)::Bool
    # Save results, from best to worst (so that best one can be seen immediately)
    data["data"] = [
        Dict(
            "iteration" => solution[1],
            "distance" => solution[2],
            "sequence" => solution[3]
        ) for solution in reverse(log.cache)
    ]
    # Move to "logs" folder and add extension
    file_name = isempty(file_name) ? "log" : file_name
    file_name = (LOGS_PATH * SEP * file_name * JSON_EXTENSION)
    # Checks
    if isempty(data)
        println("Data are empty, nothing to be saved!")
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

