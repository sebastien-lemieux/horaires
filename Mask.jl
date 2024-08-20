abstract type AbstractPrograms end
abstract type AbstractRepertoire end
abstract type AbstractSchedules end

struct Mask{T <: Union{AbstractPrograms, AbstractRepertoire, AbstractSchedules}}
    m::BitVector
end

Base.:&(a::Mask{T}, b::Mask{T}) where T <: Union{AbstractPrograms, AbstractRepertoire, AbstractSchedules} = Mask{T}(a.m .& b.m)
Base.:|(a::Mask{T}, b::Mask{T}) where T <: Union{AbstractPrograms, AbstractRepertoire, AbstractSchedules} = Mask{T}(a.m .| b.m)
Base.:^(a::Mask{T}, b::Mask{T}) where T <: Union{AbstractPrograms, AbstractRepertoire, AbstractSchedules} = Mask{T}(a.m .^ b.m)
Base.:!(a::Mask{T}) where T <: Union{AbstractPrograms, AbstractRepertoire, AbstractSchedules} = Mask{T}(.!a.m)

# a = s[:semester, :A24]
# b = s[:sigle, :IFT1015]

# a | b