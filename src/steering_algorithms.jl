abstract type AbstractManualSteering end

struct DopplerRange <: AbstractManualSteering
    doppler_range::Float64
end


function find_specular_point_c(transmitter,receiver)
    result = Vector{Float64}(undef,3)
    n_iter = ccall((:calc_sx_ag, "/home/byakuya/workdir/libgnssr.so"),Int16, (Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}), transmitter,receiver,result)
    return result,n_iter
end

function setup_specular_problem!(model, low, high)
  set_silent(model)
  @variable(model, low[i] <= x_s[i = 1:3] <= high[i])
  xt = @NLparameter(model, x_t[1:3] == 0)
  xr = @NLparameter(model, x_r[1:3] == 0)
  @NLobjective(model,  Min, sqrt((x_s[1] - x_t[1])^2 + (x_s[2] - x_t[2])^2 + (x_s[3] - x_t[3])^2) + sqrt((x_r[1] - x_s[1])^2 + (x_r[2] - x_s[2])^2 + (x_r[3] - x_s[3])^2))
  @NLconstraint(model, x_s[1]^2 / wgs84_ellipsoid.a^2 + x_s[2]^2 / wgs84_ellipsoid.a^2 + x_s[3]^2 / wgs84_ellipsoid.b^2 == 1)
  return model
end

function find_specular_point!(problem_setup, transmitter,receiver)
  set_value.(problem_setup[:x_t],transmitter)
  set_value.(problem_setup[:x_r],receiver)
  optimize!(problem_setup)
  #return problem_setup
  return JuMP.value.(problem_setup[:x_s]), objective_value(problem_setup)
end

function passthrough(trk,pvt,prn,userdata)
    code_delay = 0.0
    doppler = ustrip(trk[1].carrier_doppler_hz)
    return (doppler,code_delay)
end

function specular_tracking_ipopt(trk,pvt,prn,userdata)

    problem_setup = userdata

    receiver1 = pvt[1].position
    receiver2 = pvt[2].position
    transmitter1 = pvt[1].sats[prn].position
    transmitter2 = pvt[2].sats[prn].position

    ipopt_1,pl1 = find_specular_point!(problem_setup, transmitter1,receiver1)
    ipopt_2,pl2 = find_specular_point!(problem_setup, transmitter2,receiver2)


    reflection_range_rate = (pl2-pl1)/(pvt[2].time- pvt[1].time).fraction
    println(reflection_range_rate)
    doppler = (-reflection_range_rate/299_792_458) * 1575.42e6 
    

    code_delay = 0.0
    return (doppler,code_delay, ipopt_2)
end