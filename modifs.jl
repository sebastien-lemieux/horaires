

function modif!(d::Data)
    # # Remove BIN1002 TH on 2024-10-17
    # m = d.s[row -> row.sigle == :BIN1002 && row.volet == :TH && any(["2024-10-17" == Dated.s.format(sp.s, "yyyy-mm-dd") for sp in row.span])]
    # filter!(sp -> "2024-10-17" ≠ Dated.s.format(sp.s, "yyyy-mm-dd"),d.s.df[m.m,:][1,:span])

    # Removing BIN3005 in H, E
    m = d.s[row -> row.sigle == :BIN3005 && String(row.semester)[1] ∈ ['H', 'E']]
    deleteat!(d.s.df, m.m)
    m = d.r[row -> row.id == :BIN3005]
    m.t.df[m.m, [:winter, :summer]] .= false

    # BCM2003 requires BIN1002
    m = d.r[row -> row.id == :BCM2003]
    m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  BCM2502 et BIN1002"

    # Remove prerequisite on BCM1521 for BCM2002
    m = d.r[row -> row.id == :BCM2002]
    m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  BCM1503"

    # Remove BCM2002 from bloc 01C
    prog = d.p["Baccalauréat en bio-informatique (B. Sc.)"]
    blocs = prog.segments[1].blocs
    b = blocs[3]
    blocs[3] = Programs.Bloc(b.name, b.max-3, b.min-3, b.id, [:BCM1501, :BCM1503, :BCM2004, :BCM2502])

    # Add it to bloc 02D
    blocs = prog.segments[2].blocs
    b = blocs[4]
    blocs[4] = Programs.Bloc(b.name, b.max+3, b.min+3, b.id, [b.courses; :BCM2002])

    # add nb credits cst to bcm3515
    m = d.r[row -> row.id == :BCM3515]
    m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  BCM2003 et BCM2502"

    # Remove HEC3015

    prog = d.p["Baccalauréat en bio-informatique (B. Sc.)"]
    blocs = prog.segments[2].blocs
    b = blocs[5]
    blocs[5] = Programs.Bloc(b.name, b.max, b.min, b.id, filter(x -> x ≠ :HEC3015, b.courses))

    function changeprereq(sigle::Symbol, req::String)
        m = d.r[row -> row.id == sigle]
        m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  $req"    
    end

    changeprereq(:IFT3545, "IFT1065 et IFT2015")
    changeprereq(:CHM3450, "CHM2103")
    changeprereq(:STT2000, "STT1700")
    changeprereq(:BIO2306, "BIO1534")
    changeprereq(:BIO2043, "BCM1503")
    changeprereq(:IFT2125, "IFT1025")
    changeprereq(:PBC3060, "BIO1153 et BCM2502")
end






