abstract type AbstractManualSteering end

struct DopplerRange <: AbstractManualSteering
    doppler_range::Float64
end


function find_specular_point_c(transmitter,receiver)
    #sometimes the C library fails to converge
    result = Vector{Float64}(undef,3)
    if Sys.ARCH == :x86_64
      n_iter = ccall((:calc_sx_ag, "/home/byakuya/workdir/libgnssr.so"),Int16, (Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}), transmitter,receiver,result)
    else
      n_iter = ccall((:calc_sx_ag, :libgnssr),Int16, (Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}), transmitter,receiver,result)
    end
      return result,n_iter
end


#ported helper functions from ben's libgnssr

function earth_radius_fromlat(lat)
  a = 6378137
  f = 298.257223563
  b = a*(1-1/f); 

  return a*b ./ (a*a.*sin(lat).^2 + b*b.*cos(lat).^2).^0.5;

end

function earth_radius(ECEF_pos)
  
end


function find_specular_point_matlab_ben(transmitter, receiver; update_type="normal", intialision_type ="normal")
  #=
  calc_Secef calculats the specular point based on minimising the error
   between the surface normal and the scattering vector
  
   Usage  : [S_ecef, new_iterations, correction, Stemps] = calc_S_ecef(...
                                     R_ecef, T_ecef, varargin)
  
   Input: 
  	R_ecef = Receiver Position	in ECEF
  	T_ecef = GPS Satellite Position in ECEF
   Output:
  	S_ecef = specular point position in ECEF
  
  
     Author : Ben Southwell (adapted from Scott Gleason's code that accompanies 
  			GNSS Applications and methods textbook)
     Date : 14 Jan 2017

     Ported to julia by aldi, typos preserved 
  ==========================================================================#
  
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

function passthrough(trk,pvts,prn,userdata)
    code_delay = 0.0
    doppler = ustrip(pvts[1][2][prn].carrier_doppler_hz)
    return (doppler,code_delay,(0.0,0.0,0.0))
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
    #println(reflection_range_rate)
    doppler = (-reflection_range_rate/299_792_458) * 1575.42e6 
    

    code_delay = 0.0
    return (doppler,code_delay, ipopt_2)
end


function specular_tracking_loop(pvts,prn,specular_function,userdata)

    path_lengths = Vector{Float64}(undef,length(pvts))


    specular_position,_ = specular_function(userdata, pvts[1][3].sats[prn].position, pvts[1][3].position)

    for (idx,pvt) in enumerate(pvts)
      _,path_lengths[idx] = specular_function(userdata, pvt[3].sats[prn].position, pvt[3].position)
    end


    #do linear least square fit on path length
    A = [0:length(path_lengths)-1 ones(length(path_lengths))]
    res = A \ path_lengths

    reflection_range_rate = res[1] / ((pvts[2][3].time - pvts[1][3].time).fraction)
    reflection_range_start = res[2]

    doppler = (-reflection_range_rate/299_792_458) * 1575.42e6 
    code_delay = 0.0 #TODO

    return (doppler,code_delay,specular_position)

end