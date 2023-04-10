function truncate(data::DDM, window_size)
    peak = argmax(data.power_bins)[1]
    len = size(data.power_bins)[1]
    lower = clamp(peak - window_size ,1,len)
    upper = clamp(peak + window_size, 1, len)

    DDM(
        data.constellation,
        data.prn,
        data.integration_idx,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
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
        data.integration_idx,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
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
        data.integration_idx,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        data.code_taps_samples,
        data.power_bins ./ 16367000 #TODO: hardcoded
    )
end

function quantize(data::DDM, quantization_func)
    DDM(
        data.constellation,
        data.prn,
        data.integration_idx,
        data.pvt,
        data.direct_doppler,
        data.direct_code_phase,
        data.incoherent_rounds,
        data.doppler_taps_hz,
        data.code_taps_samples,
        quantization_func.(data.power_bins)
    )

end