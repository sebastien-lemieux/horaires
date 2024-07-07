
struct Section
    sigle::Symbol
    sec::Set{Symbol}
    session::Symbol
    year::Int
    span_d::Dict{Symbol, Vector{Span}}
end

function Base.show(io::IO, sec::Section)
    sigle = replace(String(sec.sigle), '_' => ' ')
    sections_str = join(sort(collect(sec.sec)), '-')
    print(io, "$sigle ($(sec.session)$(sec.year): $sections_str)")
end

function sections(s::Schedules, sigle::Symbol, session::Symbol, year::Int)
    df = s[sigle, session, year]
    sections = String.(unique(df.section))
    th = filter(x -> length(x) == 1, sections)
    tp = filter(x -> length(x) > 1, sections)
    res = isempty(tp) ? [Set([Symbol(sth)]) for sth in th] : [Set([Symbol(sth), Symbol(stp)]) for sth in th, stp in tp if sth[1] == stp[1]]

    final = Section[]
    for r in res
        @show r
        df = subset(s[sigle, session, year], :section => ByRow(x -> x ∈ r))
        println(df)
        volet_v = unique(df.volet)
        span_d = Dict{Symbol, Vector{Span}}()
        println(volet_v)
        for volet in volet_v
            span_d[volet] = vcat(df[df.volet .== volet,:spans]...)
            println(volet)
        end
        sec = Set(Symbol.(r))
        push!(final, Section(sigle, sec, session, year, span_d))
    end

    return final
end
# z =sections(schedules, :IFT_1015, :A, 2024)

function Base.getindex(s::Schedules, sec::Section)
    df = s[sec.sigle]
    filter(row -> row.section ∈ sec.sec, df)
end

function spanPerVolet(s::Schedules, sec::Section)
    df = s[sec]
    volet_v = unique(df.volet)
    span_d = Dict{Symbol, Vector{Span}}()
    for volet in volet_v
        span_d[volet] = vcat(df[df.volet .== volet,:spans]...)
    end
    return span_d
end

function checkConflict(s::Schedules, a::Section, b::Section)
    da = spanPerVolet(s, a)
    db = spanPerVolet(s, b)
    final = String[]
    for (ka, va) in da, (kb, vb) in db
        overlap = conflict_dt(va, vb)
        isempty(overlap) && continue
        # println("Conflict between $a-$ka and $b-$kb at: $(first(overlap))")
        push!(final, "Conflict between $a-$ka and $b-$kb at: $(first(overlap))")
        # println(df)
    end
    return final
end

# checkConflict(schedules, a, b)

