using JuMP, Gurobi

function prepare_sections(p, r, s, prog, semester, done)

    ## Prepare list of available sections
    id = r[prog].id 

    function _can(row)
        row.sigle ∈ id || return false
        row.sigle ∉ done || return false
        row.semester == semester || return false
        length(row.span) ≥ 1 || return false
        return true
    end

    avail = DataFrame(s[_can])
    avail_sections = combine(groupby(avail, [:sigle, :msection])) do df
        (; span = [reduce(vcat, df.span)])
    end

    avail_sections.credits = r[avail_sections.sigle].credits
    avail_sections.req = r[avail_sections.sigle].requirement_text
    avail_sections[!,:pref] .= 1.0
    avail_sections = avail_sections[check_req.(avail_sections.req, Ref(done)),:]

    ## prefs (should come from file)
    obl = vcat([b.courses for b in prog.segments[1].blocs]...)
    transform!(avail_sections, [:sigle, :pref] => ByRow((s,p) -> (s ∈ obl) ? 5.0 : p) => :pref)
    opt = vcat([b.courses for b in prog.segments[2].blocs]...)
    transform!(avail_sections, [:sigle, :pref] => ByRow((s,p) -> (s ∈ opt) ? 3.0 : p) => :pref)
    b02Y = vcat([bloc.courses for bloc in filter(x -> x.id == Symbol("Bloc 02Y"), prog.segments[2].blocs)]...)
    transform!(avail_sections, [:sigle, :pref] => ByRow((s,p) -> (s ∈ b02Y) ? 1.0 : p) => :pref)

    return avail_sections
end

function build_model(avail_sections, done)
    ## build model
    model = Model(Gurobi.Optimizer)
    avail_sections.var = @variable(model, sec_var[i=1:nrow(avail_sections)] ≥ 0, Bin)

    # unique section per course
    gdf = groupby(avail_sections, :sigle)
    for k in keys(gdf)
        sdf = gdf[k]
        the_max = (k.sigle ∈ done) ? 0 : 1
        nrow(sdf) < 2 && continue
        @constraint(model, sum(sdf.var) ≤ the_max)
    end

    # schedule conflicts
    for i in 1:nrow(avail_sections)
        for j in (i+1):nrow(avail_sections)
            if _conflict(avail_sections[i, :span], avail_sections[j, :span])
                @constraint(model, avail_sections[i, :var] + avail_sections[j, :var] ≤ 1)
            end
        end
    end

    # max credits
    @constraint(model, sum(avail_sections[:,:var] .* avail_sections[:,:credits]) ≤ 16)

    @objective(model, Max, sum(sec_var .* avail_sections[:,:pref] .* avail_sections[:,:credits]))

    set_optimizer_attribute(model, "PoolSearchMode", 2)  # Search for multiple solutions
    set_optimizer_attribute(model, "PoolSolutions", 10)  # Limit to 10 solutions
    optimize!(model)
    # courses(model, prog)
    return model, sec_var
end

