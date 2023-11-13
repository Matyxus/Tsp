import TSPLIB
import Base.Threads: nthreads

mutable struct GeneticAlgorithm{T} <: EvolutionaryAlgorithm{T}
    # Setting
    params::Dict
    tsp::TSPLIB.TSP
    representation::Type{T}
    # Functions
    mutation::Function
    crossover::Function
    initializer::Function
    # Results
    children::Vector{T}

    function GeneticAlgorithm(
        params::Dict, tsp::TSPLIB.TSP, 
        repr::Type{T}, mutation::Function,
        crossover::Function, initializer::Function = random_init
            ) where {T <: Representation}

        println("Initializing EA: 'GeneticAlgorithm' with params: $(params)")
        println("tsp: $(tsp.name), representation: $(nameof(repr)), mutation: $(nameof(mutation))")
        println("crossover: $(nameof(crossover)), initializer: $(nameof(initializer))")
        new{T}(params, tsp, repr, mutation, crossover, initializer, [])
    end
end

GeneticAlgorithm(params::Dict, tsp::TSPLIB.TSP) = GeneticAlgorithm(params, tsp, Sequence, swap_city!, order_crossover)
GeneticAlgorithm(params::Dict, tsp::TSPLIB.TSP, repr::Type{T}) where {T <: Representation} = GeneticAlgorithm(params, tsp, repr, swap_city!, order_crossover)


function initialize(::Type{GeneticAlgorithm}, params::Dict, tsp::TSPLIB.TSP)::Union{Nothing, GeneticAlgorithm}
    @assert !isnothing(tsp)
    @assert !isnothing(params)
    # Check given parameters
    if !check_algorithm(params)
        return nothing
    elseif !check_representation(params)
        return nothing
    elseif !check_params(GeneticAlgorithm, params["params"])
        return nothing
    elseif !check_crossover(params["params"], params["representation"])
        return nothing
    end


    return GeneticAlgorithm(
        params["params"], tsp, 
        REPRESENTATIONS[params["representation"]],
        MUTATION_MAP[params["params"]["mutation"]["name"]],
        XOVER_MAP[params["params"]["crossover"]["name"]],
        INIT_MAP[params["params"]["init"]]
    )
end


function step(algorithm::GeneticAlgorithm)::Union{Representation, Nothing}
    # println("Performing step function on GeneticAlgorithm")
    if length(algorithm.children) != 0
        new_children::Vector{Representation} = []
        num_children::Int64 = length(algorithm.children)
        # ---------- Elitism ----------
        # Elitism guarantees to save the best genes in next generation
        # Check if previous (population * elitism) is bigger then new population, if so
        # take elitism from current population number
        elite_index::Int = (
            (num_children * algorithm.params["elitism"] < algorithm.params["population"]) ?
            floor(Int64, num_children * algorithm.params["elitism"]) :
            floor(Int64, algorithm.params["population"]  * algorithm.params["elitism"])
        )
        if elite_index > 0
            append!(new_children, algorithm.children[1:elite_index])
        end
        # ---------- Cross over + Mutation + Route Length ----------
        # Total number of crossovers needed to fill population (each crossover produces two children)
        num_x_overs::Int64 = ceil(Int64, (algorithm.params["population"] - elite_index) / 2)
        if algorithm.params["threads"] > 1
            # println("Performing parallel_step, x_overs: $(num_x_overs)")
            # println("Elite index: $(elite_index)")
            append!(new_children, parallel_step(algorithm, num_x_overs))
            # println("Generated: $(length(new_children))")
        else
            append!(new_children, single_step(algorithm, num_x_overs))
        end
        # Check number of children (crossover could have added 1 more)
        @assert length(new_children) >= algorithm.params["population"]
        new_children = new_children[1:algorithm.params["population"]]
        # ---------- Result ----------
        algorithm.children = new_children
    else # Initialize population
        println("Initializing: $(algorithm.params["population"]) children ...")
        algorithm.children = algorithm.representation.([algorithm.initializer(algorithm.tsp) for _ in 1:algorithm.params["population"]])
        set_route_length.(algorithm.children, Ref(algorithm.tsp))
    end
    # Sort children based on distance
    sort!(algorithm.children, by = child -> distance(child))
    return algorithm.children[begin]
end

# Paralelle version of crossover and mutation operators,
# have to be careful about operating on the same objects (i.e.), cannot perform 
# mutation 'swap_city' in parallel on child, if such child is there more than once
function parallel_step(algorithm::GeneticAlgorithm, num_xovers::Int64)::Vector{Representation}
    @assert 1 < algorithm.params["threads"] <= nthreads()
    # ---------- Cross over ----------
    # Initialize arrays for each thread
    accumulator::Vector{Vector{Representation}} = [[] for _ in 1:nthreads()]
    Threads.@threads for _ in 1:num_xovers
        # Crossover failed, copy parents
        if rand() > algorithm.params["crossover"]["chance"]
            # We need deepcopy here, since same parents can be added -> problem with parallel mutation!
            append!(accumulator[Threads.threadid()], deepcopy.(rand(algorithm.children, 2)))
        else # Perform crossover
            append!(accumulator[Threads.threadid()], algorithm.crossover(rand(algorithm.children, 2)...))
        end
    end
    # ---------- Mutation + Route length ----------
    Threads.@threads for i in eachindex(accumulator)
        algorithm.mutation.(accumulator[i], algorithm.params["mutation"]["chance"])
        set_route_length.(accumulator[i], Ref(algorithm.tsp))
    end
    # Return new children
    return collect(Base.Iterators.flatten(accumulator))
end

function single_step(algorithm::GeneticAlgorithm, num_xovers::Int64)::Vector{Representation}
    # ---------- Cross over ----------
    accumulator::Vector{Representation} = []
    for _ in 1:num_xovers
        # Crossover failed, append parents
        if rand() < algorithm.params["crossover"]["chance"]
            # We need deepcopy here, since same parents can be added
            append!(accumulator, deepcopy.(rand(algorithm.children, 2)))
        else # Perform crossover
            append!(accumulator, algorithm.crossover(rand(algorithm.children, 2)...))
        end
    end
    # ---------- Mutation ----------
    algorithm.mutation.(accumulator, algorithm.params["mutation"]["chance"])
    # Route length
    set_route_length.(accumulator, Ref(algorithm.tsp))
    return accumulator
end


# ----------------------------------------------------- Utils -----------------------------------------------------

function check_params(::Type{GeneticAlgorithm}, params::Dict)::Bool
    # Check population
    if !check_key(params, "population", Int64)
        return false
    elseif params["population"] <= 0
        println("Population has to be value greater than 0, got: $(params["Population"])")
        return false
    # Check elitism
    elseif !check_key(params, "elitism", Float64)
        return false
    elseif !(0 < params["elitism"] <= 0.1)
        println("Elitism has to be value between (0, 0.1> got: $(params["elitism"])")
        return false
    # Mutation
    elseif !check_mutation(params)
        return false
    # Threads
    elseif !check_threads(params)
        return false
    end
    # Init
    return check_init(params)
end

function check_threads(params::Dict)::Bool
    # Check threads
    if haskey(params, "threads")
        if !isa(params["threads"], Int64)
            println("Parameter threads has to be Int64, got: $(typeof(params["threads"]))")
            return false
        elseif !(1 <= params["threads"] <= nthreads())
            println("Invalid number of threads, number must be between: <1, $(nthreads())>, got: $(params["threads"]) !")
            println("To change number of threads, run julia with options: '--threads NUM'")
        end
    end
    # Set threads to 1
    println("Defaulting to enviroment number of threads: $(nthreads()) ....")
    params["threads"] = nthreads()
    return true
end


is_running(::GeneticAlgorithm)::Bool = true


export GeneticAlgorithm


