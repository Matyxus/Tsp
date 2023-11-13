# ---------------------------- InverseSequence Representation ----------------------------
"""
    crossover(parentA::Route, parentB::Route, chance::Float64)::Pair{Route, Route}

    Performs crossover operation, by using inverse sequence of city id's
    and randomly selected index, parentA[1:index] is combined with 
    parentB[index+1:end] to create new route (another using parentB first).

# Arguments
- `parentA::Route`: Route class representing first parent 'gene'
- `parentB::Route`: Route class representing second parent 'gene'

`Returns` Pair, containing (parentA, parentB) if chance to crossover does not trigger, else two new Routes.
"""


function one_point_crossover(parentA::InverseSequence, parentB::InverseSequence)::Tuple{InverseSequence, InverseSequence}
    crossover_point::Int64 = rand(1:(length(route(parentA))-1))
    return (
        InverseSequence(append!(route(parentA)[1:crossover_point],  route(parentB)[crossover_point+1:end]); transform=false),
        InverseSequence(append!(route(parentB)[1:crossover_point],  route(parentA)[crossover_point+1:end]); transform=false)
    )
end

function order_crossover(parentA::InverseSequence, parentB::InverseSequence)::Tuple{InverseSequence, InverseSequence}
    len::Int64 = length(route(parentA))
    from, to = rand(1:len, 2)
    from, to = from > to ? (to, from) : (from, to)
    return ( # 1st part, middle, last part
        InverseSequence(append!(route(parentB)[1:from-1], route(parentA)[from:to], route(parentB)[to+1:end]); transform=false),
        InverseSequence(append!(route(parentA)[1:from-1], route(parentB)[from:to], route(parentA)[to+1:end]); transform=false),
    )
end


# ---------------------------- Sequence Representation ----------------------------


function pmx(parentA::Sequence, parentB::Sequence)::Tuple{Sequence, Sequence}
    len::Int64 = length(route(parentA))
    from, to = rand(1:len, 2)
    from, to = from > to ? (to, from) : (from, to)

    function generate_child(A::Sequence, B::Sequence)::Sequence
        child::Sequence = Sequence(zeros(Int64, len))
        # Copy middle part from parent B
        route(child)[from:to] = route(B)[from:to]
        mapping::Dict{Int64, Int64} = Dict{Int64, Int64}(zip(route(child)[from:to], route(A)[from:to]))
        # Fill the missing cities form parents
        for i in vcat(1:from-1, to+1:len)
            city::Int64 = route(A)[i]
            while (haskey(mapping, city))
                city = mapping[city]
            end
            route(child)[i] = city
        end

        # @assert length(unique(route(child))) == len
        return child
    end

    return generate_child(parentA, parentB), generate_child(parentB, parentA)
end


function order_crossover(parentA::Sequence, parentB::Sequence)::Tuple{Sequence, Sequence}
    len::Int64 = length(route(parentA))
    from, to = rand(1:len, 2)
    from, to = from > to ? (to, from) : (from, to)

    function generate_child(A::Sequence, B::Sequence)::Sequence
        added_cities::Set{Int64} = Set{Int64}(route(B)[from:to])
        seq::Vector{Int64} = [city for city in route(A) if !(city in added_cities)]
        child::Sequence = Sequence(append!(seq[begin:from-1], route(B)[from:to], seq[from:end]))
        # @assert length(unique(route(child))) == len
        return child
    end

    return generate_child(parentA, parentB), generate_child(parentB, parentA)
end


# position-crossover
function position_crossover(parentA::Sequence, parentB::Sequence)::Tuple{Sequence, Sequence}
    len::Int64 = length(route(parentA))

    function generate_child(A::Sequence, B::Sequence)::Sequence
        child::Sequence = Sequence(zeros(Int64, len))
        added_cities::Vector{Bool} = falses(len)
        # Select random number of indexes from parent A
        for index in rand(1:len, rand(1:len))
            route(child)[index] = route(A)[index]
            added_cities[route(A)[index]] = true
        end
        # Fill the rest with parent B cities at their index
        index::Union{Int64, Nothing} = findfirst(item -> item == 0, route(child))
        if !isnothing(index)
            for city in route(B)
                if !added_cities[city]
                    route(child)[index] = city
                    index = findnext(item -> item == 0, route(child), index)
                end
            end
        end
        # @assert length(unique(route(child))) == len
        return child
    end

    return generate_child(parentA, parentB), generate_child(parentB, parentA)
end

# --------------------------- Utils --------------------------- 

function check_crossover(params::Dict, representation::String)::Bool
    # Check key existence and type
    if !check_key(params, "crossover", Dict)
        return false
    # Check crossover name
    elseif !check_key(params["crossover"], "name")
        return false
    elseif !haskey(XOVER_MAP, params["crossover"]["name"])
        println("Invalid crossover name: $(params["crossover"]["name"]), options: $(keys(XOVER_MAP))")
        return false
    # Check chance
    elseif !check_key(params["crossover"], "chance", Float64)
        return false
    elseif !(0 <= params["crossover"]["chance"] <= 1)
        println("Invalid chance for crossover must be between <0, 1>, got: $(params["crossover"]["chance"])")
        return false
    # Check if representation for this crossover is valid
    elseif !(representation in ALLOWED_XOVER_TYPE[params["crossover"]["name"]])
        println("Invalid representation: $(representation) for crossover: $(params["crossover"]["name"]), options: $(ALLOWED_XOVER_TYPE)")
        return false
    end
    return true
end

const XOVER_MAP::Dict{String, Function} = Dict{String, Function}(
    "point" => one_point_crossover,
    "order" => order_crossover,
    "pmx" => pmx,
    "position" => position_crossover,
)

const ALLOWED_XOVER_TYPE::Dict{String, Set{String}} = Dict{String, Set{String}}(
    "point" => Set(["InverseSequence"]),
    "order" => Set(["InverseSequence", "Sequence"]),  # Works as 2Points Xover for InverseSequence
    "pmx" => Set(["Sequence"]),
    "position" => Set(["Sequence"]),
)

export one_point_crossover, position_crossover, pmx, order_crossover
export check_crossover, XOVER_MAP, ALLOWED_XOVER_TYPE

