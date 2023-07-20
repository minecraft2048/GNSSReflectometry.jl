
struct DDM{T, T2 <: AbstractGNSS}
    prn::Int
    samples::Int
    rate::Float64
    pvt::PVTSolution
    direct_doppler::Float64
    direct_code_phase::Float64
    reflection_point_estimate::ECEF{Float64}
    reflection_doppler_estimate::Float64
    incoherent_rounds::Int
    doppler_taps_hz::StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}
    code_taps_samples::UnitRange{Int64}
    power_bins::Matrix{T}
end

#from old constructor

function DDM(
    constellation::T1,
    prn::Int,
    samples::Int,
    rate::Float64,
    pvt::PVTSolution,
    direct_doppler::Float64,
    direct_code_phase::Float64,
    reflection_point_estimate::ECEF{Float64},
    reflection_doppler_estimate::Float64,
    incoherent_rounds::Int,
    doppler_taps_hz::StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64},
    code_taps_samples::UnitRange{Int64},
    power_bins::Matrix{T},
) where {T,T1<:AbstractGNSS}

return  DDM{T,T1}(
        prn,
        samples,
        rate,
        pvt,
        direct_doppler,
        direct_code_phase,
        reflection_point_estimate,
        reflection_doppler_estimate,
        incoherent_rounds,
        doppler_taps_hz,
        code_taps_samples,
        power_bins
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