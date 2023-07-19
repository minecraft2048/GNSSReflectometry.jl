#= function calculate_DDM(signal,nav_results,ncoh_rounds, doppler_window, doppler_step, niters; steering_strategy = GNSSReflectometry.passthrough, userdata = nothing, intermediate_freq=0)
    ddms = Vector{DDM}()
    out = nav_results
    @progress for i = 1:100:(niters*100)
        sig = read(signal, ncoh_rounds * 1u"ms")
        for prn in keys(out[i][3].sats)
            #prn=out[i][2][j].prn
            doppler,code_delay = steering_strategy((out[i][2][prn],), (out[i][3], out[i+1][3]), prn, userdata)
            #doppler = ustrip(out[i][2][j].state.carrier_doppler)
            doppler_taps = doppler-doppler_window:doppler_step:doppler+doppler_window
            ddm = noncoherent_integrate(sig,prn,ncoh_rounds, (doppler_taps)*u"Hz";intermediate_freq=intermediate_freq, compensate_doppler_code=true)
            ddm_with_metadata = DDM(
                GPSL1(), #todo derive this
                prn,
                out[i][1],
                out[i][3],
                doppler,
                out[i][2][prn].code_phase_samples,
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
 =#
function calculate_DDM(signal,sample_rate, nav_results,ncoh_rounds::Int, doppler_window::Int, doppler_step::Int,; niters = nothing,  steering_strategy = GNSSReflectometry.passthrough, 
    userdata = nothing, intermediate_freq=0, compensate_doppler_code=false,
    postprocessing_callback=x->x,
    reflection_selection_callback=x->x)

    first_nav_idx = findfirst(x->!isnothing(x[3].time),nav_results)

    if isnothing(niters)
        niters = Int(fld(lastindex(nav_results) - first_nav_idx, 100))
    end


    prns = collect(keys(nav_results[first_nav_idx][3].sats))
    result_all = []
    result_single = Vector{DDM}(undef, length(prns))

    clock_drifts = Vector{Float64}(undef,100)
    dopplers =  Vector{Float64}(undef,100)

    sig_1ms = Int(fld(sample_rate,1000))
    Hz = u"Hz"

    plan = AcquisitionPlan(
        GPSL1(),
        sig_1ms,
        sample_rate*1.0*Hz;
        dopplers = -doppler_window*Hz:doppler_step*Hz:doppler_window*Hz,
        compensate_doppler_code = true
    )

    good_nav = @view nav_results[first_nav_idx:(first_nav_idx+niters*100 - 1)]

    for navslice in Iterators.partition(good_nav, 100)
        #println(navslice[1])
        result_single = []
        for (idx,prn) in enumerate(prns)
            doppler,_,specular_position = steering_strategy(nothing,navslice,prn,userdata)
            
            res = noncoherent_integrate!(signal[navslice[1][1]:navslice[1][1]+Int(sample_rate)], prn, ncoh_rounds,doppler, plan; intermediate_freq=intermediate_freq,compensate_doppler_code=compensate_doppler_code)

            res = DDM(
                GPSL1(),
                prn,
                navslice[1][1],
                sample_rate,
                navslice[1][3],
                navslice[1][2][prn].carrier_doppler_hz,
                navslice[1][2][prn].code_phase_samples,
                ECEF(specular_position),
                doppler,
                ncoh_rounds,
                -doppler_window*1.0:doppler_step:doppler_window,
                0:size(res)[1]-1,
                res
            ) |> postprocessing_callback

            append!(result_single,[res])

        end

        append!(result_all,[result_single])

    end
#=     @progress for i = 1:100:(niters*100)
        sig = read(signal, ncoh_rounds * 1u"ms")
        for prn in keys(out[i][3].sats)
            #prn=out[i][2][j].prn
            doppler,code_delay = steering_strategy((out[i][2][prn],), (out[i][3], out[i+1][3]), prn, userdata)
            #doppler = ustrip(out[i][2][j].state.carrier_doppler)
            doppler_taps = doppler-doppler_window:doppler_step:doppler+doppler_window
            ddm = noncoherent_integrate(sig,prn,ncoh_rounds, (doppler_taps)*u"Hz";intermediate_freq=intermediate_freq, compensate_doppler_code=true)
            ddm_with_metadata = DDM(
                GPSL1(), #todo derive this
                prn,
                out[i][1],
                out[i][3],
                doppler,
                out[i][2][prn].code_phase_samples,
                ncoh_rounds,
                doppler_taps,
                1:size(ddm)[1],
                ddm
            )
            append!(ddms, [ddm_with_metadata])
        end
    end
    return ddms =#
    #test

    return result_all
end