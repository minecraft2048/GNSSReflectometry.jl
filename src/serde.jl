struct ReportIOContext
    fd::IOStream
end

ReportIOContext(filename::String) = ReportIOContext(open(filename,"w"))

function write_json(dat::Vector{Acquisition.AcquisitionResults{T,T2}}, io) where {T,T2}
    out = Dict{Int, 
                   Dict{
                        String,
                        Float64
                        }}()
    
    for res in dat
        out[res.prn] = Dict("CN0" => res.CN0, 
                            "carrier_doppler" => ustrip(res.carrier_doppler), 
                            "code_phase" => res.code_phase)

    end

    JSON.print(io, out)
end

JSON.lower(p::GPSL1{T}) where T = "GPSL1"