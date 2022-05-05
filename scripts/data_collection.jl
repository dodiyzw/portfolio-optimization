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

AlphaVantage.GLOBAL[]
client = AlphaVantage.GLOBAL[]

client.key = "YOURKEY"


@inline each_returns(mat) = [(mat[ii,:] .- mat[ii+1,:]) ./ mat[ii+1,:] for ii=1:size(mat,1)-1] #rows of the matrix
function price_week_month(tickers, ;interval::String = "weekly_adjusted")
    @argcheck in(interval, ["weekly_adjusted", "monthly_adjusted", "annual_adjusted"])
    if interval == "weekly_adjusted"
        df = @. DataFrame(time_series_weekly_adjusted(tickers, outputsize = "full")) #broadcast over all function
        #if they have different length (listed at different time), then take the shortest available
        price = [df[i][1:minimum(nrow.(df)),"adjusted close"] for i=1:length(df)]
        m = hcat(price...)
        returns = each_returns(m)
        returns_mat = reduce(hcat,returns)'
        return returns_mat
    
    elseif interval == "monthly_adjusted"
        df = @. DataFrame(time_series_monthly_adjusted(tickers, outputsize = "full")) #broadcast over all function
        price = [df[i][1:minimum(nrow.(df)),"adjusted close"] for i=1:length(df)]
        m = hcat(price...)
        returns = each_returns(m)
        returns_mat = reduce(hcat,returns)'
        return returns_mat
    end
    if interval == "annual_adjusted"
        df = @. DataFrame(time_series_monthly_adjusted(tickers, outputsize = "full")) #broadcast over all function
        price = [df[i][1:12:end,"adjusted close"] for i=1:length(df)]
        m = hcat(price...)
        returns = each_returns(m)
        returns_mat = reduce(hcat,returns)'
        return returns_mat
    end
end


ticker1 = ["AAPL", "SBUX", "MCD"]
ticker2 = ["AAPL", "SBUX", "MCD", "NKE", "KO"]
ticker3 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT"]
ticker4 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE"]
ticker5 = ["AAPL", "SBUX", "MCD", "NKE", "KO", "DIS", "MSFT", "XOM", "PFE", "PG", "JNJ"]
ls = [ticker1, ticker2, ticker3, ticker4, ticker5]

for l in ls
    string = join(l, "_")
    if (!isfile("../data/$(string)_weekly.jld2"))
        res = price_week_month(l)
        save_object("../data/$(string)_weekly.jld2", res)
    end
    if (!isfile("../data/$(string)_monthly.jld2"))
        res = price_week_month(l, interval =  "monthly_adjusted")
        save_object("../data/$(string)_monthly.jld2", res)
    end
    if (!isfile("../data/$(string)_annually.jld2"))
        res = price_week_month(l, interval =  "annual_adjusted")
        save_object("../data/$(string)_annually.jld2", res)
    end
end 


#collection of "growth" stock 
tick1 = ["FB", "TSLA", "NFLX"]
tick2 = ["FB", "TSLA", "NFLX", "GOOG"]
tick3 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC"]
tick4 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC", "ZM", "SQ"]
tick5 = ["FB", "TSLA", "NFLX", "GOOG", "SE", "CRWD", "TDOC", "ZM", "SQ", "MRNA", "CRSP"]
ls = [tick1, tick2, tick3, tick4, tick5]
#for growth stocks, we are not performing annual analysis
for l in ls
    string = join(l, "_")
    if (!isfile("../data/$(string)_weekly.jld2"))
        res = price_week_month(l)
        save_object("../data/$(string)_weekly.jld2", res)
    end
    if (!isfile("../data/$(string)_monthly.jld2"))
        res = price_week_month(l, interval =  "monthly_adjusted")
        save_object("../data/$(string)_monthly.jld2", res)
    end
end 

