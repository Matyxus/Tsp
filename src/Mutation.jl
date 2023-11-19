# -------------------------------- Swap -------------------------------- 

"""
    swap_city!(repr::Sequence, prob::Float64 = 0.1)::Nothing

    Swaps cities by randomly choosing two indexes, if triggered (random number is 
    larger then 'prob' parameter). Works similary for InverseSequence representation.

# Arguments
- `repr::Sequence`: the current representation of solution
- `prob::Float64 = 0.1`: the chance of operator being triggered

`Returns` nothing, operator operates in-place
"""
function swap_city!(repr::Sequence, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    index1, index2 = rand(1:length(route(repr)), 2)
    route(repr)[index1], route(repr)[index2] = route(repr)[index2], route(repr)[index1]
    return
end

function swap_city!(repr::InverseSequence, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    index1, index2 = rand(1:length(route(repr)), 2)
    # Convert back to sequence represetnation
    cities::Vector{Int64} = to_sequence(repr)
    cities[index1], cities[index2] = cities[index2], cities[index1]
    repr.route = get_inverse(cities)
    return
end

# -------------------------------- Rsm -------------------------------- 

"""
    reverse_subsequence!(repr::Sequence, prob::Float64 = 0.1)::Nothing

    Reverses subsequence of cities by randomly chosing two indexes, if triggered (random number is 
    larger then 'prob' parameter). Works similary for InverseSequence representation.

# Arguments
- `repr::Sequence`: the current representation of solution
- `prob::Float64 = 0.1`: the chance of operator being triggered

`Returns` nothing, operator operates in-place
"""
function reverse_subsequence!(repr::Sequence, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    from, to = rand(1:length(route(repr)), 2)
    from, to = from > to ? (to, from) : (from, to)
    route(repr)[from:to] = reverse(route(repr)[from:to])
    return
end

function reverse_subsequence!(repr::InverseSequence, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    # Convert back to sequence represetnation
    cities::Vector{Int64} = to_sequence(repr)
    from, to = rand(1:length(cities), 2)
    from, to = from > to ? (to, from) : (from, to)
    cities[from:to] = reverse(cities[from:to])
    repr.route = get_inverse(cities)
    return
end

# -------------------------------- Psm -------------------------------- 

"""
    partial_shuffle!(repr::Sequence, prob::Float64 = 0.1)::Nothing

    Iterates over cities in permutation, randomly decides (with probabilty 0.1%)
    to swap the current city with another (randomly chosen) if triggered (random number is 
    larger then 'prob' parameter). Works similary for InverseSequence representation.

# Arguments
- `repr::Sequence`: the current representation of solution
- `prob::Float64 = 0.1`: the chance of operator being triggered
- `swap_chance::Float64 = 0.1`: the chance of swapping cities

`Returns` nothing, operator operates in-place
"""
function partial_shuffle!(repr::Sequence, prob::Float64 = 0.1, swap_chance::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    len::Int64 = length(route(repr))
    for i in 1:length(len)
        if rand() > swap_chance
            j::Int64 = rand(1:len)
            route(repr)[i], route(repr)[j] = route(repr)[j], route(repr)[i]
        end
    end
    return
end

function partial_shuffle!(repr::InverseSequence, prob::Float64 = 0.1, swap_chance::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    # Convert back to sequence represetnation
    cities::Vector{Int64} = to_sequence(repr)
    len::Int64 = length(cities)
    for i in 1:length(len)
        if rand() > swap_chance
            j::Int64 = rand(1:len)
            cities[i], cities[j] = cities[j], cities[i]
        end
    end
    repr.route = get_inverse(cities)
    return
end

# --------------------------- Utils --------------------------- 
# Checks the mutation operator in config file, if it was given correctly
function check_mutation(params::Dict)::Bool
    # Check key existence and type
    if !check_key(params, "mutation", Dict)
        return false
    # Check mutation name
    elseif !check_key(params["mutation"], "name")
        return false
    elseif !haskey(MUTATION_MAP, params["mutation"]["name"])
        println("Invalid mutation name: $(params["mutation"]["name"]), options: $(keys(MUTATION_MAP))")
        return false
    # Check chance
    elseif !check_key(params["mutation"], "chance", Float64)
        return false
    elseif !(0 <= params["mutation"]["chance"] <= 1)
        println("Invalid chance for mutation, must be between <0, 1>, got: $(params["mutation"]["chance"])")
        return false
    end    
    return true
end

# Mapping of mutation name to function
MUTATION_MAP::Dict{String, Function} = Dict{String, Function}(
    "swap" => swap_city!,
    "rsm" => reverse_subsequence!,
    "psm" => partial_shuffle!
)

