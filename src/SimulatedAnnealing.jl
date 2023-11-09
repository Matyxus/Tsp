import TSPLIB

mutable struct SimulatedAnnealing{T} <: LocalSearch{T}
    # Settings
    params::Dict
    tsp::TSPLIB.TSP
    representation::Type{T}
    # Functions
    perturbation::Function
    initializer::Function
    # Results
    solution::Union{T, Nothing}

    function SimulatedAnnealing(
        params::Dict, tsp::TSPLIB.TSP, 
        repr::Type{T}, perturbation::Function,
        initializer::Function = random_init
            ) where {T <: Representation}

        println("Initializing LS: 'SimulatedAnnealing' with params: $(params)")
        println("tsp: $(tsp.name), representation: $(nameof(repr))")
        println("perturbation: $(nameof(perturbation)), initializer: $(nameof(initializer))")
        new{T}(params, tsp, repr, perturbation, initializer, nothing)
    end
end

SimulatedAnnealing(params::Dict, tsp::TSPLIB.TSP) = SimulatedAnnealing(params, tsp, Sequence, swap_city!)
SimulatedAnnealing(params::Dict, tsp::TSPLIB.TSP, repr::Type{T}) where {T <: Representation} = SimulatedAnnealing(params, tsp, repr, swap_city!)

function initialize(::Type{SimulatedAnnealing}, params::Dict, tsp::TSPLIB.TSP)::Union{Nothing, SimulatedAnnealing}
    @assert !isnothing(tsp)
    @assert !isnothing(params)
    # Check given parameters
    if !check_algorithm(params)
        return nothing
    elseif !check_representation(params)
        return nothing
    elseif !check_params(SimulatedAnnealing, params["params"])
        return nothing
    end
    return SimulatedAnnealing(
        params["params"], tsp, 
        REPRESENTATIONS[params["representation"]],
        MUTATION_MAP[params["params"]["mutation"]["name"]],
        INIT_MAP[params["params"]["init"]]
    )
end


function step(algorithm::SimulatedAnnealing)::Union{Representation, Nothing}
    # println("Performing step function on SimulatedAnnealing")
    # Algorithm cannot run anymore
    if !is_running(algorithm)
        # println("Parameter temperature has to be greater than 1, got: $(algorithm.params["temperature"])")
        return algorithm.solution
    elseif !isnothing(algorithm.solution)
        # Deep copy of previous
        new_solution::Representation = deepcopy(algorithm.solution)
        # Perturbation (must happen always)
        algorithm.perturbation(new_solution, 1.0)
        set_route_length(new_solution, algorithm.tsp)
        # Decide if new solution should be accepted
        # println("Deciding if new solution should be accepted: $(distance(algorithm.solution)) vs  $(distance(new_solution))")
        if accept_probability(distance(algorithm.solution), distance(new_solution), algorithm.params["temperature"]) > rand()
            algorithm.solution = new_solution
            # println("Accepting new")
        end
        # Update temperature
        algorithm.params["temperature"]  *= (1.0 - algorithm.params["cooling_rate"])
    else # Iteration 0 (Initialization)
        algorithm.solution = algorithm.representation(algorithm.initializer(algorithm.tsp))
        set_route_length(algorithm.solution, algorithm.tsp)
        println("Initializing solution: $(algorithm.solution)")
    end
    return algorithm.solution
end

# ----------------------------------------------------- Utils -----------------------------------------------------

function accept_probability(current_energy::Float64, new_energy::Float64, temperature::Float64)::Float64
    # Found better solution
    if (new_energy < current_energy)
        return 1.0
    end
    # Decide based on probability
    return exp((current_energy - new_energy) / temperature)
end


function check_params(::Type{SimulatedAnnealing}, params::Dict)::Bool
    # Check temperature
    if !check_key(params, "temperature", Real)
        return false
    elseif params["temperature"] <= 0
        println("Temperature has to be value greater than 0, got: $(params["temperature"])")
        return false
    # Check cooling_rate
    elseif !check_key(params, "cooling_rate", Real)
        return false
    elseif !(0 < params["cooling_rate"] < 1)
        println("Cooling rate has to be value between (0, 1) got: $(params["cooling_rate"])")
        return false
    # Mutation
    elseif !check_mutation(params)
        return false
    end
    # Make sure temperature is of type Float64
    params["temperature"] = Float64(params["temperature"])
    # Init
    return check_init(params)
end

is_running(algorithm::SimulatedAnnealing)::Bool = (algorithm.params["temperature"] > 1)


export SimulatedAnnealing



