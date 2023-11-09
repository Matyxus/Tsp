import TSPLIB
import Random.shuffle!

random_init(tsp::TSPLIB.TSP)::Vector{Int64} = shuffle!([1:tsp.dimension...])

function nearest_neighbour(tsp::TSPLIB.TSP)::Vector{Int64}  
    visited::Vector{Bool} = falses(tsp.dimension)
    path::Vector{Int64} = [rand(1:tsp.dimension)]
    for _ in 2:tsp.dimension
        visited[path[end]] = true
        best_city, best_dist = (-1, typemax(Int))
        for (city, distance) in enumerate(tsp.weights[path[end], :])
            if !visited[city] && (distance < best_dist)
                best_city, best_dist = city, distance
            end
        end
        @assert (best_city != -1 && best_dist != typemax(Int))
        push!(path, best_city)
    end
    return path
end

# --------------------------- Utils ---------------------------  

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

INIT_MAP::Dict{String, Function} = Dict{String, Function}(
    "random" => random_init,
    "nearest_neighbour" => nearest_neighbour
)

export random_init, nearest_neighbour
export check_init, INIT_MAP

