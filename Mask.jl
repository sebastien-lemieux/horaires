using DataFrames

abstract type AbstractMaskable end

struct Mask{M <: AbstractMaskable}
    t::M
    m::BitVector
end

Base.:&(a::Mask{T}, b::Mask{T}) where T <: AbstractMaskable = Mask{T}(a.t, a.m .& b.m)
Base.:|(a::Mask{T}, b::Mask{T}) where T <: AbstractMaskable = Mask{T}(a.t, a.m .| b.m)
Base.:^(a::Mask{T}, b::Mask{T}) where T <: AbstractMaskable = Mask{T}(a.t, a.m .^ b.m)
Base.:!(a::Mask{T}) where T <: AbstractMaskable = Mask{T}(a.t, .!a.m)

Base.getindex(s::M, col::Symbol, val::T) where {T <: Union{String, Symbol}, M <: AbstractMaskable} =
    Mask{M}(s, s.df[!, col] .== val)

# Base.getindex(s::M, col::Symbol, vec::Vector{T}) where {T <: Union{String, Symbol}, M <: AbstractMaskable} =
#     Mask{M}(s, s.df[!, col] .∈ vec)

Base.getindex(s::M, f::Function) where {M <: AbstractMaskable} =
    Mask{M}(s, f.(eachrow(s.df)))

Base.getindex(m::Mask{T}, col::Symbol) where T <: AbstractMaskable = m.t.df[m.m, col]

DataFrames.DataFrame(mask::Mask{T}) where T <: AbstractMaskable = mask.t.df[mask.m,:]

macro maskable(expr)
    # This macro will make the struct type's a subtype of AbstractMaskable

    if expr.head == :struct

        mutable_flag = expr.args[1]
        struct_name = expr.args[2]
        struct_body = expr.args[3]

        modified_struct = Expr(:struct, mutable_flag, Expr(:(<:), struct_name, :AbstractMaskable), Expr(:block, struct_body.args[2:end]...))
        eval(modified_struct)

        constructor_def = Expr(:function, 
            Expr(:call, struct_name, Expr(:(::), :m, Expr(:curly, :Mask, struct_name))),
            Expr(:block, Expr(:call, struct_name, Expr(:call, :DataFrame, :m)))
        )
        eval(constructor_def)

    else
        error("@maskable must be used with a struct definition")
    end
end

## Old version, rebuild constructor... why?
# macro maskable(expr)
#     # Check if the expression is a struct definition
#     if expr.head == :struct
#         # Extract the struct name
#         struct_name = expr.args[2]
        
#         # Handle the struct body, which might be wrapped in a `begin` block
#         struct_body = expr.args[3]
        
#         # If the body is wrapped in a `begin` block, extract the fields
#         if struct_body.head == :block
#             struct_fields = struct_body.args[2:end]  # Ignore the first element (line number metadata)
#         else
#             struct_fields = [struct_body]
#         end
        
#         # Modify struct to inherit from AbstractMaskable
#         modified_struct = Expr(:struct, struct_name, Expr(:(<:), :AbstractMaskable), struct_fields...)

#         # Define the constructor that accepts Mask{T}
#         constructor_def = :( $struct_name(m::Mask{$struct_name}) = $struct_name(DataFrame(m)) )

#         # Return both the struct definition and the constructor
#         return quote
#             $modified_struct
#             $constructor_def
#         end
#     else
#         error("@maskable must be used with a struct definition")
#     end
# end

