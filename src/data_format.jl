
struct DDM{T, T2 <: AbstractGNSS}
    constellation :: T2
    prn::Int
    integration_idx::Int
    pvt::PVTSolution
    direct_doppler::Float64
    direct_code_phase::Float64
    incoherent_rounds::Int
    doppler_taps_hz::StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}
    code_taps_samples::UnitRange{Int64}
    power_bins::Matrix{T}
end

struct TrackingSummary{T <: AbstractGNSS}
    constellation :: T
    prn::Int
    channel_id::Int
    acq_delay_samples::Float64
    acq_doppler_hz::Float64
    acq_samplestamp_samples::UInt64
    acq_doppler_step::UInt32
    flag_valid_acquisition::Bool
    fs::Float64
    prompt::ComplexF64
    cn0_db_hz::Float64
    carrier_doppler_hz::Float64
    carrier_phase_rads::Float64
    code_phase_samples::Float64
    tracking_sample_counter::UInt64
    flag_valid_symbol_output::Bool
    correlation_length_ms::Int32
end

function TrackingSummary(trk, channel_id, samplerate)
    return TrackingSummary(
        get_state(trk).system,
        get_state(trk).prn,
        channel_id,
        0.0,
        0.0,
        UInt64(0),
        UInt32(0),
        true,
        samplerate,
        get_prompt(trk),
        ustrip(trk.cn0),
        ustrip(get_carrier_doppler(trk)),
        get_carrier_phase(trk),
        get_code_phase(trk),
        UInt64(0),
        true,
        Int32(1)
    )
end