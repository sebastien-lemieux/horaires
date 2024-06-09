using JuMP
using GLPK

model = Model(GLPK.Optimizer)

num_courses = 100
num_semesters = 3
credits = rand(2:4, num_courses)  # Randomly assign credits between 1 and 5
prefs = rand(1:10, num_courses)  # Randomly assign preferences between 1 and 10
max_credits = 15

# Define conflicts as pairs of courses that conflict within a semester
# Example: conflicts = [(1, 2), (3, 4), ...] (add actual conflict pairs as needed)
conflicts = [(i, j) for i in 1:num_courses for j in i+1:num_courses if rand() < 0.2] # Randomly generate some conflicts

# Define binary variables for course selection in each semester
@variable(model, x[1:num_courses, 1:num_semesters], Bin)

# Constraint: Total credits in each semester should not exceed max_credits
for s in 1:num_semesters
    @constraint(model, sum(x[i, s] * credits[i] for i in 1:num_courses) <= max_credits)
end

# Add conflict constraints within each semester
for (i, j) in conflicts
    for s in 1:num_semesters
        @constraint(model, x[i, s] + x[j, s] ≤ 1)
    end
end

for i in 1:num_courses
    @constraint(model, sum(x[i,:]) ≤ 1)
end

# Objective: Maximize the sum of preferences across all semesters
@objective(model, Max, sum(x[i, s] * prefs[i] for i in 1:num_courses, s in 1:num_semesters))

# Solve the model
optimize!(model)

# Output the results
println("Selected courses for each semester:")
for s in 1:num_semesters
    println("Semester $s:")
    for i in 1:num_courses
        if value(x[i, s]) > 0.5
            println("  Course $i: Credits = $(credits[i]), Preference = $(prefs[i])")
        end
    end
end

# Calculate total credits and preferences
total_credits = [sum(value(x[i, s]) * credits[i] for i in 1:num_courses) for s in 1:num_semesters]
total_prefs = [sum(value(x[i, s]) * prefs[i] for i in 1:num_courses) for s in 1:num_semesters]

println("Total Credits per Semester: ", total_credits)
println("Total Preferences per Semester: ", total_prefs)
println("Overall Total Preferences: ", sum(total_prefs))
