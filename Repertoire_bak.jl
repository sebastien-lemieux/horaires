using PDFIO

function parseRepertoire(str)
    rep = pdDocOpen(str)
    info = pdDocGetInfo(rep)

    npage::Int = pdDocGetPageCount(rep)
    sigle_v = Symbol[]
    credit_v = Int[]
    titre_v = String[]
    desc_v = String[]
    a_v = Bool[]
    e_v = Bool[]
    h_v = Bool[]
    reqstr_v = String[]

    for i = 2:npage
        println("page: $i")
        page = pdDocGetPage(rep, i)
        io = IOBuffer()
        pdPageExtractText(io, page)

        p = split(String(take!(io)), '\n')
        sigle = :dummy; credit = 0; titre = ""; desc = String[]; a = false; e = false; h = false; reqstr = "";
            
        last_attr = ""
        for l in p
            # println("[$l]")
            length(l) == 0 && continue
            if match(r"^      \S", l) ≠ nothing
                l = strip(l)
                # println("to parse 6")
                # m = filter(s -> length(s) > 0, strip.(split(l, ":")))
                m = strip.(split(l, ":"))
                # pr
                last_attr = m[1]
                if m[1] == "Habituellement offert"
                    s = split(m[2], ", ")
                    a = ("AUTOMNE" ∈ s)
                    h = ("HIVER" ∈ s)
                    e = ("ÉTÉ" ∈ s)
                elseif m[1] == "Groupe exigences"
                    reqstr = join(m[2:end], ':')
                    # println("[$reqstr]")
                end
            elseif match(r"^    \S", l) ≠ nothing # 4 spaces
                l = strip(l)
                # println("to parse 4")
                if (m = match(r"^([A-Z0-9]+)\((\d+)\)", l)) ≠ nothing
                    sigle = Symbol(m[1][1:3] * "_" * m[1][4:end])
                    credit = parse(Int, m[2])
                elseif titre == ""
                    titre = l
                elseif l[1] == '_' ## complete
                    push!(sigle_v, sigle)
                    push!(credit_v, credit)
                    push!(titre_v, titre)
                    # println("desc: $desc")
                    push!(desc_v, join(desc, ' '))
                    push!(a_v, a)
                    push!(e_v, e)
                    push!(h_v, h)
                    push!(reqstr_v, reqstr)
                    # println("$sigle $titre $credit $(length(desc)) $a $e $h $reqstr")
                    sigle = :dummy; credit = 0; titre = ""; desc = String[]; a = false; e = false; h = false; reqstr = "";
                else
                    push!(desc, l) ## Description
                end
            elseif match(r"^                            \S", l) ≠ nothing
                # println("bing [$last_attr]")
                if last_attr == "Groupe exigences"
                    # println("bang")
                    reqstr = "$reqstr; $(strip(l))"
                end
            end
        end
    end

    return DataFrame(
        sigle = sigle_v,
        credit = credit_v,
        titre = titre_v,
        desc = desc_v,
        a = a_v,
        e = e_v,
        h = h_v,
        reqstr = reqstr_v
    )
end
