import TSPLIB
using Plots


# Plots convergence of method, uses log name as label
function plot_convergence(log_name::String, existing_plot::Union{Plots.Plot{Plots.GRBackend}, Nothing} = nothing)::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Loading log(s): $(log_name)")
    if !check_log(log_name)
        return nothing
    end
    log_config::Dict = load_log(log_name)
    if !isnothing(existing_plot)
        return plot!(existing_plot,
            [data["iteration"] for data in log_config["data"]],
            [data["distance"] for data in log_config["data"]],
            label=log_config["additional_info"]["name"],
        )
    end
    # println("Problem: $(problem.name), solutions: $(length(log_config["data"][begin]["sequence"]))")
    return plot(
        # X, Y
        [data["iteration"] for data in log_config["data"]],
        [data["distance"] for data in log_config["data"]],
        ylabel="Distance",
        xlabel="Evalutations",
        title=log_config["additional_info"]["problem"],
        label=log_config["additional_info"]["name"]
    )
end


# Plots convergence of methods, uses log names as labels
function plot_convergence(log_names::Vector{String})::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Loading logs: $(log_names)")
    if !all(check_log.(log_names))
        return nothing
    end
    p1::Union{Plots.Plot{Plots.GRBackend}, Nothing} = plot_convergence(log_names[1])
    if isnothing(p1)
        return nothing
    end
    problem_name::String = load_log(log_names[1])["additional_info"]["problem"]
    for i in 2:length(log_names)
        p_name::String = load_log(log_names[i])["additional_info"]["problem"]
        if problem_name != p_name
            println("Received logs on different problems: $(problem_name) != $(p_name), cannot display!")
            return nothing
        end
        plot_convergence(log_names[i], p1) 
    end
    return p1
end



# Plots the best found solution with distance
function plot_solution(log_name::String)::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Plotting solution of log: $(log_name)")
    if !check_log(log_name)
        return nothing
    end
    log_config::Dict = load_log(log_name)
    return plot_tour(log_config["additional_info"]["problem"], Vector{Int64}(log_config["data"][begin]["sequence"]))
end

# Plots tour on given problem
function plot_tour(problem::Union{TSPLIB.TSP, String}, tour::Vector{Int64})::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    # Convert to TSP struct
    if isa(problem, String)
        problem = load_problem(problem)
    end
    # Checks
    if isnothing(problem)
        return nothing
    elseif length(unique(tour)) != problem.dimension
        println("Problem: $(problem.name) has $(problem.dimension) cities, but got: $(length(tour)) !")
        return nothing
    elseif iszero(problem.nodes)
        println("Problem: $(problem.name) does not have coordinates!")
        return nothing
    elseif !(all(tour .> 0) && all(tour .< (problem.dimension +1)))
        println("Invalid cities: $(tour), indexes must be larger than 0 and at most: $(problem.dimension)")
        return nothing
    end
    println("Plotting tour of problem: $(problem.name), $(tour)")
    # Make first city also last, to have connection between them
    push!(tour, tour[begin])
    positions::Matrix = problem.nodes[tour, :]
    p1 = plot(positions[:, 1], positions[:, 2]; marker=(:circle,5), legend=false)
    # Remove the appended city
    pop!(tour)
    title!(p1, "Tour: $(problem.name), dist: $(floor(calculate_distance(tour, problem), digits=3))")
    return p1
end


# ----------------------------------------------------- Utils -----------------------------------------------------

function check_log(log_name::String)::Bool
    log_config::Union{Dict, Nothing} = load_log(log_name)
    if isnothing(log_config)
        return false
    elseif !check_key(log_config, "additional_info", Dict)
        return false
    # Data
    elseif !check_key(log_config, "data", Vector)
        return false
    elseif isempty(log_config["data"])
        println("Vector of solutions is empty in: $(log_name)")
        return false
    elseif !check_key(log_config, "input_config", Dict)
        return false
    end
    return true
end

function plot_cities(problem::TSPLIB.TSP)::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    if iszero(problem.nodes)
        println("Problem: $(problem.name) does not have coordinates!")
        return nothing
    end
    return ;
end

function plot_connections(p1::Plots.Plot{Plots.GRBackend}, problem::TSPLIB.TSP, path::Vector{Int64})::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Plotting connections: $(path)")

    
    return 
end



export plot_convergence, plot_solution, plot_tour









