using Dates

const idtoday = ["Lu", "Ma", "Me", "Je", "Ve", "Sa", "De"]
const daytoid = Dict(idtoday .=> 1:length(idtoday))

struct Span
    s::DateTime
    e::DateTime
end

Span(time_s::Time, time_e::Time, date_s::Date, date_e::Date) = Span(DateTime(date_s, time_s), DateTime(date_e, time_e))

function expand(time_s, time_e, date_s, date_e, dow)
    res = Span[]
    (ismissing(time_s) || ismissing(time_e) || ismissing(dow) || ismissing(date_s) || ismissing(date_e)) && return res
    for day in split(dow)
        dow_id = daytoid[day]
        date_s = tonext(date_s, dow_id, same=true)
        date_e = toprev(date_e, dow_id, same=true)
        res = vcat(res, [Span(time_s, time_e, d, d) for d in date_s:Week(1):date_e])
    end
    res
end

conflict(span_a::Span, span_b::Span) = (span_a.s <= span_b.e) && (span_a.e >= span_b.s)
conflict_dt(span_a::Span, span_b::Span) = (span_a.s ≤ span_b.e && span_a.e ≥ span_b.e) ? Span(span_a.s, span_b.e) : Span(span_b.s, span_a.e)
conflict(a::Vector{Span}, b::Vector{Span}) = any([conflict(sa, sb) for sa in a, sb in b])
conflict_dt(a::Vector{Span}, b::Vector{Span})::Vector{Span} = unique([conflict_dt(sa, sb) for sa in a, sb in b if conflict(sa, sb)])

extract(span::Span) = Dates.format(span.s, "yyyy-mm-dd"), Dates.format(span.s, "HH:MM"), Dates.format(span.e, "HH:MM"), Dates.dayofweek(span.s)

function Base.show(io::IO, span::Span)
    d, s, e, dw = extract(span)
    print(io, "$d [$(idtoday[dw]) $s-$e]")
end

function inWeek(span::Span)
    d, s, e, dw = extract(span)
    return "$(idtoday[dw]) $s-$e"
end

function Base.show(io::IO, v::Vector{Span})
    print(io, "(")
    for span in v
        show(io, MIME"text/plain"(), span)
        !(span === last(v)) && print(io, ", ")
    end
    print(io, ")")
end

