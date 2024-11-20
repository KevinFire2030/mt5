# How a Simple Candles Strategy Achieved a 90% Win Rate With 7-Year Automated Backtest

## youtube transcript

(257) How a Simple Candles Strategy Achieved a 90% Win Rate With 7-Year Automated Backtest - YouTube
https://www.youtube.com/watch?v=J6VRMhDnVrM

Transcript:
(00:01) hi and welcome back today we will test a very simple pattern that yielded around 90% win rate on the eurous dollar back test this is not a trick I back tested this strategy on two different assets and seven years of data and both equities showed positive profit and an aggregated win rate of 87% actually there's nothing new in this strategy it was published by Larry Williams back in 1999 and it seems that it still works on few currencies and I came across this strategy through one of your messages as the strategy was recently tested by
(00:32) another YouTube channel simple patterns are always easy to test and Implement so thank you for keeping these ideas coming they really bring a lot of interesting approaches to investigate as usual the python code I will be using for this video is available for download from the link in the description so you can try it for yourself and maybe apply your own modifications and experiments for a long setup we will wait for an external red candle meaning the high is greater than the previous High and the low is lower
(01:00) than the previous low so the maxima and the Minima of the current most recent candle are engulfing those of the previous candle this is translated using these three conditions that we will see in detail in the coding part we also need the recent candle to close below the low of the previous candle we Mark the closing price level and we enter the market on the next candle open we exit the market in one of two ways either we hit our 200 Pips stop- loss or in the next session we Close Our Winning trade so we will keep the trade open until
(01:33) either it hits the stop- loss or by the end of a daily session it becomes a winning trade there are other variations of the same pattern on how to enter the market for example we can wait for the price to break above the recent high before entering the market we will leave these for another video I will just stick with what we have explained so far but just to tell you that you might see similar strategies with small tweaks in order to improve the outcome for a short setup we will just consider symmetrical condition itions so whenever we have a
(02:01) green external candle with wide high and low levels and a closing price above the high of the previous candle we set our entry level for the next session and we use a 200 Pips stop-loss waiting for a bearish market to close our short trade with profit okay now let's code this in Python and back test this strategy to see how it performs on historical data this is our Jupiter notebook file I'm defining the first function which is read CSV data frame so to data frame it's going to to read a file and transform it into a data frame it
(02:33) Returns the data frame it also applies some cleaning basic cleaning uh lines then we have read data folder that's going to read a whole folder of CSV files so if you have more than one asset you want to test the strategy on you just have to drop these in one of these folders and use the read data from the folder it's going to return a list of data frames with the file names as well so we can identify which data frame is coming from which file name then then for the total signal this is where we are putting our conditions to generate
(03:05) signals short and long signals so I'm going to define the current position which is the current candles index then we have four different conditions the first one C 0 is is just testing if the open price is above the closing price so if we have a righted candle or a candle in the bearish direction then the second condition is checking if the high is greater than the high of the previous day the uh C2 condition is checking if the low is less than the low of the previous day so now we have somehow a very wide external
(03:37) candle that's wider than the range of the previous candle with two conditions C1 and C2 and C3 is going to test if the close of the outside bar is less than the low of the previous day so the reason I'm saying the previous day or the previous candle is because we're using this on the daily time frame so the CSV files that I'm using are the daily time frame data so if all these conditions that we see here are verified in this case we have a bullish signal this is the return two here so the function is going to return the value
(04:10) two then in the opposite direction if we have a bearish signal we have different conditions we're going to return one in any other case we return zero which means we don't have any signal to enter the market then we have ADD total signal which is going to apply this function on the um data frame and it's going to add a new column called total signal add add Point position column is going to add positions wherever we have uh a signal if it's a bearish signal the point is positioned above the candle if it's a
(04:40) bullish signal the point is positioned below the candle and when I say a point I'm just referring to these positions that we're going to plot here so these purple points are the signals basically that were generated using this algorithm so back to the code we can also use the plot candlestick with signals so it's going to plot the charts and the uh Point positions that were generated in the previous function so now we can use these functions um for example I'm using read data folder it's going to read the folder by default it's called Data
(05:17) folder so just running this is going to run over two csvs because I'm using the EUR US dollar and the GBP US dollar these are the two csvs that I have in my data folder then just to compute the sum of the total signals that we have to compute the number of the signals we have 3155 bearish signals in total and 312 bullish signals we can plot the signals we can plot different slices because we have the data frame we were choose one of two data frames because here we have just two data frames for the two assets then we start we have the
(05:52) start index which is 300 this is where we're starting our slicing up to a number of rows of 355 so up to 655 in terms of slice so this is the starting index where we're plotting and for how many rows are we going to include in our chart so if I put just 10 rows it's going to be 10 candles so 10 days and it's going to look like this so it's not very clear but if we put let's say 100 rows we're going to see 100 candles and so on now for the entry and the exit uh I just included two different strategies one is called strategy one which I
(06:32) didn't explain in this video it simply uses a stoploss distance which is a percentage of the current price and a take profit also as a percentage of the current price and I'm just defining this strategy I kept it there for uh for the experiment so you can you can use it you can drop it we didn't go through it it's uh it's simply something that I've added to the strategy but it works well actually we will test it in a while and we can also optimize these parameters so the percentage of the stoploss distance and the takeprofit distance as well I'm
(07:03) going to run this cell and we can skip this part for now to test strategy number one and actually to optimize it I'm going to uncomment this part going to optimize it on all the data frames all the assets I'm going to comment this line and I'm going to show you the potential that this indicator has now why am I saying the potential because we're optimizing the strategy on two assets and for each of these assets we have the optimal stop-loss percentage and takeprofit percentage providing the maximum return so what can we expect
(07:39) from such an indicator in the best possible conditions this is what we're going to compute now and if I run the aggregated results we can see that we have an aggregated returns of 181% which is amazing number of Trades is 56 and the maximum drow down is just minus 12% and an average drow down of minus 1.
(08:06) 22% the win rate is around 75% and the best trade is 7% worst trade minus 5% and the average trade is 2.3% so these are excellent results just don't forget that we're talking about optimized results so we optimized for each asset what would be the best uh possible stop loss and takeprofit percentage to uh to have the maximum returns I'll not spend a lot of time on this part part of the strategy because this is not what we focused our video on I just I'll just leave it here for you you can experiment on it if you're interested but the um strategy that we
(08:41) explained is strategy two so the size of the lot is 10% of the equity and I Define this function called calculate stop-loss it takes the entry price of the current candle via Pips distance of the stop loss so it's 200 by default the PIP value is 10 to minus four and we need the direction as well because we need to know if we're putting the stop loss level below or above the entry price in case we have a long or a short position then this is the part where the trading happens and back testing happens so first of all if we have any open
(09:16) trades we're going to check the profit loss if it's positive if we have a winning trade we're going to close it this happens at the beginning of each session because we need to close any trades any winning trades that were opened in the previous session and whenever we have a bullish signal and we don't have any currently open trades the current close price is equal to self.
(09:37) dat. close minus one so it's the last candle's closing price the stop loss is equal to whatever the function is going to provide so calculate stop loss we provide the entry price which is the current closing price I'm changing the Pips distance to 250 you can change it to 100 or 150 and 200 default values were 200 and 250 that's what I saw in the literature and in the YouTube video describing this strategy pip value is 10 to minus 4 and the direction is long in this case then we apply the buy function with the size and the stop loss notice
(10:11) that we don't need a take-profit value because anyway we're going to close the trade whenever it becomes a winning trade in the next session or in the future sessions then when we have a bearish signal and we don't have any open position we apply the same approach and we um use the cell function to open a selling position or a short position so I'm going to run this cell and I'm going to comment this part which is basically optimizing the uh stop-loss percentage and takeprofit percentage so we don't have these parameters in this
(10:43) function in this new class or new strategy these were for the previous one and I'm just going to run it so that's not an optimized strategy we're going to run it as is and we need to change this from strategy 1 to strategy 2 so we have a win rate of 8 7% 87.5% we have an aggregated returns of 26% which is not extremely high for such a high win rate and I'm going to explain to you why we're getting a high win rate but our aggregated returns are still relatively low but the maximum drow down is - 11% and an average drow down ofus
(11:21) 1.2% this is acceptable it's good so we can actually plot the equity curves of the assets we are trading and we can see that at the beginning we had really good time so if you aggregate these two uh curves until this point here the index 1,500 it's going to provide you an excellent set of results but then we have one of these two I think it's the EUR US dollar went down actually it wasn't the strategy wasn't working anymore on this pair and it was actually covered up by a spike with the GBP US dollar so it kind of compensates States
(12:00) so all in all we have 12% in returns and 14% in returns between the EUR US dollar and gpp then we have access to the results for each of these two assets so if you go to results zero for example the first elements we can get the results for Euro US dollar and that's 12% uh the Buy and Hold returns is minus 5% the maximum drow down - 11 average drow down -1% and so on so we have a win rate of 90% that's on the EUR US dollar and if we try it for the GBP let's run this so we have a win rate of 84.5% and the returns of around 14% And
(12:43) so on now U the most important thing I want to highlight in this strategy is that we have a high win rate we have an extremely high win rate but we not very impressed by the returns remember that these are results on The Daily time frame and we are closing any winning trade immediately on the next day at the beginning of any day we're closing those trades and it could be that at some point these trades didn't have the chance to be opened long enough to provide greater uh returns so at the same time this is where the high win
(13:16) rate is coming from because if every time you have a winning trade you're going to close it that's a very high win rate however how much you are winning per trade is not going to be very impressive and this is what we're seeing here so in brief the 200 Pips stop-loss distance that we have introduced in in this strategy is way larger than the takeprofit distance practically that we're using so we're not really using a take-profit distance but we're actually closing the trades very quickly and this is as if we were using a very uh narrow
(13:50) take-profit distance this is why we have a very high win rate but nothing impressive related to the aggregated returns remember that this is the daily time frame and we're using data from 2017 up to 2024 so that's 7 years of data so whatever you are seeing here as returns it's over 7 years of data it's not much the win rate is impressive the aggregated returns are not very impressive though but I would still give some credit to the Simplicity of the strategy and honestly it's still achieving relatively safe results with
(14:25) very limited drow down percentage even though I did add a small Commission part in the back test to account for minimal trading fees and that's all I had to tell you for this one thank you for staying that long until our next one try safe and see you next time

## transcript summary

이 전략은 Larry Williams가 1999년에 발표한 간단한 매매 전략으로, 최근 EUR/USD와 GBP/USD에 대해 백테스트를 통해 약 87%의 높은 승률을 기록했습니다. 기본 개념은 외부 캔들 패턴을 이용한 매매로, 일일 차트 기준으로 외부 캔들이 발생하면 다음 세션에 진입하고, 승리한 거래는 다음 세션 시작에 청산하는 방식입니다.

### 매매 전략 요약:
#### 롱 진입 조건:

- 외부 빨간 캔들이 형성되었을 때 (현재 고점이 이전 고점보다 높고 저점이 이전 저점보다 낮음).
- 최근 캔들이 이전 캔들의 저점보다 낮은 가격에서 종가를 형성할 경우 다음 캔들 오픈 시점에 매수 진입.
- 200핍 손절선 설정. 거래가 수익 구간에 진입하면 다음 세션 시작 시점에 청산.

#### 숏 진입 조건:

- 외부 초록 캔들이 형성되었을 때 (현재 고점이 이전 고점보다 높고 저점이 이전 저점보다 낮음).
- 최근 캔들이 이전 캔들의 고점보다 높은 가격에서 종가를 형성할 경우 다음 캔들 오픈 시점에 매도 진입.
- 200핍 손절선 설정. 거래가 수익 구간에 진입하면 다음 세션 시작 시점에 청산.

#### 추가 사항:

별도 최적화된 전략(손절 및 익절 비율 조정)도 실험해보았지만, 설명된 주 전략과는 다릅니다.
결과적으로, 이 전략은 높은 승률(약 87%)을 보였으나 장기적 총수익률은 낮은 편이었습니다.
주 이유는 일일 차트로 다음 세션에 즉시 청산하는 구조에서 비롯되며, 이는 높은 승률을 유지하지만 개별 거래의 수익률이 제한되는 효과를 가져옵니다.
총 수익률은 크지 않지만 낮은 최대 손실률과 제한된 드로우다운으로 안정적인 결과를 보입니다.
결론적으로, 이 전략은 높은 승률과 단순성, 낮은 리스크를 가지고 있지만, 장기적으로 큰 수익률을 기대하기 어렵습니다.



## total_signals

```python
def total_signal(df, current_candle):
    current_pos = df.index.get_loc(current_candle)
    c0 = df['Open'].iloc[current_pos] > df['Close'].iloc[current_pos]
    # Condition 1: The high is greater than the high of the previous day
    c1 = df['High'].iloc[current_pos] > df['High'].iloc[current_pos - 1]
    # Condition 2: The low is less than the low of the previous day
    c2 = df['Low'].iloc[current_pos] < df['Low'].iloc[current_pos - 1]
    # Condition 3: The close of the Outside Bar is less than the low of the previous day
    c3 = df['Close'].iloc[current_pos] < df['Low'].iloc[current_pos - 1]

    if c0 and c1 and c2 and c3:
        return 2  # Signal for entering a Long trade at the open of the next bar
    
    c0 = df['Open'].iloc[current_pos] < df['Close'].iloc[current_pos]
    # Condition 1: The high is greater than the high of the previous day
    c1 = df['Low'].iloc[current_pos] < df['Low'].iloc[current_pos - 1]
    # Condition 2: The low is less than the low of the previous day
    c2 = df['High'].iloc[current_pos] > df['High'].iloc[current_pos - 1]
    # Condition 3: The close of the Outside Bar is less than the low of the previous day
    c3 = df['Close'].iloc[current_pos] > df['High'].iloc[current_pos - 1]
    
    if c0 and c1 and c2 and c3:
        return 1

    return 0
```

### 포지션 신호 조건:
1. c0: 시가 > 종가
현재 캔들이 음봉임을 나타냅니다. 이는 매도 압력이 있었음을 의미합니다.
2. c1: 현재 고가 > 이전 고가
현재 캔들의 고가가 이전 캔들의 고가보다 높아졌음을 나타냅니다. 이는 매수 압력이 증가했음을 시사합니다.
3. c2: 현재 저가 < 이전 저가
현재 캔들의 저가가 이전 캔들의 저가보다 낮아졌음을 나타냅니다. 이는 시장의 변동성이 증가했음을 의미합니다.
4. c3: 종가 < 이전 저가
5. 
현재 캔들의 종가가 이전 캔들의 저가보다 낮아졌음을 나타냅니다. 이는 매도 압력이 강했음을 시사합니다.
이 네 가지 조건이 모두 충족되면, 시장이 과매도 상태에 도달했을 가능성이 있으며, 반등할 가능성이 있다고 판단하여 롱 포지션을 진입하라는 신호를 생성합니다.

### 숏 포지션 신호 조건:
1. c0: 시가 < 종가
현재 캔들이 양봉임을 나타냅니다. 이는 매수 압력이 있었음을 의미합니다.
2. c1: 현재 저가 < 이전 저가
현재 캔들의 저가가 이전 캔들의 저가보다 낮아졌음을 나타냅니다. 이는 시장의 변동성이 증가했음을 의미합니다.
3. c2: 현재 고가 > 이전 고가
현재 캔들의 고가가 이전 캔들의 고가보다 높아졌음을 나타냅니다. 이는 매수 압력이 강했음을 시사합니다.
4. c3: 종가 > 이전 고가
현재 캔들의 종가가 이전 캔들의 고가보다 높아졌음을 나타냅니다. 이는 매수 압력이 강했음을 시사합니다.
이 네 가지 조건이 모두 충족되면, 시장이 과매수 상태에 도달했을 가능성이 있으며, 하락할 가능성이 있다고 판단하여 숏 포지션을 진입하라는 신호를 생성합니다.

이러한 조건들은 시장의 과매수 또는 과매도 상태를 식별하여 반대 방향으로의 움직임을 예측하는 데 사용됩니다. 이는 기술적 분석에서 흔히 사용되는 전략 중 하나로, 시장의 반전 시점을 포착하려는 시도입니다.

## 매매 전략

```python
class Strat_02(Strategy):
    mysize = 0.1  # Trade size

    def init(self):
        super().init()
        self.signal1 = self.I(SIGNAL)  # Assuming SIGNAL is a function that returns signals

    def calculate_stop_loss(self, entry_price, pips=200, pip_value=0.0001, direction="long"):
        """
        Calculate the stop loss distance given the entry price, number of pips, and pip value.
        
        Parameters:
        entry_price (float): The price at which the trade is entered.
        pips (int): The number of pips for the stop loss. Default is 200.
        pip_value (float): The value of one pip. Default is 0.0001 for most currency pairs.
        direction (str): 'long' or 'short' to indicate the trade direction.
        
        Returns:
        float: The stop loss price.
        """
        sl_distance = pips * pip_value
        if direction == "long":
            stop_loss_price = entry_price - sl_distance
        elif direction == "short":
            stop_loss_price = entry_price + sl_distance
        else:
            raise ValueError("direction must be 'long' or 'short'")

        return stop_loss_price

    def next(self):
        super().next()

        # Check if any trades are winning and close them
        for trade in self.trades:
            if trade.pl > 0:
                trade.close()

        # Handle new signals
        if self.signal1[-1] == 2 and not self.position:
            current_close = self.data.Close[-1]
            sl = self.calculate_stop_loss(entry_price=current_close, pips=250, pip_value=0.0001, direction="long")
            self.buy(size=self.mysize, sl=sl)

        elif self.signal1[-1] == 1 and not self.position:
            current_close = self.data.Close[-1]
            sl = self.calculate_stop_loss(entry_price=current_close, pips=250, pip_value=0.0001, direction="short")
            self.sell(size=self.mysize, sl=sl)
```

### 백테스트 결과

Start                     2017-06-06 00:00:00
End                       2024-06-14 00:00:00
Duration                   2565 days 00:00:00
Exposure Time [%]                   45.355191
Equity Final [$]                  5698.753885
Equity Peak [$]                   6025.001308
Return [%]                          13.975078
Buy & Hold Return [%]               -1.729428
Return (Ann.) [%]                    1.512417
Volatility (Ann.) [%]                4.607678
Sharpe Ratio                         0.328238
Sortino Ratio                        0.512531
Calmar Ratio                         0.199269
Max. Drawdown [%]                   -7.589835
Avg. Drawdown [%]                   -1.266538
Max. Drawdown Duration     1066 days 00:00:00
Avg. Drawdown Duration       78 days 00:00:00
# Trades                                  220
Win Rate [%]                        84.545455
Best Trade [%]                       1.791137
Worst Trade [%]                     -2.157145
Avg. Trade [%]                       0.059485
Max. Trade Duration          54 days 00:00:00
Avg. Trade Duration           5 days 00:00:00
Profit Factor                        1.230404
Expectancy [%]                       0.063373
SQN                                  1.011295
_strategy                            Strat_02
_equity_curve                             ...
_trades                        Size  Entry...



