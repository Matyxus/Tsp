module Tsp
# Files without dependencies
include("Constants.jl")
include("Loader.jl")
# Structures
include("Representation.jl")
include("Log.jl")
include("Visualization.jl")
# --------- Functions --------- 
include("Initializations.jl")
include("Mutation.jl")
include("Crossover.jl")
# --------- Algorithms --------- 
include("Search.jl")  # Defintion of Structure's, functions for all algorithms
include("SimulatedAnnealing.jl")
include("GeneticAlgorithm.jl")
include("CompleteEnumeration.jl")
# --------- Main --------- 
include("Solver.jl") 
include("Gui.jl")
include("Main.jl")

end


