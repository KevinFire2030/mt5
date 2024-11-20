# Trading with Python: Simple Scalping Strategy
## Script
(256) Trading with Python: Simple Scalping Strategy - YouTube
https://www.youtube.com/watch?v=C3bh6Y4LpGs

Transcript:
(00:00) hi and welcome again this increasing Equity curve is the main reason I like this strategy and I'm sharing it in this video so you can also optimize it and maybe further improve these results the back test of this trading strategy showed positive returns of over 200% for a testing period of almost 3 months and also a steady increase in the total Equity so today we will test this simple sculping system using python strategy can be used in manual trading as well as in algorithmic trading it's very simple and it for both trading Styles we will
(00:32) use the 5 minutes time frame to accelerate the pace of trading and increase the number of Trades I also needed to optimize the risk reward ratio and other parameters used for this trading strategy this can be easily done using Python and numerical back testing the python code that I'm using for this back test is available for download from the link in the description of this video so you can download it to follow through and use it for your experiments this strategy uses two moving average curv curves to estimate the current
(01:02) Trend if the fast moving average is above the slow moving average then we have an uptrend and in the opposite direction if the fast moving average is below the slow moving average then we have a downtrend in an uptrend we only consider long positions and in a downtrend we only consider short positions then we can use Binger band edges to trigger position entry points so if we have an uptrend we're looking for a long position then if the price crosses the low lower Ballinger curve we open a long position and in the opposite
(01:34) direction in a downtrend if the price crosses the upper Ballinger band then we enter a short position this is based on the assumption that the price will always converge to the center of the Ballinger Band After Crossing extreme values and on top of it we are trading in the same direction of the moving average Trend so we consider this as a confirmation of the signal the exact numerical values for the length of the fast and slow moving averages and the parameters of the Binger band will be detailed in the coding part these might
(02:06) not be the best values but they worked well so far so you might want to do your own research afterwards and use an improved set of parameters then when the trades are opened or when we have an open trade we can set the stop-loss distance in relation with the volatility of the market using the ATR and multiplying by a variable or a parameter that we will name stoploss coefficient take profit this is just the stoploss distance multiplied by the takeprofit stoploss ratio which is also a parameter that we can change depending on our
(02:38) trading style and this is it if you have watched my previous video you would notice it's very similar strategy I have just replaced the trend detection with the two EMAs the fast curve and the slow curve because I noticed it decreases the lag in the sense that it also increases the total number of Trades now there's only one way to find out if the system is worth it let's try it out and put it under the test using python so we will back test this strategy on historical data for a few months and see what happens to our equity and just another
(03:10) reminder the python code we will use now is available for download There's a link in the description of this video you can get it for free and apply your own experiments and a quick hint You might want to start by applying a better trade management approach since I haven't exhausted all the options on how to define the stop-loss and takeprofit values this might improve the results that you will see in the back test so this is our jupitor notebook file the first cell is just for importing the data so I'm using uh CSV file the Euro
(03:40) US dollar uh candles 5 minutes time frame the um dates are between 2019 and 2022 so we have enough data on the 5 minutes time frame that's a lot of candles and here we're just uh reformatting the index I'm just removing the fractions of seconds because these are not needed and and I'm casting the index into a daytime format using the correct format so now we have a correct format of the data then I'm filtering out all the candles where we didn't have any movement and this is where the candle's high is equal to the candle's
(04:16) low so we don't need these These are usually days off and weekends and days where the market was basically closed so we don't have any movement we're not interested in this data and uh we're setting the index to GMT time after we have corrected format so this is just formatting the data then I'm using pandascore technical analysis module to compute the EMA the slow EMA which is length 50 and the fast EMA which is length 30 so these are our two moving averages that will help us to detect the uh Trend direction uptrend or downtrend
(04:50) the RSI is not used here I just kept it because I was experimenting on an exit strategy using the RSI as well and this line computes the Binger band so it's a length 15 and the standard deviation of 1.5 then we have the ATR the average true range for um the volatility measurements and uh this will help us Define the stop-loss distance and consequently the uh takeprofit distance as well and that's it we basically join everything into our data frame we have the data and that's our data frame this is how it looks like we have the uh GMT
(05:23) time as an index the Open high low close the volume the EMA slow the EMA fast the RSI which we will not use now but it's here in case you need to experiment on it I kept a commented section of the code in here this is our exit strategy and we have the ATR we have the Binger bands uh upper and lower and middle lines and so on so we have all what we need to start this strategy this is a function called EMA signal it's going to take the data frame the current candle as well and the number of back candles and the way we're going to do this we're
(05:59) going to t test if the fast moving average is above the slow moving average or below it depending on which direction we want to trade so it's going to detect the trend but we don't need to test it for one candle it's not tested for the current candle it's also tested for the last consecutive candles it can be the last six consecutive candles eight consecutive candles and so on and this is why we have the back candles parameter right here so we don't want to uh test the U a signal just for one candle it might be too noisy to do so we
(06:33) want the trend to be the same and confirmed for the last let's say uh six candles and if we consider Six Candles on the 5 minutes time frame that's 6 * 5 which means it's 30 minutes so the last 30 minutes we've had either an uptrend or a downtrend you might want to change this one and test if you get better results than the results we are getting in this video so that's it I'm applying this function to our data frame and this is what we will call EMA signal I'm adding this into our data frame as a new column so now we have the emema signal
(07:05) or the trend signal then we um can apply the function called total signal which takes also the data frame the current candles index and the number of back candles so it would compute the EMA signal it's using the previous function to compute the trend if we have a trend up so if the EMA signal is equal to two we are in an uptrend we're looking for a buying position in this case and we're waiting for the closing price of the current candle to close below the lower Ballinger band okay of the current candle this is what it does so these are
(07:40) our two conditions here in which case we have a long signal and we return two in the opposite case if the EMA signal is equal to one so it's a downtrend and the closing of the current candle is above the upper Ballinger band curve so we have a short signal and we return one in any other case we return Z I'm applying this function the total signal to all the data or the slice of the data that we have the 30,000 rows that we have just sliced right here just the last or the most recent 30,000 uh rows it's almost 3 months of
(08:17) data and uh we're just saving all the signals the total signal in a new column called total signal this is going to make it faster for us in the back test so this is how our data frame looks like we have all what we had before and on top of it let me go just to the right no so at the end we should have the um total signal column that we can see here so we have a signal equal one which means it's a short signal signal equal to it's a long signal and so on so we can continue so now to visualize our signals it's good to visualize things on
(08:56) the graph we can use this cell to create point points above and below the candles wherever we have a signal and we can plot the um data frame and we can plot the candles like a normal chart adding the Ballinger band lower and upper bands the EMA fast the EMA slow and also the positions of the uh signal the short and long signals that we have just computed and this is what we have so it's just to verify and validate visually that things are working as intended that we haven't made any errors in the code and so we
(09:33) have our Ballinger bands the two moving averages and those signals so these are short signals because they are above the candles and this one is an excellent one for example we are in a downtrend look at the price it went up and it reached here it crossed the upper Binger band and so it triggers um short signal anyway it's working sometimes you have these consecutive signals but these are just one one signal actually we're taking the first one because as soon as we see one signal occurrence we're opening a trade and we open one trade at
(10:07) a time so these are discarded unless if we were stopped before that so we might enter the market again and now we can proceed with the back test I'm using the back testing uh Pi the size of a lot is 3,000 here the stop-loss coefficient is 1.1 so the stop loss distance is going to be 1.
(10:28) 1 time the ATR and the takeprofit stop-loss ratio is 1.5 discard the RSI as I've mentioned we're not using it for this uh video so uh we're initializing our variables and whatever we want here and now we can Define the stoploss uh distance so it's SL ATR it's equal to the coefficient times the current ATR the most recent ATR value and the take profit stop-loss ratio is equal to uh this value and we're going to use it right here to define the stop loss and take profits so this is how it works if the signal is equal to two so it's a long position
(11:07) it's a long position signal and we don't have any open trades we're going to define the stop-loss value the take profit value as well and we're going to open a buy position using the stop- loss take profit and the size of the U of the trade again for the the other condition in the opposite direction if we have a short signal and we don't have any opened trades currently we will be defining the stop- loss the take profit and using these to open a sell position we're going to Define our back testing conditions so
(11:41) we're passing the data frame my strategy class what we see here and initial cash amount which is 250 it's in dollars let's say and a margin of 1 over3 so it's a leverage 1 to30 and now to the results we can see that we have a return percentage of 25% with the parameters that I've just used against a Buy and Hold return of minus 7% almost so the maximum drow down minus 17% that's a lot in my opinion I wouldn't trade anything below minus 10% as a maximum drow down but the average drow down is okay it's minus 1.2% the
(12:18) number of Trades is 1,671 and the win rate is 4 to 44% almost and um yeah basically that's it in a nutshell it's a winning strategy I could show you the uh plotting so let's plot the equity curve as we can see it's a steadily increasing Equity with few drow down periods so this one is a large one remember that this is a 3mon uh period overall so this I would assume this is like couple of weeks of drow down period so that should be okay two to three weeks of drow Downs the rests are the rest of the drow down areas
(12:52) right here are relatively short but overall it's kind of increasing so it holds a potential I know you want to add commissions and so on it might eat from the uh the profitability of the strategy but at least the indicators and the way of thinking uh the way we combine the Binger bands with the moving averages and the Simplicity of the system is what's intriguing for me so it's very simple and it performs very well now could we optimize it further to make it really efficient and maybe deploy it live on a paper account why not just let
(13:25) me know in the comments section if you would like me to try it live forward Tes it live on a paper account we can do this for a future video and that's all I had to tell you for today I hope you found this video helpful if so please support by liking or just dropping a quick comment share your ideas let me know what you think about this until our next one trade safe and see you next time

## summary
- The video presents a simple scalping strategy for trading, utilizing Python for backtesting, with a focus on increasing equity through the use of moving averages and Bollinger Bands.
The strategy applies a 5-minute time frame, using fast and slow exponential moving averages (EMAs) to determine market trends, and trades are entered when prices cross the Bollinger Band extremes.
The stop-loss and take-profit levels are dynamically calculated using the Average True Range (ATR), with parameters like stop-loss coefficient and take-profit ratio being customizable.
The Python code for the backtest is provided for download, allowing users to test and optimize the strategy, particularly the trade management components like stop-loss and take-profit values.
The backtest results show a 25% return with a win rate of around 44%, with steady equity growth and manageable drawdowns, suggesting the potential of the strategy for further optimization and live testing.

## EMA와 볼린저 밴드를 이용한 평균 회귀 전략

### 전략 로직

#### 매수 신호 (TotalSignal = 2)
1. EMA 상승 추세 (단기 EMA > 장기 EMA)일 때
2. 가격이 일시적으로 하락하여 볼린저 하단에 도달
3. → 상승 추세에서의 일시적 조정을 매수 기회로 활용

#### 매도 신호 (TotalSignal = 1)
1. EMA 하락 추세 (단기 EMA < 장기 EMA)일 때
2. 가격이 일시적으로 상승하여 볼린저 상단에 도달
3. → 하락 추세에서의 일시적 반등을 매도 기회로 활용

### 사용된 지표
- EMA (지수이동평균): 주추세 판단
- 볼린저 밴드 (15기간, 1.5표준편차): 단기적 과매수/과매도 상황 포착

### 전략 특징
- 평균 회귀(Mean Reversion) 전략
- EMA로 주추세 방향 확인
- 볼린저 밴드로 단기적 가격 이탈 포착
- 추세 방향으로의 회귀를 예상하여 매매 실행

## EMA Signal 함수 해석
```python
def ema_signal(df, current_candle, backcandles):
    # 현재 캔들부터 과거 backcandles 개수만큼의 데이터를 분석
    df_slice = df.reset_index().copy()
    start = max(0, current_candle - backcandles)
    end = current_candle
    relevant_rows = df_slice.iloc[start:end]

    # EMA 크로스오버 조건 확인
    if all(relevant_rows["EMA_fast"] < relevant_rows["EMA_slow"]):      # 단기 EMA가 장기 EMA보다 모두 아래에 있을 때
        return 1    # 상승 신호
    elif all(relevant_rows["EMA_fast"] > relevant_rows["EMA_slow"]):    # 단기 EMA가 장기 EMA보다 모두 위에 있을 때
        return 2    # 하락 신호
    else:
        return 0    # 중립 신호
```

### 기능 분석
이 함수는 EMA(지수이동평균) 크로스오버 전략을 구현한 것으로 보입니다.
주요 기능:
- 단기 EMA(EMA_fast)와 장기 EMA(EMA_slow)의 위치 관계를 비교
- 지정된 기간(backcandles) 동안의 패턴을 확인
- 세 가지 신호를 반환 (0, 1, 2)

### 신호 의미
- 1 (상승 신호): 단기 EMA가 장기 EMA보다 지속적으로 아래에 있는 상태
- 2 (하락 신호): 단기 EMA가 장기 EMA보다 지속적으로 위에 있는 상태
- 0 (중립 신호): EMA 크로스오버가 발생하거나 일관된 패턴이 없는 상태

### backcandles 매개변수
- 이 매개변수는 과거 몇 개의 캔들을 사용하여 EMA 크로스오버를 확인할지를 결정합니다.
- 예를 들어, backcandles가 6이면 현재 캔들에서 과거 6개의 캔들을 사용하여 EMA 크로스오버를 확인합니다.

#### [예시]
- backcandles=7일 경우:

현재 캔들: 10번째
분석 구간: 3~10번째 캔들 (7개 구간)

[캔들3] EMA_fast < EMA_slow
[캔들4] EMA_fast < EMA_slow
[캔들5] EMA_fast < EMA_slow
[캔들6] EMA_fast < EMA_slow
[캔들7] EMA_fast < EMA_slow
[캔들8] EMA_fast < EMA_slow
[캔들9] EMA_fast < EMA_slow

- 위와 같이 7개 캔들 모두에서 EMA_fast가 EMA_slow보다 작으면 → 1 반환
- 7개 캔들 모두에서 EMA_fast가 EMA_slow보다 크면 → 2 반환
- 그 외의 경우(한 번이라도 크로스가 발생한 경우) → 0 반환


## TotalSignal 함수 해석

```python
def total_signal(df, current_candle, backcandles):
    # EMA 하락 추세일 때 (단기 < 장기)
    # 가격이 볼린저 상단에 도달하면 → 매도 (과매수 상태로 판단)
    if (ema_signal(df, current_candle, backcandles)==1 and 
        df.Close[current_candle]>=df['BBU_15_1.5'][current_candle]):
            return 1    # 매도 신호
    
    # EMA 상승 추세일 때 (단기 > 장기)
    # 가격이 볼린저 하단에 도달하면 → 매수 (과매도 상태로 판단)
    if (ema_signal(df, current_candle, backcandles)==2 and 
        df.Close[current_candle]<=df['BBL_15_1.5'][current_candle]):
            return 2    # 매수 신호
```
### 매수 조건 (반환값 2)
- EMA가 상승 추세 (단기 EMA > 장기 EMA)
- 현재 가격이 일시적으로 하락하여 볼린저 하단에 도달
→ 상승 추세에서의 일시적 조정을 매수 기회로 활용
### 매도 조건 (반환값 1)
- EMA가 하락 추세 (단기 EMA < 장기 EMA)
- 현재 가격이 일시적으로 상승하여 볼린저 상단에 도달
→ 하락 추세에서의 일시적 반등을 매도 기회로 활용
### 이는 전형적인 평균 회귀(Mean Reversion) 전략으로:
- 주추세는 EMA로 판단
- 볼린저 밴드로 단기적인 과매수/과매도 상황 포착
추세 방향으로의 회귀를 예상하여 매매

## MyStrat 클래스 분석


```python
class MyStrat(Strategy):
    # 클래스 변수 (파라미터)
    mysize = 3000           # 거래 수량
    slcoef = 1.1           # 손절 계수 (ATR 곱셈 계수)
    TPSLRatio = 1.5        # 익절/손절 비율
    rsi_length = 16        # RSI 기간 (현재 미사용)
    
    def init(self):
        super().init()
        self.signal1 = self.I(SIGNAL)    # 매매 신호 초기화
    
    def next(self):
        super().next()
        # 손절/익절 거리 계산
        slatr = self.slcoef * self.data.ATR[-1]      # 손절 거리 = ATR * 계수
        TPSLRatio = self.TPSLRatio                    # 익절/손절 비율

        # 매수 신호 (signal1 == 2)일 때
        if self.signal1==2 and len(self.trades)==0:
            sl1 = self.data.Close[-1] - slatr         # 손절가 = 현재가 - (ATR * 계수)
            tp1 = self.data.Close[-1] + slatr*TPSLRatio  # 익절가 = 현재가 + (ATR * 계수 * 비율)
            self.buy(sl=sl1, tp=tp1, size=self.mysize)   # 매수 주문
        
        # 매도 신호 (signal1 == 1)일 때
        elif self.signal1==1 and len(self.trades)==0:         
            sl1 = self.data.Close[-1] + slatr         # 손절가 = 현재가 + (ATR * 계수)
            tp1 = self.data.Close[-1] - slatr*TPSLRatio  # 익절가 = 현재가 - (ATR * 계수 * 비율)
            self.sell(sl=sl1, tp=tp1, size=self.mysize)  # 매도 주문

bt = Backtest(df, MyStrat, cash=250, margin=1/30)


```
### 포지션 크기 관리
- mysize = 3000: 고정된 거래 수량 사용
- 리스크 관리를 위해 포지션 크기를 동적으로 조절하는 것이 좋을 수 있음

### 손절/익절 관리
- ATR 기반의 동적 손절/익절 설정
- slcoef = 1.1: ATR의 1.1배를 손절 거리로 사용
- TPSLRatio = 1.5: 익절 거리는 손절 거리의 1.5배

### 매매 조건
- 한 번에 하나의 포지션만 보유 (len(self.trades)==0)
- signal1이 2일 때 매수, 1일 때 매도
- RSI 기반 청산 로직은 주석 처리됨


## 백테스트 결과

Start                                     0.0
End                                   29998.0
Duration                              29998.0
Exposure Time [%]                    32.59442
Equity Final [$]                   564.111374
Equity Peak [$]                    568.743962
Return [%]                          125.64455
Buy & Hold Return [%]               -6.960914
Return (Ann.) [%]                         0.0
Volatility (Ann.) [%]                     NaN
Sharpe Ratio                              NaN
Sortino Ratio                             NaN
Calmar Ratio                              0.0
Max. Drawdown [%]                  -16.861386
Avg. Drawdown [%]                   -1.204402
Max. Drawdown Duration                 3827.0
Avg. Drawdown Duration              143.12234
# Trades                               1671.0
Win Rate [%]                        43.985637
Best Trade [%]                        0.40522
Worst Trade [%]                     -0.252185
Avg. Trade [%]                       0.006138
Max. Trade Duration                     196.0
Avg. Trade Duration                  4.851586
Profit Factor                        1.189901
Expectancy [%]                       0.006173
SQN                                  2.998267
_strategy                             MyStrat
_equity_curve                        Equit...
_trades                         Size  Entr...
dtype: object

### 수익성 지표
- 최종 수익
- 초기자본: $250
- 최종자본: $564.11
- 총 수익률: 125.64%
- 최고 자본: $568.74
- Buy & Hold 대비 우수 (Buy & Hold: -6.96%)

### 거래 통계
- 총 거래 횟수: 1,671회
- 승률: 43.99%
- 최고 수익 거래: +0.41%
- 최악 손실 거래: -0.25%
- 평균 거래 수익: +0.0061%
- 수익 팩터: 1.19 (1 이상이면 수익성 있음)

### 리스크 지표
- 드로다운 분석
- 최대 드로다운: -16.86%
- 평균 드로다운: -1.20%
- 최대 드로다운 기간: 3,827 캔들
- 평균 드로다운 기간: 143.12 캔들

### 거래 시간
- 평균 거래 유지 시간: 4.85 캔들
- 최대 거래 유지 시간: 196 캔들
- 시장 노출도: 32.59% (전체 시간의 약 1/3만 포지션 보유)

### 시스템 품질 지표
- SQN(System Quality Number): 2.99
- 2.0~3.0: 평균 이상의 시스템
- 안정적인 거래 시스템으로 평가 가능

### 개선 필요 사항
- 승률 개선
  - 현재 승률 44%는 다소 낮음
  - 진입/청산 조건 최적화 필요
- 드로다운 관리
  - 최대 드로다운 16.86%는 다소 높음
  - 리스크 관리 강화 필요
- 거래 효율성
  - 평균 수익이 0.0061%로 매우 낮음
  - 거래 비용 고려시 수익성 저하 가능성

### 종합 평가
- 전반적으로 안정적인 수익 창출
- 리스크 대비 적절한 수익 실현
- 시장 방향성과 무관한 알파 창출
- 단, 거래 비용과 슬리피지 고려시 실제 수익은 감소 가능성 있음


## TE 분석

```python
trades = stats._trades
#print(trades)

trades_df = pd.DataFrame(trades)
display(trades_df.head(10))


# 수익/손실 거래 분리
profit_trades = trades_df[trades_df['PnL'] > 0]
loss_trades = trades_df[trades_df['PnL'] < 0]

# 계산에 필요한 값들
win_rate = len(profit_trades) / len(trades_df)
avg_profit = profit_trades['PnL'].mean()
avg_loss = abs(loss_trades['PnL'].mean())  # 손실은 음수이므로 절대값 처리

# Trading Edge 계산
TE = (win_rate * avg_profit) - ((1 - win_rate) * avg_loss)

# 필요 RR비율 계산
required_rr = (1 - win_rate) / win_rate
actual_rr = avg_profit / avg_loss

print("=== Trading Edge 분석 ===")
print(f"승률: {win_rate:.2%}")
print(f"평균 수익: ${avg_profit:.2f}")
print(f"평균 손실: ${avg_loss:.2f}")
print(f"Trading Edge: ${TE:.2f}")
print(f"필요 RR비율: {required_rr:.2f}")
print(f"실제 RR비율: {actual_rr:.2f}")
print(f"RR비율 평가: {'충족' if actual_rr > required_rr else '미달'}")
```

=== Trading Edge 분석 ===
승률: 44.64%
평균 수익: $2.94
평균 손실: $1.89
Trading Edge: $0.27
필요 RR비율: 1.24
실제 RR비율: 1.56
RR비율 평가: 충족

=== Trading Edge 분석 ===
승률: 36.83%
평균 수익: $3.88
평균 손실: $2.04
Trading Edge: $0.14
필요 RR비율: 1.72
실제 RR비율: 1.90
RR비율 평가: 충족


2024.11.14 12:38:28.015	2024.11.13 23:58:59   === Trading Edge 분석 ===
2024.11.14 12:38:28.015	2024.11.13 23:58:59   총 거래 수: 74
2024.11.14 12:38:28.015	2024.11.13 23:58:59   승률: 12.16%
2024.11.14 12:38:28.015	2024.11.13 23:58:59   평균 수익: $244.03
2024.11.14 12:38:28.015	2024.11.13 23:58:59   평균 손실: $71.17
2024.11.14 12:38:28.015	2024.11.13 23:58:59   Trading Edge: $-32.83
2024.11.14 12:38:28.015	2024.11.13 23:58:59   필요 RR비율: 7.22
2024.11.14 12:38:28.015	2024.11.13 23:58:59   실제 RR비율: 3.43
2024.11.14 12:38:28.015	2024.11.13 23:58:59   RR비율 평가: 미달
