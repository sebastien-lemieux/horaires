
struct Section{T <: AbstractString}
    sigle::Symbol
    sec::Set{T}
    #spans::Vector{Span}
    credit::Int
end

function Section(s::Schedules, p::Program, sigle::Symbol, sec::Set{T}) where T <: AbstractString
    df = filter(row -> row.section ∈ sec, s[sigle])
    spans = reduce(vcat, df.spans)
    Section(sigle, sec, spans, p[sigle].credit)
end

Base.show(io::IO, sec::Section) = print(io, "$(replace(String(sec.sigle), '_' => ' ')) ($(join(sec.sec, '-')))")

function prepSections(s::Schedules, p::Program, sigle::Symbol)
    df = s[sigle]
    sections = unique(df.section)
    th = filter(x -> length(x) == 1, sections)
    tp = filter(x -> length(x) > 1, sections)
    res = isempty(tp) ? [Set([sth]) for sth in th] : [Set([sth, stp]) for sth in th, stp in tp if sth[1] == stp[1]]
    [Section(s, p, sigle, r) for r in res]
end

function checkConflict(schedules, p::Program, sigle_a, sigle_b)
    sections_a = prepSections(schedules, p, sigle_a)
    sections_b = prepSections(schedules, p, sigle_b)
    for a in sections_a, b in sections_b
        cf = conflict_dt(a.spans, b.spans)
        if isempty(cf)
            println("Compatible sections: $a and $b")
        else
            println("Incompatible sections: $a and $b, $(length(cf)) conflict(s) => $cf")
        end
    end
end
