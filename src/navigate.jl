function navigate(fup, n, acq_results; intermediate_freq=0, dsp_callback=nothing, userdata=nothing)
    #resampler_ctx_ch0 = FIRFilter(7//4)
    fp = read(fup, 10u"ms")
    #fp = Kea.resample(fp[:,1], resampler_ctx_ch0)
    trk_results = similar(acq_results, Tracking.TrackingResults)
    trk_states = similar(acq_results, Tracking.TrackingState)
    decoder_states = similar(acq_results, typeof(GPSL1DecoderState(1)))
    subctr = 0
    subctr1 = 0 
    Hz = u"Hz"
    for i in eachindex(acq_results)
      prn = acq_results[i].prn
      decoder_states[i] = GPSL1DecoderState(prn)
      trk_states[i] = TrackingState(prn, GPSL1(), acq_results[i].carrier_doppler, acq_results[i].code_phase)
    end
    #init states
    Threads.@threads for i in eachindex(trk_results)
      trk_results[i] = track(ComplexF64.(collect(fp[:,1])), trk_states[i], fp.samplerate*Hz;intermediate_frequency=intermediate_freq*Hz)
    end
    filtered_prompt = Vector{ComplexF64}()
    clock_drifts = Vector{Float64}()
    trk_result_out = Vector{Vector{Tracking.TrackingResults}}()
    pvt_sol = Vector{PVTSolution}()
    file_idx = Vector{Int}()
    ret = Vector{Any}()

    @progress for kk in 1:n
      fp = read(fup, 10u"ms")
      #fp = Kea.resample(fp[:,1], resampler_ctx_ch0)
      #println("Iteration $kk")
      samples = ComplexF64.(collect(fp[:,1]));
      rate = fp.samplerate*Hz;
      @floop for i in eachindex(trk_results)
        trk_results[i] = track(samples, get_state(trk_results[i]), rate;intermediate_frequency=intermediate_freq*Hz);
        #append!(filtered_prompt,trk_res.filtered_prompt)
        #println(trk_results[i].cn0)
        decoder_states[i] = decode(decoder_states[i], get_bits(trk_results[i]), get_num_bits(trk_results[i]))
      end

      if subctr1 % 50 == 0
          for i in 1:6
            @info "PRN $(trk_results[i].state.prn) $(trk_results[i].cn0)"
          end
      end
      subctr1 = subctr1 + 1

      qq = SatelliteState.(decoder_states, trk_results);
      #println(qq)
      nav = calc_pvt(qq);
      if !(isnothing(nav.time))
        lla = get_LLA(nav)
        if subctr == 0
          @info "First nav soln at $(nav.time) is lat: $(lla.lat) lon: $(lla.lon) alt: $(lla.alt) clk drift: $(nav.relative_clock_drift)"
        else
          if subctr % 50 == 0
            @info "Position at time $(nav.time) is lat: $(lla.lat) lon: $(lla.lon) alt: $(lla.alt) clk drift: $(nav.relative_clock_drift)"
          end
        end
       # append!(trk_result_out, [trk_results])
        #append!(pvt_sol, [nav])
        #append!(file_idx,[kk])
        #append!(clock_drifts,nav.relative_clock_drift)

        a = []
        for i in 1:length(trk_results)
            append!(a,[TrackingSummary(trk_results[i],i,fp.samplerate)])
        end

        append!(ret, ((kk, a, nav),))
        subctr = subctr +1
      end
    end
  #return pvt_sol,trk_result_out, file_idx
  return ret
end