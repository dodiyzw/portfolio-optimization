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
AlphaVantage.GLOBAL[]
client = AlphaVantage.GLOBAL[]

client.key = "3WFOMYKIAVICKFU6"

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

ls[1]
optimize_return(ls[1], load_object("../data/$(strings[1])_weekly.jld2"), 10 / 100).vari


#optimize for weekly profit
ticker1 = ["AAPL", "SBUX", "MCD"]
ticker2 = ["AAPL", "SBUX", "MCD", "NKE", "KO"]
ticker3 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT"]
ticker4 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE"]
ticker5 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE", "PG", "JNJ"]
ls = [ticker1, ticker2, ticker3, ticker4, ticker5]


#vary expected return
returns = collect(0.03:0.01:0.30)
fig = Figure(resolution = (1500, 800), textsize = 20)
ax1 = Axis(fig[1, 1], xlabel = "risk", ylabel = "return", width = 800, height = 600)
for i = 1:length(ls)
    opt = [
        optimize_return(ls[i], load_object("../data/$(strings[i])_weekly.jld2"), r) for
        r in returns
    ]
    x = [sqrt(opt[i].vari) * 100 for i = 1:length(opt)]
    scatter!(ax1, x, returns .* 100, color = my_c[i], label = join(ls[i], "_"))
end
fig[1, 2] = Legend(fig, ax1)
resize_to_layout!(fig)
fig
opt = optimize_return(ls[5], load_object("../data/$(strings[4])_weekly.jld2"), 10 / 100)
avg_r = opt.avg * 100
volatil = opt.vol
for i = 1:length(avg_r)
    text!(
        ax1,
        ls[5][i],
        position = (volatil[i], avg_r[i]),
        textsize = 15,
        font = "CMU Serif",
    )
end

strings[4]
load_object("../data/$(strings[4])_weekly.jld2")

#optimize for monthly profit




# optimize_return(price_week_month(["AAPL", "SBUX", "MCD", "NKE", "KO"], interval = "monthly_adjusted"), 30/100)
@. optimize_return(price_week_month(ls, interval = "monthly_adjused"), returns)

#optimize for annual profit     

###THIS WORKS

strings = [join(l, "_") for l in ls]

#vary returns
returns = collect(0.03:0.01:0.40)

fig = Figure(resolution = (2000, 2000), textsize = 20, font = "CMU Serif")
ax1 = Axis(
    fig[1, 1],
    xlabel = "risk (SD)",
    ylabel = "return (%)",
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
    scatter!(ax1, x, returns .* 100, color = my_c[i], label = strings[i])
end
fig[1, 2] = Legend(fig, ax1, "Stocks in Portfolio", framevisible = false, labelsize = 18, font = "CMU Serif")

opt =
    optimize_return(ls[end], load_object("../data/$(strings[end])_annually.jld2"), 10 / 100)
avg_r = opt.avg * 100
volatil = opt.vol
for i = 1:length(avg_r)
    text!(
        ax1,
        ls[end][i],
        position = (volatil[i], avg_r[i]),
        textsize = 18,
        font = "CMU Serif",
    )
end
resize_to_layout!(fig)
fig


