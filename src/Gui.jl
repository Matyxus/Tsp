using GLMakie

mutable struct MyGraphics
    sliders::Dict{String, Union{Int, Float64}} # Slider buttons (mapping label to value)
    buttons::Dict{String, Bool} # Buttons (mapping label to on/off bool)
    axis::Any  # Axis containing current best found cities sequence
    lines::Union{Any, Nothing}  # Lines containing current best found cities sequence
    best_axis::Any # Axis containing overall best found cities sequence
    best_lines::Union{Any, Nothing} # Lines containing overall best found cities sequence
    info_label_values::Dict{String, Any}    # Info labels containing information about current & overall best found cities sequence
end

mutable struct GUI
    graphics::MyGraphics
    screen::Any
end

export get_sliders, get_buttons, set_button_value, set_button_values, update_gui


function GUI(params::Dict{String, Any})::GUI
    # ------------------------- Figure --------------------------
    figure = init_figure(params)

    # -------------------------- Grids --------------------------
    axis_grid = figure[1, 1] = GridLayout()
    button_grid = figure[2, 1:2] = GridLayout()
    slider_grid = figure[3, 1:2] = GridLayout()
    best_found_grid = figure[1, 2] = GridLayout()

    best_label_grid = best_found_grid[1, 1] = GridLayout()
    best_axis_grid = best_found_grid[1, 2] = GridLayout()

    # ------------------ Current & Best Route -------------------
    axis, best_axis = init_axis(params, axis_grid, best_axis_grid)

    # ------------------------- Sliders -------------------------
    sliders, slider_objects = init_sliders(params, slider_grid)

    # ------------------------- Buttons -------------------------
    buttons, button_objects = init_buttons(button_grid)

    # ------------------ Button functionality -------------------
    for i in eachindex(BUTTON_LABELS)
        on(button_objects[i].clicks) do click
            buttons[BUTTON_LABELS[i]] = true

            if BUTTON_LABELS[i] == "Default"
                set_slider_default_values(params["algorithm"]["params"], collect(keys(params["gui"]["sliders"])), slider_objects)
            elseif BUTTON_LABELS[i] == "Clear & Reset"
                set_slider_default_values(params["algorithm"]["params"], collect(keys(params["gui"]["sliders"])), slider_objects)
                clear_routes(graphics, data)
            end
            
            # println("New value of $(BUTTON_LABELS[i]) is $(buttons[BUTTON_LABELS[i]])")
        end
    end

    # ------------------------- Labels --------------------------
    info_label_values = init_labels(best_label_grid)

    # ---------------------- Constructors -----------------------
    sc = display(figure)

    graphics = MyGraphics(sliders, buttons, axis, nothing, best_axis, nothing, info_label_values)
    GUI(graphics, sc)
end



# ---------------------------- Init GUI -----------------------------
function init_figure(params::Dict{String, Any})::Makie.Figure
    set_theme!(theme_dark())
    resolution = (params["gui"]["height"], params["gui"]["width"])
    figure = Figure(resolution = resolution)

    name_label = "Traveling Salesman - " * params["setting"]["problem_name"] * " - " * params["algorithm"]["name"]
    figure[0, 1:2] = Label(figure, name_label, fontsize = 30)

    return figure
end

function init_axis(params::Dict{String, Any}, axis_grid::Makie.GridLayout, best_axis_grid::Makie.GridLayout)::Tuple{Makie.Axis, Makie.Axis}
    # ------------------------- City Labels -------------------------
    city_labels = collect(keys(params["cities"]["position"]))
    starting_city = params["cities"]["start"]
    city_labels_without_start = [label for label in city_labels if label != starting_city]

    # ---------------------- City Coordinates -----------------------
    x_start = params["cities"]["position"][starting_city][1]
    y_start = params["cities"]["position"][starting_city][2]

    x_coords = [params["cities"]["position"][label][1] for label in city_labels_without_start]
    y_coords = [params["cities"]["position"][label][2] for label in city_labels_without_start]

    # ------------------------- Axis Limits -------------------------
    x_max = maximum([x_start; x_coords]) + AXIS_OFFSET
    x_min = minimum([x_start; x_coords]) - AXIS_OFFSET

    y_max = maximum([y_start; y_coords]) + AXIS_OFFSET
    y_min = minimum([y_start; y_coords]) - AXIS_OFFSET

    # ------------------------ Current Route ------------------------
    axis = Axis(axis_grid[1, 1], title = "Current Route", xlabel = "x", ylabel = "y")

    xlims!(axis, x_min, x_max)
    ylims!(axis, y_min, y_max)

    scatter!(axis, x_start, y_start, markersize = 15, color = :red)
    scatter!(axis, x_coords, y_coords, markersize = 15, color = :blue)
    text!(axis, Point.(x_coords .+ TEXT_OFFSET, y_coords .+ TEXT_OFFSET), text = city_labels_without_start)
    text!(axis, Point.(x_start + TEXT_OFFSET, y_start + TEXT_OFFSET), text = starting_city)

    # ------------------------- Best Route --------------------------
    best_axis = Axis(best_axis_grid[1, 1], title = "Best route", xlabel = "x", ylabel = "y")

    xlims!(best_axis, x_min, x_max)
    ylims!(best_axis, y_min, y_max)

    scatter!(best_axis, x_start, y_start, markersize = 15, color = :red)
    scatter!(best_axis, x_coords, y_coords, markersize = 15, color = :blue)
    text!(best_axis, Point.(x_coords .+ TEXT_OFFSET, y_coords .+ TEXT_OFFSET), text = city_labels_without_start)
    text!(best_axis, Point.(x_start + TEXT_OFFSET, y_start + TEXT_OFFSET), text = starting_city)

    return axis, best_axis
end

function init_sliders(params::Dict{String, Any}, slider_grid::Makie.GridLayout)::Tuple{Dict{String, Union{Int, Float64}}, Vector{Makie.Slider}}
    sliders_array::Array{Any} = []

    for (key, value) in params["gui"]["sliders"]
        default_value = params["algorithm"]["params"][key]

        if isa(value[3], Float64)
            push!(
                sliders_array, 
                (label = key, range = value[1]:value[3]:value[2], startvalue = default_value, format = x -> string(round(100 * x, digits=3), " %"))
            )
        else
            push!(sliders_array, (label = key, range = value[1]:value[3]:value[2], startvalue = default_value))
        end
    end

    slider_grid_object = SliderGrid(slider_grid[1, 1],
        (label = "Step interval", range = 0:1:1000, startvalue=150, format = x -> string(x, " ms")),
        sliders_array...
    )

    slider_objects = slider_grid_object.sliders
    slider_observables = [s.value for s in slider_objects]

    slider_labels = append!(["Step interval"], collect(keys(params["gui"]["sliders"])))
    sliders = Dict{String, Union{Int, Float64}}(slider_labels .=> zeros(length(slider_labels)))

    # -------------------- Slider functionality ---------------------
    for i in eachindex(slider_labels)
        if slider_labels[i] != "Step interval"
            sliders[slider_labels[i]] = params["algorithm"]["params"][slider_labels[i]]
        end

        on(slider_observables[i]) do value
            # println("New value of $(slider_labels[i]) is $value")
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
    print(label_values)

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

function set_button_value(gui::GUI, button_label::String)
    gui.graphics.buttons[button_label] = false
end

function set_button_values(gui::GUI)
    gui.graphics.buttons = Dict{String, Bool}(
        BUTTON_LABELS .=> falses(length(BUTTON_LABELS))
    )
end

# ---------------------- Button functionality -----------------------

function set_slider_default_values(default_sliders::Dict{String, Any}, slider_labels::Vector{String}, sliders::Vector{Makie.Slider})
    for i in eachindex(slider_labels)
        set_close_to!(sliders[i + 1], default_sliders[slider_labels[i]])
    end
end

function clear_routes(graphics::MyGraphics, data::MyData)
    if !isnothing(graphics.lines)
        delete!(graphics.axis.scene, graphics.lines)
    end
    if !isnothing(graphics.best_lines)
        delete!(graphics.best_axis.scene, graphics.best_lines)
    end

    graphics.lines = nothing
    graphics.best_lines = nothing

    for i in eachindex(LABEL_LABELS)
        graphics.info_label_values[LABEL_LABELS[i]][] = LABEL_STARTING_VALUES[i]
    end

    data.best_entry = nothing
end

# --------------------------- Update GUI ----------------------------

function update_route(axis::Makie.Axis, lines::Union{Makie.Lines, Nothing}, x_coords::Vector{Int}, y_coords::Vector{Int})
    if !isnothing(lines)
        delete!(axis.scene, lines)
    end

    return lines!(axis, x_coords, y_coords, color = :green)
end

function update_gui(gui::GUI, log::Log)::Nothing
    ordered_cities = split(data["best"], "-")

    x_coords = [gui.data.cities[label][1] for label in ordered_cities]
    y_coords = [gui.data.cities[label][2] for label in ordered_cities]
    
    gui.graphics.lines = update_route(gui.graphics.axis, gui.graphics.lines, x_coords, y_coords)

    gui.graphics.info_label_values["Current iteration: "][] += 1
    gui.graphics.info_label_values["Current shortest distance: "][] = round(data["distance"], 3)
    gui.graphics.info_label_values["Current best: "][] = round(data["best"], 3)
    

    if isnothing(gui.data.best_entry) || data["distance"] < gui.data.best_entry["distance"]
        gui.data.best_entry = data

        gui.graphics.best_lines = update_route(gui.graphics.best_axis, gui.graphics.best_lines, x_coords, y_coords)

        gui.graphics.info_label_values["Best distance: "][] = round(data["distance"], 3)
        gui.graphics.info_label_values["Best: "][] = round(data["best"], 3)
    end
    return
end

