module GNSSReflectometry

using JuMP
using PositionVelocityTime
using Geodesy
using AstroTime
using Acquisition
using TerminalLoggers
using ProgressLogging
using Unitful
using GNSSSignals
using FLoops
using GNSSDecoder
using JSON
using PrecompileTools
using Statistics
using LinearAlgebra

include("data_format.jl")
export DDM, TrackingSummary, DDM2

include("steering_algorithms.jl")
export find_specular_point!, find_specular_point_c, setup_specular_problem!, passthrough,specular_tracking_ipopt,specular_tracking_loop

include("dsp.jl")
export calculate_DDM, calculate_DDM_2, calculate_DDM_3

#include("navigate.jl")
#export navigate

include("postprocessing.jl")
export truncate, quantize, normalize,calculate_processed_snr,calculate_absolute_snr

include("serde.jl")
export write_json

end # module GNSSReflectometry
