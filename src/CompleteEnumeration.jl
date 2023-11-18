# Structure used for saving state of permutation
mutable struct State
    permutation::Vector{Int64}
    visited::Vector{Bool}
    previous::Int64
    seq_length::Int64
    distance::Float64
    State(size::Int64) = new([1], falses(size), 0, 1, 0.0)
    State(start::Int64, size::Int64) = new([start], falses(size), 0, 1, 0.0)
end

# Reset to previous state
function go_back(state::State, tsp::TSPLIB.TSP)::Nothing
    # Subtract distance from previous city
    state.distance -= tsp.weights[
        state.permutation[end], 
        # Add check in case we only have 1 city
        state.permutation[end-(state.seq_length != 1)]
    ]
    state.previous = pop!(state.permutation)
    state.visited[state.previous] = false
    state.seq_length -= 1
    return
end


mutable struct CompleteEnumeration{T} <: Alg{T}
    # Settings
    params::Dict
    tsp::TSPLIB.TSP
    representation::Type{T}
    state::State
    # Functions
    initializer::Function
    # Results
    solution::Union{T, Nothing}

    function CompleteEnumeration(params::Dict, tsp::TSPLIB.TSP, initializer::Function = random_init)
        println("Initializing 'CompleteEnumeration' with params: $(params)")
        println("tsp: $(tsp.name), initializer: $(nameof(initializer))")
        new{Sequence}(params, tsp, Sequence, State(tsp.dimension), initializer, nothing)
    end
end


function initialize(::Type{CompleteEnumeration}, params::Dict, tsp::TSPLIB.TSP)::Union{Nothing, CompleteEnumeration}
    @assert !isnothing(tsp)
    @assert !isnothing(params)
    # Check given parameters
    if !check_key(params, "params", Dict)
        return nothing
    elseif !check_params(CompleteEnumeration, params["params"])
        return nothing
    end
    return CompleteEnumeration(
        params["params"], tsp,
        INIT_MAP[params["params"]["init"]]
    )
end


function step(alg::CompleteEnumeration)::Union{Representation, Nothing}
    # println("Performing step on algorithm: 'CompleteEnumeration'")
    # Found all permutations starting with first city of state, change first city to next one
    if alg.state.seq_length == 0
        # println("Found all permutation which start with: $(alg.state.permutation[begin])")
        alg.state = State(alg.state.permutation[begin] + 1, alg.tsp.dimension)
    # Initialize solution
    elseif isnothing(alg.solution)
        alg.solution = alg.representation(alg.initializer(alg.tsp))
        set_route_length(alg.solution, alg.tsp)
        # println("Initializing solution for 'CompleteEnumeration': $(alg.solution)")
    end
    # Search trough permutation, return first valid, record state
    if is_running(alg)
        # println("Looking trough possible permutations, dist: $(alg.state.distance), current: $(alg.state.permutation)")
        current::Int64 = alg.state.permutation[end]
        alg.state.visited[current] = true
        # Went pass the best found distance, go back
        if alg.state.distance > distance(alg.solution)
            go_back(alg.state, alg.tsp)
        # Found valid permutation, check for best distance
        elseif alg.state.seq_length == alg.tsp.dimension
            # println("Reached full permutation size, comparing distances: $(alg.state.distance) vs $(distance(alg.solution))")
            # println("Permutation: $(alg.state.permutation)")
            # Add distance between last and first city
            alg.state.distance += alg.tsp.weights[alg.state.permutation[begin], current]
            if alg.state.distance < distance(alg.solution)
                alg.solution = alg.representation(deepcopy(alg.state.permutation))
                alg.solution.distance = alg.state.distance
            end
            # Subtract distance between last and fist city
            alg.state.distance -= alg.tsp.weights[alg.state.permutation[begin], current]
            go_back(alg.state, alg.tsp)
        # Previous was last in sequence, go back
        elseif alg.state.previous == alg.tsp.dimension
            go_back(alg.state, alg.tsp)
        else
            # Find first unvisited city (depending on previous state)
            index::Union{Int64, Nothing} = findnext(item -> item == false, alg.state.visited, alg.state.previous + 1)
            # Already visited all in this sequence, go back
            if isnothing(index)
                go_back(alg.state, alg.tsp)
            else # Advance permutation
                push!(alg.state.permutation, index)
                alg.state.seq_length += 1
                alg.state.distance += alg.tsp.weights[current, index]
                # Reset previous, make sure all cities (not in permutation) are considerend in next step
                alg.state.previous = 0
            end
        end
    end
    return alg.solution
end

# ----------------------------------------------------- Utils -----------------------------------------------------
check_params(::Type{CompleteEnumeration}, params::Dict)::Bool = check_init(params)
# We didnt explore all permutations
is_running(alg::CompleteEnumeration)::Bool = alg.state.permutation[begin] <= alg.tsp.dimension


# ------------------------ GUI ------------------------

get_alg_sliders(::CompleteEnumeration)::Dict = Dict()
update_params(alg::CompleteEnumeration, params::Dict{String, Union{Int64, Float64}})::Nothing = nothing


export CompleteEnumeration



