function Plots.heatmap(ddm::DDM)
    return heatmap(ddm.doppler_taps_hz,ddm.code_taps_samples,ddm.power_bins; title="PRN $(ddm.prn) at $(ddm.pvt.time)", xlabel="Doppler (Hz)", ylabel="Delay (samples)")
end
function Plots.plot(ddm::DDM)
    pos = argmax(ddm.power_bins)
    println(pos)
    xsize = size(ddm.power_bins)[1]
    index = Int(clamp(pos[1]-100,1,xsize)):Int(clamp(pos[1]+100,1,xsize))
    return plot(index,ddm.power_bins[index,pos[2]]; title="PRN $(ddm.prn) at $(ddm.pvt.time)", xlabel="Delay (samples)", ylabel="Power")
end