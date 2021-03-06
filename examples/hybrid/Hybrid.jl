#=  Here I compare a wide variety of tiebreaking rules, some of which (STB, MTB, and
    HTB) are described by Ashlagi and Nikzad (2020), and others (XTB, WTB) of my own
    creation. Testing the tiebreaking rules over a hybrid market in which the students
    uniformly prefer a subset of the schools allows us to examine the properties of
    these mechanisms in over- and underdemanded markets at a glance. See the readme
    for further discussion.                     =#

using Permutations
using Plots
using DeferredAcceptance


"""
Plots outcomes for various tiebreaking rules for a market with
the given characteristics.
"""
function plotter_more(n, m_pop, m_unp, samp)

    m = m_pop + m_unp

    descr = "$n students, $m schools ($m_pop popular, $m_unp unpopular), $samp samples"
    println(descr)

    # All schools have unit capacities
    capacities = ones(Int64, m)

    # Blank rank dists
    cdf_STB = zeros(Float64, m)
    cdf_MTB = zeros(Float64, m)
    cdf_HTB = zeros(Float64, m)
    cdf_XTB = zeros(Float64, m)
    cdf_WHTB = zeros(Float64, m)
    cdf_WXTB = zeros(Float64, m)

    # For HTB and WTB
    blend = ones(Float64, 1, m) # Use MTB in all schools except
    blend[1:m_pop] .= 0            # the popular schools, which use STB

    for i in 1:samp
        # Students unilaterally prefer popular schools to unpopular ones
        # Random ranking otherwise
        students = vcat(hcat((randperm(m_pop) for i in 1:n)...),
                   m_pop .+ hcat((randperm(m_unp) for i in 1:n)...))

        # Schools place all students in single priority category
        schools = ones(Int64, n, m)

        # Break ties
        schools_STB = singletiebreaking(schools)
        schools_MTB = multipletiebreaking(schools)
        schools_HTB = hybridtiebreaking(schools, blend)
        schools_XTB = hybridtiebreaking(schools, 0.5)
        schools_WHTB = welfaretiebreaking(students, schools, blend)
        schools_WXTB = welfaretiebreaking(students, schools, 0.5)

        # Update rank risks
        # println("Starting STB $i")
        cdf_STB += DA_rank_dist(students, schools_STB, capacities)
        # println("Starting MTB $i")
        cdf_MTB += DA_rank_dist(students, schools_MTB, capacities)
        # println("Starting HTB $i")
        cdf_HTB += DA_rank_dist(students, schools_HTB, capacities)
        # println("Starting XTB $i")
        cdf_XTB += DA_rank_dist(students, schools_XTB, capacities)
        # println("Starting WHTB $i")
        cdf_WHTB += DA_rank_dist(students, schools_WHTB, capacities)
        # println("Starting WXTB $i")
        cdf_WXTB += DA_rank_dist(students, schools_WXTB, capacities)

        # To display plot as it updates
        # display(plot([cdf_STB, cdf_MTB, cdf_HTB, cdf_XTB, cdf_WHTB, cdf_WXTB],
        #         label = ["DA-STB" "DA-MTB" "DA-HTB" "DA-XTB, λ=0.5" "DA-WHTB" "DA-WXTB, λ=0.5"],
        #         lc = [:dimgray :dimgray :dimgray :crimson :dodgerblue :olivedrab],
        #         ls = [:dot :dash :dashdot :dot :dash :dashdot],
        #         legend = :bottomright,
        #         title = descr, titlefontsize=11,
        #         xlabel = "rank", ylabel= "average number of students"))

    end

    # Norm rank dists against sample size
    for i in (cdf_STB, cdf_MTB, cdf_HTB, cdf_XTB, cdf_WHTB, cdf_WXTB)
        i ./= samp
    end

    return plot([cdf_STB, cdf_MTB, cdf_HTB, cdf_XTB, cdf_WHTB, cdf_WXTB],
                label = ["DA-STB" "DA-MTB" "DA-HTB" "DA-XTB, λ=0.5" "DA-WHTB" "DA-WXTB, λ=0.5"],
                lc = [:dimgray :dimgray :dimgray :crimson :dodgerblue :olivedrab],
                ls = [:dot :dash :dashdot :dot :dash :dashdot],
                legend = :bottomright,
                title = descr, titlefontsize=11,
                xlabel = "rank", ylabel= "average number of students")
end

(n, m_pop, m_unp, samp) = (50, 17, 33, 200)

p = plotter_more(n, m_pop, m_unp, samp)

# savefig(p, string("examples/hybrid/plot.pdf"))
# savefig(p, string("examples/hybrid/plot.png"))
