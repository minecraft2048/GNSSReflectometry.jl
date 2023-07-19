
struct DDM{T, T2 <: AbstractGNSS}
    constellation :: T2
    prn::Int
    samples::Int
    rate::Float64
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

function Base.show(io::IO, ::MIME"text/plain",data::DDM)
    println(io,"DDM for PRN $(data.prn) at $(data.pvt.time):")
    println(io,"Receiver position:")
    lla = get_LLA(data.pvt)
    println(io,"    lat: $(lla.lat) lon: $(lla.lon), alt:$(lla.alt)")
    println(io,"Direct signal parameters")
    println(io,"    Delay: $(data.direct_code_phase) samples")
    println(io,"    Doppler: $(data.direct_doppler) Hz")
    println(io,"Reflection point estimate:")
    println(io,"    Reflection point position:")
    lla_ref = LLAfromECEF(wgs84)(data.reflection_point_estimate)
    antenna_refl =   data.pvt.position - data.reflection_point_estimate 
    aa = argmax(data.power_bins)
    println(io,"    lat: $(lla_ref.lat) lon: $(lla_ref.lon), alt:$(lla_ref.alt)")
    println(io,"    (antenna boresight angle: $(90 + rad2deg(get_sat_enu(data.pvt.position, data.reflection_point_estimate).ϕ))°)")
    println(io,"    Reflection point doppler: $(data.reflection_doppler_estimate) Hz")
    println(io,"    Peak delay:   $(aa[1]) samples")
    println(io,"    Peak doppler: $(data.doppler_taps_hz[aa[2]] + data.reflection_doppler_estimate) Hz")

    println(io,"Metrics:")
    println(io,"    Processed SNR: $(10*log10(calculate_processed_snr(data))) dB")
    println(io,"    Absolute SNR: $(10*log10(calculate_absolute_snr(data))) dB")
    

end