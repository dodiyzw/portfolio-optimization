# portfolio-optimization using MVO
This project is a first attempt at using mean-variance optimization to optimize stock portfolio. 

This project is interested in learning to optimize the risk and return associated with stocks in a portfolio. This project aims to **1) produce a portfolio that minimizes risk and 2) find the weightage of stock combinations that has the lowest risk** for a specific return rate in mind. 

First, this project uses the Mean-Variance Portfolio (MVO) Theory to find the stock weightage of a portfolio that minimizes risk for a specific **annual** return rate. This is studied using blue-chip stocks in the US markets that has been listed on the stock market since 1990s so that there is sufficient data to perform Mean-Variance Optimization. 

Subsequently, this project uses the MVO to optimize for stock weightage in a portfolio that minimizes risk on a **weekly** and **monthly** basis.

### Data Collection 
Stock market data is collected using the *AlphaVantage* API through the *AlphaVantage.jl* package in Julia. An API key is required to obtain data using the API. 

As it is too slow to make an API call and optimize at the same time due to large dataset and many number of API requests, API calls were made and data were stored as *JLD2* files. Data files can be found in the *data* folder.

To obtain data for different stocks, simply obtain the API key and input the desired ticker symbol. 

### Optimization set-up 
The optimization used is as follow, where the variance (risk) is minimized 

<p align="center"><img src="https://render.githubusercontent.com/render/math?math=\large\min  x^{T}Qx"> </p>
subjected to 
<p align="center"><img src="https://render.githubusercontent.com/render/math?math=\large\ ux \geq R"> </p>
<p align="center"><img src="https://render.githubusercontent.com/render/math?math=\large\ \Sigma x_{i} = 1"> </p>

where $x_{i}$ refers to weightage of the each stocks in the portfolio, $Q$ refers to the covariance of the stocks in the portfolio, and $R$ refers to the desired return rate from the portfolio. $u$ refers to the mean return of stocks. 

### Example of portfolio allocation for different expected annual return 
<p>
    <img src="output/AAPL_SBUX_MCD_NKE_KO_DIS_MSFT_XOM_PFE_PG_JNJbar__annual.jpg?raw=true" width="800" height="600" />
</p>

### Limitation 
1) the portfolio in this project **does not combine high growth and blue chip stocks into the same portfolio, making the individual portfolio rather small**
2) this project **only uses stocks from US market} and this may not provide sufficient diversification**
3) this project is **based on historical data** and the past does not necessarily tells us future returns and risks
4) the optimization in this project **does not constraint weightage of stocks in portfolio based on industry**
