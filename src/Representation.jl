import TSPLIB: TSP

# --------------------- Representation ---------------------
# Super type of all different representations
abstract type Representation end
distance(repr::Representation)::Float64 = repr.distance
route(repr::Representation)::Vector{Int64} = repr.route
Base.show(io::IO, repr::Representation) = println(io, "Dist: $(distance(repr)), Route: $(convert(repr))")
# Convert representation to sequance of cities -> vector of indexes (default representation)
convert(::Representation)::Vector{Int64} = throw(ArgumentError("All subtypes of 'Representation' must define method 'convert' !"))
# Get lenght of route
route_length(repr::Representation, tsp::TSP)::Float64 = calculate_distance(convert(repr), tsp)
function set_route_length(repr::Representation, tsp::TSP)::Float64
    repr.distance = route_length(repr, tsp)
    return distance(repr)
end

calculate_distance(route::Vector{Int64}, tsp::TSP)::Float64 = (
    sum([tsp.weights[route[i], route[i+1]] for i in 1:(tsp.dimension-1)]) + 
    tsp.weights[route[end], route[begin]]
)

# --------------------- Sequence ---------------------
# Default representation of journey (contains cities in order of their visit, as indexes)
mutable struct Sequence <: Representation
    route::Vector{Int64}
    distance::Float64
    Sequence(route::Vector{Int64}) = new(route, 0)
    Sequence(route::Vector{Int64}, dist::Float64) = new(route, dist)
end
convert(seq::Sequence)::Vector{Int64} = seq.route

# --------------------- InverseSequence ---------------------
# Representation using inverse sequance to represent cities on route (provides easier operation with crossover operators etc.)
mutable struct InverseSequence <: Representation
    route::Vector{Int64}
    distance::Float64
    InverseSequence(route::Vector{Int64}; transform::Bool = true) = new(transform ? get_inverse(route) : route, 0)
    InverseSequence(route::Vector{Int64}, dist::Float64; transform::Bool = true) = new(transform ? get_inverse(route) : route, dist)
end

convert(inv_seq::InverseSequence)::Vector{Int64} = get_permutation(route(inv_seq))

"""
    get_inverse(route::Vector{Int})::Vector{Int}

    Creates vector 'result' where each index 'i' corresponds
    to number in `route` argument, and 'result[i]' is equal to
    count of numbers which are preceding (index wise) 'i' and
    are lower in `route`.

# Arguments
- `route::Vector{Int}`: Vector containing sequence of numbers (starting from 1 up to N, must include all)

`Returns` Vector{Int64} of same lenght as input, of reverse sequence

# Examples
```julia-repl
julia> get_inverse([5, 7, 1, 3, 6, 4, 2])
7-element Vector{Int64}: [2, 5, 2, 0, 2, 0, 0]
```
"""
function get_inverse(route::Vector{Int64})::Vector{Int64}
    inverse::Vector{Int64} = []
    for i in 1:length(route)
        inverse_i::Int64 = 0
        m::Int64 = 1
        while (route[m] != i)
            if route[m] > i
                inverse_i += 1
            end
            m += 1
        end
        append!(inverse, inverse_i)
    end
    return inverse
end

"""
    get_permutation(inverse::Vector{Int})::Vector{Int}

    Reverses the function get_inverse(route::Vector{Int}), from
    inverse sequence constructs original sequence.

# Arguments
- `inverse::Vector{Int}`: Vector containing sequence of numbers

`Returns` Permutation of numbers build from reverse sequence

# Examples
```julia-repl
julia> get_permutation([2, 5, 2, 0, 2, 0, 0])
7-element Vector{Int64}: [5, 7, 1, 3, 6, 4, 2]

julia> get_permutation(get_inverse([5, 7, 1, 3, 6, 4, 2]))
7-element Vector{Int64}: [5, 7, 1, 3, 6, 4, 2]
```
"""
function get_permutation(inverse::Vector{Int64})::Vector{Int64}
    len::Int64 = length(inverse)
    temp::Vector{Int64} = zeros(Int64, len)
    for i in len:-1:1
        for m in (i+1):len
            if temp[m] >= (inverse[i] + 1)
                temp[m] += 1
            end
        end
        temp[i] = (inverse[i] + 1)
    end
    permutation::Vector{Int64} = zeros(Int64, len)
    for i in 1:len
        permutation[temp[i]] = i
    end
    return permutation
end

# --------------------------- Utils --------------------------- 

function check_representation(params::Dict)::Bool
    # Check key existence and type
    if !check_key(params, "representation")
        return false
    elseif !haskey(REPRESENTATIONS, params["representation"])
        println("Invalid representation name: $(params["representation"]), options: $(keys(REPRESENTATIONS))")
        return false
    end
    return true
end

const REPRESENTATIONS::Dict{String, DataType} = Dict(
    "Sequence" => Sequence,
    "InverseSequence" => InverseSequence
)

export Representation, Sequence, InverseSequence
export route, convert, distance, route_length, set_route_length
export check_representation, REPRESENTATIONS



