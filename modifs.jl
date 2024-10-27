# Remove BIN1002 TH on 2024-10-17
m = s[row -> row.sigle == :BIN1002 && row.volet == :TH && any(["2024-10-17" == Dates.format(sp.s, "yyyy-mm-dd") for sp in row.span])]
filter!(sp -> "2024-10-17" ≠ Dates.format(sp.s, "yyyy-mm-dd"),s.df[m.m,:][1,:span])

# Removing BIN3005 in H, E
m = s[row -> row.sigle == :BIN3005 && String(row.semester)[1] ∈ ['H', 'E']]
deleteat!(s.df, m.m)
m = r[row -> row.id == :BIN3005]
m.t.df[m.m, [:winter, :summer]] .= false

# BCM2003 requires BIN1002
m = r[row -> row.id == :BCM2003]
m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  BCM2502 et BIN1002"

# Remove prerequisite on BCM1521 for BCM2002
m = r[row -> row.id == :BCM2002]
m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  BCM1503"

# Remove BCM2002 from bloc 01C
prog = p["Baccalauréat en bio-informatique (B. Sc.)"]
blocs = prog.segments[1].blocs
b = blocs[3]
blocs[3] = Bloc(b.name, b.max-3, b.min-3, b.id, [:BCM1501, :BCM1503, :BCM2004, :BCM2502])

# Add it to bloc 02D
blocs = prog.segments[2].blocs
b = blocs[4]
blocs[4] = Bloc(b.name, b.max+3, b.min+3, b.id, [b.courses; :BCM2002])

# add nb credits cst to bcm3515

# Remove HEC3015

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]
blocs = prog.segments[2].blocs
b = blocs[5]
blocs[5] = Bloc(b.name, b.max, b.min, b.id, filter(x -> x ≠ :HEC3015, b.courses))

# Add requirements to IFT3545

m = r[row -> row.id == :IFT3545]
m.t.df[m.m, :requirement_text] .= "prerequisite_courses :  IFT1065 et IFT2015"
