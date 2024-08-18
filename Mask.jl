struct Mask{T <: Union{Programs, Repertoire, Schedules}}
    m::BitVector
end

Base.:&(a::Mask{T}, b::Mask{T}) where T <: Union{Programs, Repertoire, Schedules} = Mask{T}(a.m .& b.m)
Base.:|(a::Mask{T}, b::Mask{T}) where T <: Union{Programs, Repertoire, Schedules} = Mask{T}(a.m .| b.m)
Base.:^(a::Mask{T}, b::Mask{T}) where T <: Union{Programs, Repertoire, Schedules} = Mask{T}(a.m .^ b.m)
Base.:!(a::Mask{T}) where T <: Union{Programs, Repertoire, Schedules} = Mask{T}(.!a.m)

# a = s[:semester, :A24]
# b = s[:sigle, :IFT1015]

# a | b