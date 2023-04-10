module GNSSReflectometry

using JuMP
using PositionVelocityTime
using Plots
using Geodesy
using AstroTime
using Acquisition
using TerminalLoggers
using ProgressLogging
using Unitful
using GNSSSignals
using FLoops
using Tracking
using GNSSDecoder


include("data_format.jl")
export DDM, TrackingSummary

include("visualization.jl")
export heatmap, plot

include("steering_algorithms.jl")
export find_specular_point!, find_specular_point_c, setup_specular_problem!, passthrough,specular_tracking_ipopt

include("dsp.jl")
export calculate_DDM, calculate_DDM_2, calculate_DDM_3

include("navigate.jl")
export navigate

include("postprocessing.jl")
export truncate, quantize, normalize

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{GNSSReflectometry.var"#126#threadsfor_fun#10"{GNSSReflectometry.var"#126#threadsfor_fun#9#11"{Core.Float64, Unitful.FreeUnits{(Hz,), 𝐓^-1, nothing}, Base.Vector{Tracking.TrackingState}, Base.Vector{Tracking.TrackingResults}, Base.OneTo{Core.Int64}}},Int64})   # time: 8.247356
    Base.precompile(Tuple{GNSSReflectometry.var"##reducing_function#344#13"{Core.Float64, Unitful.FreeUnits{(Hz,), 𝐓^-1, nothing}, Base.Vector{GNSSDecoder.GNSSDecoderState{GNSSDecoder.GPSL1Data, GNSSDecoder.GPSL1Constants, GNSSDecoder.GPSL1Cache, GNSSDecoder.UInt320}}, Base.Vector{Tracking.TrackingResults}, Unitful.Quantity{Core.Float64, 𝐓^-1, Unitful.FreeUnits{(Hz,), 𝐓^-1, nothing}}, Base.Vector{Base.ComplexF64}},Tuple{},Int64})   # time: 1.9150969
    Base.precompile(Tuple{Type{TrackingSummary},Tracking.TrackingResults,Int64,Any})   # time: 0.007682894
    Base.precompile(Tuple{var"##context_function#347#15"})   # time: 0.007587403
end

end # module GNSSReflectometry
