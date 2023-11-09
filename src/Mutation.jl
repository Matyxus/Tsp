# Swap mutation
function swap_city!(repr::Representation, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    index1, index2 = rand(1:length(route(repr)), 2)
    route(repr)[index1], route(repr)[index2] = route(repr)[index2], route(repr)[index1]
    return
end


# RSM mutation
function reverse_subsequence!(repr::Representation, prob::Float64 = 0.1)::Nothing
    if rand() > prob
        return
    end
    from, to = rand(1:length(route(repr)), 2)
    from, to = from > to ? (to, from) : (from, to)
    route(repr)[from:to] = reverse(route(repr)[from:to])
    return
end

# PSM mutation
function partial_shuffle!(repr::Representation, prob::Float64 = 0.1, swap_chance::Float64 = 0.1)::Nothing
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

# --------------------------- Utils --------------------------- 

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

MUTATION_MAP::Dict{String, Function} = Dict{String, Function}(
    "swap_city" => swap_city!,
    "rsm" => reverse_subsequence!,
    "psm" => partial_shuffle!
)

export swap_city!, reverse_subsequence!, partial_shuffle!
export check_mutation, MUTATION_MAP

