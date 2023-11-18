module Tsp
#
include("Constants.jl")
include("Loader.jl")
# TypeDefs of Representation
include("Representation.jl")
include("Log.jl")
include("Vizualization.jl")
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


