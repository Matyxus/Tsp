using GLMakie

mutable struct MyGraphics
    sliders::Dict{String, Union{Int64, Float64}} # Slider buttons (mapping label to value)
    buttons::Dict{String, Bool} # Buttons (mapping label to on/off bool)
    axis::Any  # Axis containing current best found cities sequence
    lines::Union{Any, Nothing}  # Lines containing current best found cities sequence
    best_axis::Any # Axis containing overall best found cities sequence
    best_lines::Union{Any, Nothing} # Lines containing overall best found cities sequence
    info_label_values::Dict{String, Any}    # Info labels containing information about current & overall best found cities sequence
end

mutable struct GUI
    graphics::MyGraphics
    screen::Any # The current screen
end

function GUI(solver::Solver)::GUI
    println("Initializing GUI ...")
    # ------------------------- Figure --------------------------
    figure::Makie.Figure = init_figure(solver.config, get_tsp(solver.alg).name)
    # -------------------------- Grids --------------------------
    axis_grid = figure[1, 1] = GridLayout()
    button_grid = figure[2, 1:2] = GridLayout()
    slider_grid = figure[3, 1:2] = GridLayout()
    best_found_grid = figure[1, 2] = GridLayout()
    best_label_grid = best_found_grid[1, 1] = GridLayout()
    best_axis_grid = best_found_grid[1, 2] = GridLayout()
    # ------------------ Current & Best Route -------------------
    axis, best_axis = init_axis(solver, axis_grid, best_axis_grid)
    # ------------------------- Sliders -------------------------
    sliders, slider_objects = init_sliders(solver, slider_grid)
    # ------------------------- Buttons -------------------------
    buttons, button_objects = init_buttons(button_grid)
    # ------------------ Button functionality -------------------
    # Remember the order of sliders and their values
    slider_labels::Vector{String} = append!(["Step interval"], collect(keys(get_alg_sliders(solver.alg))))
    slider_values::Vector{Union{Int64, Float64}} = [sliders[slider_label] for slider_label in slider_labels]
    for i in eachindex(BUTTON_LABELS)
        on(button_objects[i].clicks) do click
            buttons[BUTTON_LABELS[i]] = true
            if BUTTON_LABELS[i] == "Default"
                set_slider_default_values(slider_values, slider_objects)
            end
        end
    end
    # ------------------------- Labels --------------------------
    info_label_values = init_labels(best_label_grid)
    # ---------------------- Constructors -----------------------
    graphics = MyGraphics(sliders, buttons, axis, nothing, best_axis, nothing, info_label_values)
    return GUI(graphics, display(figure))
end

# ---------------------------- Init GUI -----------------------------

function init_figure(params::Dict{String, Any}, problem_name::String)::Makie.Figure
    set_theme!(theme_dark())
    resolution::Tuple = !check_gui(params) ? (WIDTH, HEIGHT) : (params["gui"]["width"], params["gui"]["height"])
    figure::Makie.Figure = Figure(resolution = resolution)
    name_label::String = "Traveling Salesman - " * problem_name * " - " * params["algorithm"]["name"]
    figure[0, 1:2] = Label(figure, name_label, fontsize = 30)
    return figure
end

function init_axis(solver::Solver, axis_grid::Makie.GridLayout, best_axis_grid::Makie.GridLayout)::Tuple{Makie.Axis, Makie.Axis}
    # ---------------------- City Coordinates -----------------------
    x_coords = get_tsp(solver.alg).nodes[:, 1]
    y_coords = get_tsp(solver.alg).nodes[:, 2]
    # ------------------------- Axis Limits -------------------------
    x_max = maximum(x_coords) + AXIS_OFFSET
    x_min = minimum(x_coords) - AXIS_OFFSET
    y_max = maximum(y_coords) + AXIS_OFFSET
    y_min = minimum(y_coords) - AXIS_OFFSET
    # ------------------------ Current Route ------------------------
    axis = Axis(axis_grid[1, 1], title = "Current Route", xlabel = "x", ylabel = "y")
    GLMakie.xlims!(axis, x_min, x_max)
    GLMakie.ylims!(axis, y_min, y_max)
    GLMakie.scatter!(axis, x_coords, y_coords, markersize = 5, color = :blue)
    # ------------------------- Best Route --------------------------
    best_axis = Axis(best_axis_grid[1, 1], title = "Best route", xlabel = "x", ylabel = "y")
    GLMakie.xlims!(best_axis, x_min, x_max)
    GLMakie.ylims!(best_axis, y_min, y_max)
    GLMakie.scatter!(best_axis, x_coords, y_coords, markersize = 5, color = :blue)
    return axis, best_axis
end

function init_sliders(solver::Solver, slider_grid::Makie.GridLayout)::Tuple{Dict{String, Union{Int, Float64}}, Vector{Makie.Slider}}
    # Sliders specific to algorithm
    sliders_array::Vector{Any} = []
    for (key, vals) in get_alg_sliders(solver.alg)
        # If step size is float, add format
        if isa(vals[3], Float64)
            push!(
                sliders_array, 
                (label = key, range = vals[1]:vals[3]:vals[2], startvalue = vals[end], format = x -> string(round(x, digits=3)))
            )
        else
            push!(sliders_array, (label = key, range = vals[1]:vals[3]:vals[2], startvalue = vals[end]))
        end
    end
    # For complete enemuration we must have sleeping, otherwise the window
    # gets updated too often
    min_sleep::Int64 = isa(solver.alg, CompleteEnumeration) ? 1 : 0
    # All sliders
    slider_grid_object::Makie.SliderGrid = SliderGrid(
        slider_grid[1, 1],
        # Slider for the amount of sleeping time between rendering
        (label = "Step interval", range = min_sleep:1:1000, startvalue=150, format = x -> string(x, " ms")),
        sliders_array...
    )
    slider_objects = slider_grid_object.sliders
    slider_observables::Vector{Observable} = [s.value for s in slider_objects]
    slider_labels::Vector{String} = append!(["Step interval"], collect(keys(get_alg_sliders(solver.alg))))
    sliders = Dict{String, Union{Int64, Float64}}(slider_labels .=> [[150]; [val[end] for val in values(get_alg_sliders(solver.alg))]])
    # -------------------- Slider functionality ---------------------
    for i in eachindex(slider_labels)
        on(slider_observables[i]) do value
            sliders[slider_labels[i]] = value
        end
    end
    return sliders, slider_objects
end

function init_buttons(button_grid::Makie.GridLayout)::Tuple{Dict{String, Bool}, Vector{Makie.Button}}
    button_objects = [
        Button(button_grid[1, index], label = label)
        for (index, label) in enumerate(BUTTON_LABELS)
    ]
    buttons = Dict{String, Bool}(
        BUTTON_LABELS .=> falses(length(BUTTON_LABELS))
    )
    return buttons, button_objects
end

function init_labels(best_label_grid::Makie.GridLayout)::Dict{String, Observable}
    label_values = Observable.(LABEL_STARTING_VALUES)
    info_labels = [
        Label(best_label_grid[index, 1], @lift(label * string($(value))))
        for (index, (label, value)) in enumerate(zip(LABEL_LABELS, label_values))
    ]
    info_label_values = Dict{String, Observable}(
        LABEL_LABELS .=> label_values
    )
    return info_label_values
end

# ------------------------ Setters & Getters ------------------------

function get_sliders(gui::GUI)::Dict{String, Union{Int, Float64}}
    return gui.graphics.sliders
end

function get_buttons(gui::GUI)::Dict{String, Bool}
    return gui.graphics.buttons
end

"""
    set_button_value(gui::GUI, button_label::String, on::Bool = false)::Nothing

    Sets button value to the given value (true - pressed or false - not pressed)

# Arguments
- `gui::GUI`: current struct representing GUI
- `button_label::String`: name of the button
- `on::Bool`: true if button is pressed, false by default

`Returns` Nothing
"""
function set_button_value(gui::GUI, button_label::String, on::Bool = false)::Nothing
    gui.graphics.buttons[button_label] = on
    return
end

# Sets all buttons as not pressed
function initialize_button_values(gui::GUI)::Nothing
    gui.graphics.buttons = Dict{String, Bool}(
        BUTTON_LABELS .=> falses(length(BUTTON_LABELS))
    )
    return
end

# ---------------------- Button functionality -----------------------

function set_slider_default_values(default_sliders::Vector{Union{Float64, Int64}}, sliders::Vector{Makie.Slider})
    for (i, value) in enumerate(default_sliders)
        set_close_to!(sliders[i], value)
    end
end

# --------------------------- Update GUI ----------------------------

function update_route(axis::Makie.Axis, lines::Union{Makie.Lines, Nothing}, x_coords::Vector{ <: Real}, y_coords::Vector{ <: Real})
    if !isnothing(lines)
        delete!(axis.scene, lines)
    end
    return lines!(axis, x_coords, y_coords, color = :green)
end

function update_gui(gui::GUI, solver::Solver, current::Representation)::Nothing
    best_solution::Union{Tuple{Int64, Float64, Vector{Int64}}, Nothing} = get_best(solver.log)

    tour::Vector{Int64} = to_sequence(current)
    push!(tour, tour[begin])  # Add last city for connection
    positions::Matrix = get_tsp(solver.alg).nodes[tour, :]
    pop!(tour) # Remove last added city
    x_coords = positions[:, 1]
    y_coords = positions[:, 2]
    # Update current, if its not equal to the one currently rendered
    if isnothing(best_solution) || gui.graphics.info_label_values["Current distance: "][] != round(distance(current); digits=3)
        gui.graphics.lines = update_route(gui.graphics.axis, gui.graphics.lines, x_coords, y_coords)
        gui.graphics.info_label_values["Current distance: "][] = round(distance(current); digits=3)
    end
    gui.graphics.info_label_values["Iteration: "][] += 1
    # Update best
    if isnothing(best_solution) || distance(current) < best_solution[2]
        gui.graphics.best_lines = update_route(gui.graphics.best_axis, gui.graphics.best_lines, x_coords, y_coords)
        gui.graphics.info_label_values["Best distance: "][] = round(distance(current); digits=3)
    end
    return
end

# --------------------------- Utils ----------------------------

function check_gui(config::Dict)::Bool
    # Check config
    if !check_key(config, "gui")
        return false
    elseif !check_key(config["gui"], "width", Int64)
        return false
    elseif 0 >= config["gui"]["width"]
        println("Width of gui has to be grater than 0, got: $(config["gui"]["width"])")
        return false
    elseif !check_key(config["gui"], "height", Int64)
        return false
    elseif 0 >= config["gui"]["height"]
        println("Height of gui has to be grater than 0, got: $(config["gui"]["height"])")
        return false
    end
    return true
end


export GUI, update_gui
