# using Revise

module Tsp
#
include("Constants.jl")
include("Loader.jl")
# TypeDefs of Representation
include("Representation.jl")
include("Log.jl")
# --------- Vizualization --------- 
include("Vizualization.jl")
include("Gui.jl")
# --------- Functions --------- 
include("Initializations.jl")
include("Mutation.jl")
include("Crossover.jl")
# --------- Algorithms --------- 
include("Search.jl")  # Defintion of Structure's, functions for all algorithms
include("SimulatedAnnealing.jl")
include("GeneticAlgorithm.jl")
include("CompleteEnumeration.jl")
# --------- Main functin --------- 
include("Main.jl")
# println("hello")



end


