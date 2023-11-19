using Plots

"""
    plot_convergence(log_name::String, existing_plot::Union{Plots.Plot{Plots.GRBackend}, Nothing} = nothing)::Union{Plots.Plot{Plots.GRBackend}, Nothing}

    Plots the algorithm run, where X axis corresponds to the number of iterations, Y to the tour length achieved.
    If given multiple 'log_names', plots all into one plot.

# Arguments
- `log_name::String`: name of result/log file
- `existing_plot::Union{Plots.Plot{Plots.GRBackend}, Nothing} = nothing`: plot of previous result/log file

`Returns` Plot of algorithm run, nothing if erorr occurred
"""
function plot_convergence(log_name::String, existing_plot::Union{Plots.Plot{Plots.GRBackend}, Nothing} = nothing)::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Loading log: $(log_name) ...")
    if !check_log(log_name)
        return nothing
    end
    log_config::Dict = load_log(log_name)
    if !isnothing(existing_plot)
        return Plots.plot!(existing_plot,
            [data["iteration"] for data in log_config["data"]],
            [data["distance"] for data in log_config["data"]],
            label=log_config["additional_info"]["name"],
        )
    end
    # println("Problem: $(problem.name), solutions: $(length(log_config["data"][begin]["sequence"]))")
    return Plots.plot(
        # X, Y
        [data["iteration"] for data in log_config["data"]],
        [data["distance"] for data in log_config["data"]],
        ylabel="Distance",
        xlabel="Evalutations",
        title=log_config["additional_info"]["problem"],
        label=log_config["additional_info"]["name"]
    )
end

# Plots convergence of multiple methods
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


"""
    function plot_solution(log_name::String)::Union{Plots.Plot{Plots.GRBackend}, Nothing}

    Plots the best tour (connection between cities) of given result/log file.

# Arguments
- `log_name::String`: name of result/log file

`Returns` the plot of cities connecitons, nothing if error occurred
"""
function plot_solution(log_name::String)::Union{Plots.Plot{Plots.GRBackend}, Nothing}
    println("Plotting solution of log: $(log_name)")
    if !check_log(log_name)
        return nothing
    end
    log_config::Dict = load_log(log_name)
    return plot_tour(log_config["additional_info"]["problem"], Vector{Int64}(log_config["data"][begin]["sequence"]))
end


"""
    function plot_tour(problem::Union{TSP, String}, tour::Vector{Int64})::Union{Plots.Plot{Plots.GRBackend}, Nothing}

    Plots the given tour (connection between cities).

# Arguments
- `problem::Union{TSP, String}`: name of the TSP problem or its structure
- `tour::Vector{Int64}`: tour over cities (must be given as city indexes [1, ...., N])

`Returns` the plot of cities connecitons, nothing if error occurred
"""
function plot_tour(problem::Union{TSP, String}, tour::Vector{Int64})::Union{Plots.Plot{Plots.GRBackend}, Nothing}
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
    # println("Plotting tour of problem: $(problem.name), $(tour)")
    # Make first city also last, to have connection between them
    push!(tour, tour[begin])
    positions::Matrix = problem.nodes[tour, :]
    p1 = Plots.plot(positions[:, 1], positions[:, 2]; marker=(:circle,5), legend=false)
    # Remove the appended city
    pop!(tour)
    Plots.title!(p1, "Tour: $(problem.name), dist: $(floor(calculate_distance(tour, problem), digits=3))")
    return p1
end

# Saves plot as image
"""
    save_plot(fig::Plots.Plot{Plots.GRBackend}, file_path::String)

    Saves the given plot in the given file (PNG).

# Arguments
- `fig::Plots.Plot{Plots.GRBackend}`: plot to be saved
- `file_path::String`: path to the file

`Returns` nothing
"""
function save_plot(fig::Plots.Plot{Plots.GRBackend}, file_path::String)
    return Plots.savefig(fig, file_path)
end


# ----------------------------------------------------- Utils -----------------------------------------------------
# Checks if the logs strucure is correctly given
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

export plot_convergence, plot_solution, plot_tour, save_plot



