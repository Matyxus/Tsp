import TSPLIB
import Random.shuffle!

# Randomly intializes solution
random_init(tsp::TSP)::Vector{Int64} = shuffle!([1:tsp.dimension...])

"""
    nearest_neighbour(tsp::TSP)::Vector{Int64}  

    Begins by randomly choosing starting city, then 
    adds the closest city to the one previously added,
    untill all cities were added.

# Arguments
- `tsp::TSP`: the tsp problem

`Returns` Vector of cities indexes
"""
function nearest_neighbour(tsp::TSP)::Vector{Int64}  
    visited::Vector{Bool} = falses(tsp.dimension)
    path::Vector{Int64} = [rand(1:tsp.dimension)]
    for _ in 2:tsp.dimension
        visited[path[end]] = true
        best_city, best_dist = (-1, Inf)
        for (city, distance) in enumerate(tsp.weights[path[end], :])
            if !visited[city] && (distance < best_dist)
                best_city, best_dist = city, distance
            end
        end
        # @assert (best_city != -1 && best_dist != Inf)
        push!(path, best_city)
    end
    return path
end

# --------------------------- Utils ---------------------------  
# Checks if the initialization in configuration is given correctly
function check_init(params::Dict)::Bool
    # Check key existence and type
    if !check_key(params, "init")
        return false
    elseif !haskey(INIT_MAP, params["init"])
        println("Invalid initialization name: $(params["init"]), options: $(keys(INIT_MAP))")
        return false
    end
    return true
end

# Mapping of initialization name to function
INIT_MAP::Dict{String, Function} = Dict{String, Function}(
    "random" => random_init,
    "nearest_neighbour" => nearest_neighbour,
    "nn" => nearest_neighbour
)

export random_init, nearest_neighbour
export check_init, INIT_MAP

