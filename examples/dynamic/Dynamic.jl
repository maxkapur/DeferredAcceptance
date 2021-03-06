#=  In real life, after students are assigned a school by the DA mechanism, they may receive an admission
    offer from a private school or choose to move out of district, both of which are equivalent to the
    student assigning increased preference to the "outside option" of not attending any of the schools in
    the primary market. This frees up seats, and running a second lottery allows us to offer better
    schools to some of the students while guaranteeing them their first round assignment. An important
    design consideration is which tiebreaking mechanism to use in each round. Feigenbaum et al. (2020)
    recommend using STB in the both rounds but reversing the STB lottery numbers in the second round,
    which minimizes reassignment. (Note that this is not the same as running the DA algorithm in reverse;
    we still use student-proposing DA). An arbitrary permutation of the first-round lottery numbers can
    instead be used in the second round to allow the market designed to optimize for distributional goals.
    The code below offers a sketch of a two-round reassignment mechanism with a reverse lottery.       =#

using DeferredAcceptance, Random

function argsort(vec::AbstractArray{<:Real, 1})::AbstractArray{<:Real, 1}
    return invperm(sortperm(vec))
end

n = 100         # Number of students
m = 70          # Number of schools with unit capacities
γ = m / 10      # Average number of ranks by which outside options improve between rounds.

#=  School m + 1 is the outside option and has unlimited capacity. Note that DA() implements its own
    "reject bin" automatically, so specifying a new outside option is redundant if the students
    uniformly prefer schools in the market to nonassignment. The dynamic-matching case relaxes this
    assumption, allowing that some students actually prefer nonassignment to a subset of the schools;
    we need to encode that preference explicitly.                       =#

students = hcat((randperm(m + 1) for i in 1:n)...)
schools = ones(Int64, n, m + 1)
capacities = [ones(Int64, m)..., n]

# Break ties using STB (which is equiv. to HTB with blend 0) and store the lottery numbers
schools_r1, lottery_r1 = hybridtiebreaking(schools, 0., return_add=true)  

assn_r1 = deferredacceptance(students, schools_r1, capacities; verbose=true)   # Compute first-round assignments


# Reveal outside options and update student preference lists.
students_float = convert(Array{Float16}, students)              # Rank of student's outside options
students_float[m + 1, :] -= γ * randexp(Float16, n)             # improves by an exponential random var,
students_r2 = mapslices(argsort, students_float, dims=1)        # whose mean is γ.

schools_r2 = copy(schools)                          # Compute second-round school preferences:
lowest_school_rank = minimum(schools)                     # For robustness; in my data this will always be 1
for (s, c) in enumerate(assn_r1[1])                       # Guarantee r1 assignments
    schools_r2[s, c] = lowest_school_rank - 1
end
schools_r2 += (1. .- lottery_r1)                          # Then break ties using reverse lottery numbers
schools_r2 = mapslices(argsort, schools_r2, dims=1)

assn_r2 = deferredacceptance(students_r2, schools_r2, capacities; verbose=true)  # Compute r2 assignments

for i in zip(assn_r1[2], assn_r2[2])        # Compare the assignments. r1 should dominate rankwise.
    println("$(i[1]) ≥ $(i[2])")
end
