function truncate(data::DDM, window_size)
    peak = argmax(data.power_bins)[1]
    len = size(data.power_bins)[1]
    lower = clamp(peak - window_size ,1,len)
    upper = clamp(peak + window_size, 1, len)

    DDM(
        data.constellation,
        data.prn,
        data.samples,
        data.rate,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.reflection_point_estimate,
        data.reflection_doppler_estimate,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        lower:upper,
        data.power_bins[lower:upper,:]
    )
end


function truncate(data::DDM, upper_window, lower_window)
    peak = argmax(data.power_bins)[1]
    len = size(data.power_bins)[1]
    lower = clamp(peak - lower_window ,1,len)
    upper = clamp(peak + upper_window, 1, len)

    DDM(
        data.constellation,
        data.prn,
        data.samples,
        data.rate,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.reflection_point_estimate,
        data.reflection_doppler_estimate,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        lower:upper,
        data.power_bins[lower:upper,:]
    )
end


function normalize(data::DDM)
    DDM(
        data.constellation,
        data.prn,
        data.samples,
        data.rate,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.reflection_point_estimate,
        data.reflection_doppler_estimate,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        data.code_taps_samples,
        data.power_bins ./ (data.rate) #TODO: hardcoded
    )
end

function quantize(data::DDM, quantization_func)
    DDM(
        data.constellation,
        data.prn,
        data.samples,
        data.rate,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.reflection_point_estimate,
        data.reflection_doppler_estimate,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        data.code_taps_samples,
        quantization_func.(data.power_bins)
    )

end

function calculate_processed_snr(data::DDM)
    #Scott Gleason formula 6-20
    maxpos = argmax(data.power_bins)
    noise_length = maxpos[1]-100
    noise = Float64.(data.power_bins[1:clamp(noise_length,1,length(data.power_bins[:,1])),:])
    ȳₙ = mean(noise)
    rms = std(noise .- ȳₙ)
    return (maximum(data.power_bins)-ȳₙ) / rms
end
function calculate_absolute_snr(data::DDM)
    #Scott Gleason formula 6-20
    maxpos = argmax(data.power_bins)
    noise_length = maxpos[1]-100
    noise = Float64.(data.power_bins[1:clamp(noise_length,1,length(data.power_bins[:,1])),:])
    ȳₙ = mean(noise)
    return (maximum(data.power_bins)-ȳₙ)/ ȳₙ
end