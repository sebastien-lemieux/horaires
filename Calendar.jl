using Cairo, Graphics, Dates

# Define your Span struct
include("Span.jl")

# French day names
jours = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]

# Time slots: every 30 minutes from 8:00 to 20:00
times = collect(DateTime(2025,9,8,8,0):Minute(30):DateTime(2025,9,8,20,0))

# Layout Parameters
cell_width = 100
cell_height = 30
header_height = 40
left_margin = 80
top_margin = 60

# Canvas size
width = left_margin + 7 * cell_width + 20
height = top_margin + length(times) * cell_height + 40

# Create Cairo Surface
surface = CairoSVGSurface("data/weekly_schedule.svg", width, height)
context = CairoContext(surface)

# Background
set_source_rgb(context, 1, 1, 1) # White
paint(context)

# Draw Day Headers
set_source_rgb(context, 0.2, 0.2, 0.4) # Dark blue
select_font_face(context, "Arial", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_BOLD)
set_font_size(context, 12)

for (i, jour) in enumerate(jours)
    x = left_margin + (i - 1) * cell_width + cell_width / 2
    y = top_margin - 20
    move_to(context, x - 30, y)
    show_text(context, jour)
end

# Draw Time Rows
set_source_rgb(context, 0.5, 0.5, 0.5) # Gray lines
set_line_width(context, 0.5)

for (i, time) in enumerate(times)
    y = top_margin + (i - 1) * cell_height
    move_to(context, left_margin, y)
    line_to(context, width - 20, y)
    stroke(context)
    
    # Time Labels
    set_source_rgb(context, 0, 0, 0)
    set_font_size(context, 10)
    move_to(context, 15, y + cell_height / 2 + 4)
    show_text(context, Dates.format(time, "HH:MM"))
end

# Draw Vertical Day Lines
set_source_rgb(context, 0.5, 0.5, 0.5) # Gray lines
for i in 0:7
    x = left_margin + i * cell_width
    move_to(context, x, top_margin)
    line_to(context, x, height - 40)
    stroke(context)
end

# Example Spans
spans = [
    Span(101, DateTime(2025, 2, 16, 9, 0),  DateTime(2025, 2, 16, 10, 30)),  # Dimanche
    Span(102, DateTime(2025, 2, 17, 11, 0), DateTime(2025, 2, 17, 12, 0)),  # Lundi
    Span(103, DateTime(2025, 2, 18, 14, 0), DateTime(2025, 2, 18, 15, 30)),  # Mardi
    Span(104, DateTime(2025, 2, 19, 10, 0), DateTime(2025, 2, 19, 11, 30)),  # Mercredi
    Span(105, DateTime(2025, 2, 20, 13, 0), DateTime(2025, 2, 20, 14, 0))   # Jeudi
]

# Utility to find row for a given time
function find_time_index(dt::DateTime)
    for (i, time) in enumerate(times)
        if dt <= time
            return i
        end
    end
    return length(times)
end

# Function to get column from date
function day_column(dt::DateTime)
    return dayofweek(dt) # 1 = Monday ... 7 = Sunday
end

# Plot Spans
for span in spans
    col = day_column(span.s) % 7 + 1  # Adjust for Dimanche starting
    start_row = find_time_index(span.s)
    end_row = find_time_index(span.e)
    
    x = left_margin + (col - 1) * cell_width
    y = top_margin + (start_row - 1) * cell_height
    w = cell_width - 4
    h = (end_row - start_row + 1) * cell_height - 4
    
    # Draw Rectangle for Span
    set_source_rgba(context, 0.3, 0.6, 0.8, 0.5) # Light blue
    rectangle(context, x, y, w, h)
    fill(context)
    
    # Span ID Label
    set_source_rgb(context, 0, 0, 0)
    set_font_size(context, 10)
    move_to(context, x + w/2 - 10, y + h/2 + 4)
    show_text(context, string(span.s_id))
end

# Finish and Save
finish(surface)
println("Schedule saved to weekly_schedule.svg")

TypstString(1 // 2; block = true)
