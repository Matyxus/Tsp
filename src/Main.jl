# --------------------------------------- Main functions --------------------------------------- 

function main(config::String, problem::String, log_name::String = "", gui::Bool = false)::Bool
    println("Main function, got config: $(config), problem: $(problem), log: '$(log_name)', gui: $(gui)")
    solver::Union{Solver, Nothing} = Solver(config, problem)
    println("Successfully initialized solver -> $(!isnothing(solver))!")
    if isnothing(solver)
        return false
    end
    success, run_time = gui ? vizualized_run(solver) : standard_run(solver)
    println("Finished successfully: $(success), run time: $(round(run_time; digits=3))(sec.)")
    if !isempty(log_name)
        save_log(log_name, prepare_data(solver, run_time, log_name), solver.log)
    end
    return success
end

function standard_run(solver::Solver)::Tuple{Bool, Float64}
    println("Starting to iterate with algorithm: $(solver.config["algorithm"]["name"]), max_iters: $(solver.config["settings"]["max_iter"])")
    # Start running algorithm
    best_dist::Float64 = Inf64
    percent::Int64 = floor(solver.config["settings"]["max_iter"] / 10)
    solution::Union{Representation, Nothing} = nothing
    run_time::Float64 = 0.0
    while (solver.iteration != solver.config["settings"]["max_iter"]) && is_running(solver.alg)
        run_time += @elapsed solution = step(solver.alg)
        # Erorr happened
        if isnothing(solution)
            println("Error received invalid solution!")
            break
        elseif distance(solution) < best_dist
            best_dist = distance(solution)
            add_result(solver.log, solver.iteration, best_dist, to_sequence(solution))
        end
        solver.iteration += 1
        if (solver.iteration % percent) == 0
            println("Finished iteration: $(solver.iteration)/$(solver.config["settings"]["max_iter"])")
        end
    end
    if best_dist != Inf64
        println("Finished iterating: $(solver.iteration)/$(solver.config["settings"]["max_iter"]) times.")
        println("Improved initial solution: $(length(solver.log.cache)-1) times.")
        println("Optimal solution: $(solver.alg.tsp.optimal)")
    else
        println("Erorr happend while running algorithm, exiting ...")
        return false, run_time
    end
    return true, run_time
end

function vizualized_run(solver::Solver)::Tuple{Bool, Float64}
    println("Starting to iterate with algorithm: $(solver.config["algorithm"]["name"]), max_iters: $(solver.config["settings"]["max_iter"])")
    # Start running algorithm
    run_time::Float64 = 0.0
    running::Bool = true
    pause::Bool = false
    best_dist::Float64 = Inf64
    solution::Union{Representation, Nothing} = nothing
    # Ignore number of iterations
    gui::GUI = GUI(solver)
    while running && is_running(solver.alg)
        # Extract current values of buttons
        button_values::Dict{String, Bool} = get_buttons(gui)
        # Exit program
        if button_values["Exit"]
            running = false
            break
        end
        # Decide if we are playing or paused
        if pause != button_values["Pause"] # Changed "Pause" state from previous
            pause = !pause
            # Set "Play" to false
            button_values["Play"] = false
            set_button_value(gui, "Play")
        elseif button_values["Play"] # Play was clicked on true, set Pause to false
            button_values["Pause"] = pause = false
            set_button_value(gui, "Pause")
        end
        # Set slider values to algorithm
        slider_values::Dict{String, Union{Int64, Float64}} = get_sliders(gui)
        update_params(solver.alg, slider_values)
        # Either the game is running or its paused and user pressed "step" button
        if button_values["Play"] || (!button_values["Play"] && button_values["Step"])
            run_time += @elapsed solution = step(solver.alg)
            if isnothing(solution)
                println("Error received invalid solution!")
                break
            else
                update_gui(gui, solver, solution)
                if distance(solution) < best_dist
                    best_dist = distance(solution)
                    add_result(solver.log, solver.iteration, best_dist, to_sequence(solution))
                end
            end
            solver.iteration += 1
        end
        # Check if we should continue running
        running = (gui.screen.window_open[] == true)
        # Reset "step" button
        set_button_value(gui, "Step")
        # Sleep
        if slider_values["Step interval"] != 0
            sleep(slider_values["Step interval"] / 1000)
        end
    end
    # Free resources by closing window
    if !isnothing(gui.screen)
        GLMakie.destroy!(gui.screen)
    end
    return true, run_time
end

export main
