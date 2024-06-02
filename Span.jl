using Dates

struct Span
    s::DateTime
    e::DateTime
end

Span(time_s::Time, time_e::Time, date_s::Date, date_e::Date) = Span(DateTime(date_s, time_s), DateTime(date_e, time_e))

expand(time_s, time_e, date_s, date_e) = [Span(time_s, time_e, d, d) for d in date_s:Week(1):date_e]
conflict(span_a::Span, span_b::Span) = (span_a.s <= span_b.e) && (span_a.e >= span_b.s)
conflict_dt(span_a::Span, span_b::Span) = (span_a.s ≤ span_b.e && span_a.e ≥ span_b.e) ? Span(span_a.s, span_b.e) : Span(span_b.s, span_a.e)
conflict(a::Vector{Span}, b::Vector{Span}) = any([conflict(sa, sb) for sa in a, sb in b])
conflict_dt(a::Vector{Span}, b::Vector{Span}) = [conflict_dt(sa, sb) for sa in a, sb in b if conflict(sa, sb)]

function Base.show(io::IO, span::Span)
    d = Dates.format(span.s, "yyyy-mm-dd")
    s = Dates.format(span.s, "HH:MM")
    e = Dates.format(span.e, "HH:MM")
    print(io, "$d [$s-$e]")
end

function Base.show(io::IO, v::Vector{Span})
    print(io, "(")
    for span in v
        show(io, MIME"text/plain"(), span)
        !(span === last(v)) && print(io, ", ")
    end
    print(io, ")")
end

