function calculate_DDM(signal,nav_results,ncoh_rounds, doppler_window, doppler_step, niters; steering_strategy = GNSSReflectometry.passthrough, userdata = nothing, intermediate_freq=0)
    ddms = Vector{DDM}()
    out = nav_results
    @progress for i = 1:100:(niters*100)
        sig = read(signal, ncoh_rounds * 1u"ms")
        for j = 1:3
            prn=out[i][2][j].prn
            doppler,code_delay = steering_strategy((out[i][2][j],), (out[i][3], out[i+1][3]), prn, userdata)
            #doppler = ustrip(out[i][2][j].state.carrier_doppler)
            doppler_taps = doppler-doppler_window:doppler_step:doppler+doppler_window
            ddm = noncoherent_integrate(sig,prn,ncoh_rounds, (doppler_taps)*u"Hz";intermediate_freq=intermediate_freq, compensate_doppler_code=true)
            ddm_with_metadata = DDM(
                GPSL1(), #todo derive this
                prn,
                out[i][1],
                out[i][3],
                doppler,
                out[i][2][j].code_phase_samples,
                ncoh_rounds,
                doppler_taps,
                1:size(ddm)[1],
                ddm
            )
            append!(ddms, [ddm_with_metadata])
        end
    end
    return ddms
    #test
end

