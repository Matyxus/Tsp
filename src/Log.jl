# Struct for saving results of algorithms
mutable struct Log
    cache::Vector{Tuple{Int64, Float64, Vector{Int64}}}
    Log() = new([])
end


add_result(log::Log, iteration::Int64, distance::Float64, solution::Vector{Int64}) = push!(log.cache, (iteration, distance, solution))
get_best(log::Log)::Union{Tuple{Int64, Float64, Vector{Int64}}, Nothing} = (length(log.cache) == 0) ? nothing : log.cache[end]

export Log, add_result, get_best




