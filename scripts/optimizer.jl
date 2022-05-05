using DataFrames, Dates
using AlphaVantage
using CairoMakie
using Statistics
using StatsBase
using LinearAlgebra
using JuMP
import Ipopt
using ArgCheck
using JLD2
using Colors

my_blue = colorant"rgba(100,143,255,0.9)"
my_purple = colorant"rgba(120,94,240,0.9)"
my_pink = colorant"rgba(220,38,127,0.9)"
my_orange = colorant"rgba(254,97,0,0.9)"
my_yellow = colorant"rgba(255,176,0,0.9)"
my_c = [my_blue, my_purple, my_pink, my_orange, my_yellow]

struct Optimized
    tic::Vector{String}         #ticker of stocks if i want....
    avg::Vector{Float64}        #mean return of stocks
    vol::Vector{Float64}        #volatility of each stock
    vari::Float64               #objective value from objective function
    w::Vector{Float64}          #weight of each stock
end
# AlphaVantage.GLOBAL[]
# client = AlphaVantage.GLOBAL[]

# client.key = "YOURKEY"

@inline each_returns(mat) =
    [(mat[ii, :] .- mat[ii+1, :]) ./ mat[ii+1, :] for ii = 1:size(mat, 1)-1] #rows of the matrix

#can split our study to weekly, monthly, yearly
function optimize_return(tickers, mat, exp_return)
    t = tickers
    μ = Statistics.mean(mat, dims = 1) |> vec   #mean return
    Q = Statistics.cov(mat)       #covariance
    # Q[1,1] / (volatility[1] / 100)^2
    n = size(Q, 1)
    root_cov = [Q[i, i] for i = 1:n]
    volatility = sqrt.(root_cov) .* 100
    portfolio = Model(Ipopt.Optimizer)
    #Suppress unnecessary output, while solver works through different combinations#
    set_silent(portfolio)
    #Objective function & and constraints#
    @variable(portfolio, x[1:n] >= 0)
    @objective(portfolio, Min, x' * Q * x)
    # @constraint(portfolio, sum(x) == 10000)
    @constraint(portfolio, sum(μ[i] * x[i] for i = 1:n) >= exp_return)
    @constraint(portfolio, sum(x[i] for i = 1:n) == 1)
    # @constraint(portfolio, x[2] + x[5] <= 0.5)
    optimize!(portfolio)
    var = objective_value(portfolio)
    weights = value.(x)
    # return var, weights
    # return μ
    return Optimized(t, μ, volatility, var, weights)
end

function optimize_growth_return(tickers, mat, exp_return)
    t = tickers
    μ = Statistics.mean(mat, dims = 1) |> vec   #mean return
    Q = Statistics.cov(mat)       #covariance
    # Q[1,1] / (volatility[1] / 100)^2
    n = size(Q, 1)
    root_cov = [Q[i, i] for i = 1:n]
    volatility = sqrt.(root_cov) .* 100
    portfolio = Model(Ipopt.Optimizer)
    #Suppress unnecessary output, while solver works through different combinations#
    set_silent(portfolio)
    #Objective function & and constraints#
    @variable(portfolio, x[1:n] >= 0)
    @objective(portfolio, Min, x' * Q * x)
    # @constraint(portfolio, sum(x) == 10000)
    @constraint(portfolio, sum(μ[i] * x[i] for i = 1:n) >= exp_return)
    @constraint(portfolio, sum(x[i] for i = 1:n) == 1)
    # @constraint(portfolio,  x[findfirst(tickers .== lim_50)] <= 0.50)   #lets us limit the weightage of specific stock to 50%
    # @constraint(portfolio, x[1] + x[2] <= 0.50)
    # @constraint(portfolio, x[2] + x[5] <= 0.5)
    optimize!(portfolio)
    var = objective_value(portfolio)
    weights = value.(x)
    # return var, weights
    # return μ
    return Optimized(t, μ, volatility, var, weights)
end


#optimize for weekly profit
tick1 = ["FB", "TSLA", "NFLX"]
tick2 = ["FB", "TSLA", "NFLX", "GOOG"]
tick3 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC"]
tick4 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC", "ZM", "SQ"]
tick5 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC", "ZM", "SQ", "MRNA", "CRSP"]
ls = [tick1, tick2, tick3, tick4, tick5]
strings = [join(l, "_") for l in ls]

ticker1 = ["AAPL", "SBUX", "MCD"]
ticker2 = ["AAPL", "SBUX", "MCD", "NKE", "KO"]
ticker3 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT"]
ticker4 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE"]
ticker5 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE", "PG", "JNJ"]
ls = [ticker1, ticker2, ticker3, ticker4, ticker5]
strings = [join(l, "_") for l in ls]
#vary expected return
returns = collect(0.0001:0.0002:0.03)
# returns = collect(0.0001:0.0002:0.01)
fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(
    fig[1, 1],
    ylabel = "risk (SD)",
    xlabel = "return (%)",
    width = 1000,
    height = 600,
    xlabelsize = 18,
    ylabelsize = 18,
)
for i = 1:length(ls)
    opt = [
        optimize_growth_return(ls[i], load_object("../data/$(strings[i])_weekly.jld2"), r) for
        r in returns
    ]
    x = [sqrt(opt[i].vari) * 100 for i = 1:length(opt)]
    scatter!(ax1, returns .* 100, x, color = my_c[i], label = join(ls[i], "_"))
end
fig[1, 2] = Legend(fig, ax1, "Stocks in Portfolio", framevisible = false, labelsize = 18, font = "CMU Serif", titlesize = 18)

fig 
opt = optimize_growth_return(ls[end], load_object("../data/$(strings[end])_weekly.jld2"), 0.01)
avg_r = opt.avg * 100
volatil = opt.vol
scatter!(ax1, avg_r, volatil, marker = :x, markersize = 15, color = :red)
for i = 1:length(avg_r)
    text!(
        ax1,
        ls[end][i],
        position = (avg_r[i], volatil[i]),
        textsize = 18,
        font = "CMU Serif",
    )
end
hidedecorations!(ax1, label = false, ticklabels = false, ticks = false)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])_weekly.pdf", fig)

#bar plot
opt1 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_weekly.jld2"), 0.01)

opt2 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_weekly.jld2"), 3)

w_3 = opt1.w
w_40 = opt2.w
fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(fig[1, 1]; xlabel = "stocks", ylabel = "weight", width = 1000, height = 600, xlabelsize = 18, ylabelsize = 18, xticks = (collect(2:2:22) , ls[end]))
ls = [i for i=2:2:22 for j=1:2]
labels1 = ["0.01%", "3%"]
elements = [PolyElement(polycolor = my_c[i]) for i in 1:length(labels1)]
title = "Returns"
heights = collect(Iterators.flatten(zip(w_3,w_40)))
grp = [j for i=1:length(ls)/2 for j=1:2]
barplot!(ax1, ls, heights, dodge = grp, color = my_c[grp], label = labels1)
Legend(fig[1,2], elements, labels1, title)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])bar__weekly.pdf", fig)

#optimize for monthly profit
returns = collect(0.01:0.001:0.12)
# returns = collect(0.001:0.0005:0.030)
fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(
    fig[1, 1],
    ylabel = "risk (SD)",
    xlabel = "return (%)",
    width = 1000,
    height = 600,
    xlabelsize = 18,
    ylabelsize = 18,
)
for i = 1:length(ls)
    opt = [
        optimize_growth_return(ls[i], load_object("../data/$(strings[i])_monthly.jld2"), r) for
        r in returns
    ]
    x = [sqrt(opt[i].vari) * 100 for i = 1:length(opt)]
    scatter!(ax1, returns .* 100, x, color = my_c[i], label = join(ls[i], "_"))
end
fig[1, 2] = Legend(fig, ax1, "Stocks in Portfolio", framevisible = false, labelsize = 18, font = "CMU Serif", titlesize = 18)

fig 
opt = optimize_growth_return(ls[end], load_object("../data/$(strings[end])_monthly.jld2"), 0.01)
avg_r = opt.avg * 100
volatil = opt.vol
scatter!(ax1, avg_r, volatil, marker = :x, markersize = 15, color = :red)
for i = 1:length(avg_r)
    text!(
        ax1,
        ls[end][i],
        position = (avg_r[i], volatil[i]),
        textsize = 18,
        font = "CMU Serif",
    )
end
hidedecorations!(ax1, label = false, ticklabels = false, ticks = false)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])_monthly.pdf", fig)

#bar plot
opt1 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_monthly.jld2"), 1)

opt2 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_monthly.jld2"), 12)

w_3 = opt1.w
w_40 = opt2.w
fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(fig[1, 1]; xlabel = "stocks", ylabel = "weight", width = 1000, height = 600, xlabelsize = 18, ylabelsize = 18, xticks = (collect(2:2:22) , ls[end]))
ls = [i for i=2:2:22 for j=1:2]
labels1 = ["1%", "12%"]
elements = [PolyElement(polycolor = my_c[i]) for i in 1:length(labels1)]
title = "Returns"
heights = collect(Iterators.flatten(zip(w_3,w_40)))
grp = [j for i=1:length(ls)/2 for j=1:2]
barplot!(ax1, ls, heights, dodge = grp, color = my_c[grp], label = labels1)
Legend(fig[1,2], elements, labels1, title)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])bar__monthly.pdf", fig)


#optimize for annual profit     
ticker1 = ["AAPL", "SBUX", "MCD"]
ticker2 = ["AAPL", "SBUX", "MCD", "NKE", "KO"]
ticker3 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT"]
ticker4 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE"]
ticker5 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE", "PG", "JNJ"]
ls = [ticker1, ticker2, ticker3, ticker4, ticker5]

strings = [join(l, "_") for l in ls]

#vary returns
returns = collect(0.03:0.005:0.40)

fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(
    fig[1, 1],
    ylabel = "risk (SD)",
    xlabel = "return (%)",
    width = 1000,
    height = 600,
    xlabelsize = 18,
    ylabelsize = 18,
)
for i = 1:length(ls)
    opt = [
        optimize_return(ls[i], load_object("../data/$(strings[i])_annually.jld2"), r)
        for r in returns
    ]
    x = [sqrt(opt[i].vari) * 100 for i = 1:length(opt)]
    scatter!(ax1, returns .* 100, x, color = my_c[i], label = strings[i])
end
fig[1, 2] = Legend(fig, ax1, "Stocks in Portfolio", framevisible = false, labelsize = 18, font = "CMU Serif", titlesize = 18)

opt =
    optimize_return(ls[end], load_object("../data/$(strings[end])_annually.jld2"), 10 / 100)
avg_r = opt.avg * 100
volatil = opt.vol
scatter!(ax1, avg_r, volatil, marker = :x, markersize = 15, color = :red)
for i = 1:length(avg_r)
    text!(
        ax1,
        ls[end][i],
        position = (avg_r[i]-0.5, volatil[i]+1),
        textsize = 18,
        font = "CMU Serif",
    )
end
hidedecorations!(ax1, label = false, ticklabels = false, ticks = false)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])_annual.pdf", fig)

#bar plot
opt1 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_annually.jld2"), 3 / 100)

opt2 =
    optimize_return(ls[end], load_object("../data/$(strings[end])_annually.jld2"), 40 / 100)

w_3 = opt1.w
w_40 = opt2.w
fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(fig[1, 1]; xlabel = "stocks", ylabel = "weight", width = 1000, height = 600, xlabelsize = 18, ylabelsize = 18, xticks = (collect(2:2:22) , ticker5))
ls = [i for i=2:2:22 for j=1:2]
labels1 = ["3%", "40%"]
elements = [PolyElement(polycolor = my_c[i]) for i in 1:length(labels1)]
title = "Returns"
heights = collect(Iterators.flatten(zip(w_3,w_40)))
grp = [j for i=1:length(ls)/2 for j=1:2]
barplot!(ax1, ls, heights, dodge = grp, color = my_c[grp], label = labels1)
Legend(fig[1,2], elements, labels, title)
resize_to_layout!(fig)
fig
save("../output/$(strings[end])bar__annual.pdf", fig)



