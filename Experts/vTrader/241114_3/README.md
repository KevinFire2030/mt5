
# Python Backtest: Profitable Scalping Strategy with VWAP, Bollinger Bands and RSI Indicators

## Transcript

(258) Python Backtest: Profitable Scalping Strategy with VWAP, Bollinger Bands and RSI Indicators - YouTube
https://www.youtube.com/watch?v=RbQaARxEW9o

Transcript:
(00:01) hi everyone today we have a winner strategy using v-wab Bollinger Bands and the RSI for confirmation I backtested this before sharing it in this video it's the first scalping strategy that we are showing on this channel because usually sculpting is very challenging for algorithms since the data is usually noisy on Lower time frames if you are new to this channel the python code is downloadable from the link in the description and don't forget to support and subscribe maybe drop a comment if you have any ideas to be shared the
(00:30) total return after three years of back testing is around 300 percent and the reason I liked this strategy is the average trade duration which is around 51 minutes here so you can see this on this line so this is the fastest trade closing strategy on this channel so far and this means less overnight fees and less stress because you can immediately see the results of your executed trades and someone from the comments section asked for the sharp ratio and it's included also in this strategy it's around one point 0.65 this value can
(01:03) change with any parameters modifications in our python code so when you download the python code and you execute it you check the back testing this sharp ratio might be changing just keep an eye on this so you can maximize this value for this strategy I'm using the five minutes time frame The View app curve I'm looking for 15 candles for example to be above or below the view up curve which is the Blue Line we can see here and it's mainly used for Trend detection so if we have 15 candles above the V web curve we are in an uptrend if we are
(01:38) below the view app curve I'm looking for selling positions because I consider we have downtrend then to take the entry positions for the trading we have Bollinger Bands I'm using the length 14 with a standard deviation of two so if we are in an uptrend above the P web curve we are looking for buying positions and whenever I have a candle closing below the lower Bollinger curve this is where I have my entry signal for a buying position if we are looking for a downtrend so we are below the v-wap curve and we're looking for a selling
(02:12) position or a short position I'm waiting for a candle to close above the upper Bollinger band and this will be my selling signal finally to confirm the signal I'm using the RSI if I have an RSI below 45 then I confirm a Buy Signal if I have an RSI above 55 I'm confirming a short position or a selling signal for the take profit and the stop loss I'm using the ATR the average true range looking back for example for the last seven candles taking the ATR value for these seven or eight candles I'm multiplying this by a certain
(02:45) coefficient and this will be my stop loss distance the take profit is equal to the stop loss distance times the take profit stop loss ratio also known as the risk reward ratio so as you may have noticed there's a lot of parameters to be tuned the length of the ATR the coefficient the ratio the take profit stop loss ratio among other parameters such as the indicators parameters the RSI length so all of these are parameters that we can be modifying in the python code and checking how they could affect our strategy over the three
(03:20) years data so again you can download the code from the link in the description and you can experiment on your own to see how these parameters can affect your trading strategy okay now we can write all of this in Python modify the parameters and see how our back testing is affected this is our jupyter notebook file we are importing pandas SPD and I'm loading my data frame loading my data it's a CSV file the Euro US dollar candlesticks five minutes asking price between 2019 and 2022 so this is three years worth of data then we need to do a
(03:55) bit of reformatting for the time the GMT time column which is loaded with a data so this is the data frame before our cleaning the GMT time column contains the date but then the time as well and then we have 0.000 which are the fractions of the second so we don't need this for the moment and we can clean this to make a simpler format of the date so I'm removing the point zero zero zero at this line using this line I'm adjusting the format of the time using this particular line here and then I'm setting the date as index so I will no
(04:32) longer have the integer index here I will have this GMT time corrected as an index also I'm discarding the rows where the high value of the candle is equal to the low value which means that we didn't have any movements of the price or of the market at these particular moments this can happen on weekends they can happen on days off or any other moments where the market was off or we simply lost the contact with our data servers so now I have my data frame is cleaned the length of my data is two hundred thousand twenty four thousand and nine
(05:07) hundred and eighty nine so this is how many rows I have in my data frame then I'm adding the technical indicators so at this point we are adding a column called v-wap which contains the view app I'm providing the high low close and the volume of these rows and the view app is computed automatically using this particular Library I'm adding the RSI because I'm going to use it I'm using length 16 here you might want to change this this is one of the parameters you can experiment on and the Bollinger Bands I'm using length 14 and standard
(05:41) deviation 2.0 there is no particular reason for these values this is trial and error you might want to change these and experiment on your own the results that I'm going to show you are definitely not the best results for this strategy you can definitely improve these by trying or adding probably the other technical indicators if you wish so then we need to compute the view app signal something I call the view app signal and this is uh Computing the number of candles that are above completely above or completely below the
(06:16) view app curve for example if we have 15 back candles above the v-wap curve I would consider I have an uptrend and my view app signal will be equal to 2 and in the opposite case if I have 15 back candles that are below the view up curve so I consider that I'm in a downtrend and this will be my v-wap signal so anyway this v-wap signal is stored as a new column in my data frame that I'm calling DF V web signal then we can compute the total signal and this is done inside of this function I'm calling total signal so the conditions are the
(06:52) following if I have a v-wap signal that is equal to 2 meaning I'm looking for an uptrend or buying or long positions and at this same time I have a candle that closes below the lower Bollinger band curve and at the same time the RSI is below 45 in this case I have a buying signal function is going to return to if in the opposite case I have a view app signal equal to one I'm looking to short the market at the same time I have to have a closing candle above the upper Bollinger band and the current candles RSI is above 55 then I'm going to return
(07:30) 1 which means I have a short signal if none of these conditions is true then I'm going to return 0 which means I don't have a particular signal for the current candle I'm looking at and so we can compute the total signal and store it as a new column in our data frame we're going to call it DF total signal just to make sure that my conditions are working properly I'm going to count the number of total signals we got in our data frame and we have 2781 so so theoretically we should be having around 2781 trades in our back testing so if
(08:09) you have been watching this channel you know that we always try to visualize our signals which makes things easier I'm going to create points above or below the candles whenever I have selling or buying signals and I'm going to store these positions of the points in a new column in the data frame called Point position break for example and this cell here we'll be plotting the candles it's to visualize the candles so I'm providing the Open high low and close prices and I'm providing as well the v-wap line we can also provide the Bollinger Bands we
(08:47) also need to add the signals meaning the points that we just computed where we had the total signal valid and these are the signals as we can see here we have a buying signal or a long signal at this point this purple point which is below the candle and that's because we had 15 candles above the view app curve the blue curve and at the same time we have this candle this red candle closing below the lower Bollinger band curve so this is true according to the conditions we also have the probably the RSI above
(09:19) the 55 for example so and we have this buying position this long trigger here as a signal it was a false signal because afterwards we can see that the price drop down but this one here is a good signal because we have 15 can those above the viewab curve so we are looking for a buying position and one of these candles closed below the lower Bollinger band curve we can see that we are good to go as a buying position so anyway what I can say at this point is that the algorithm is working as intended so this these are the conditions that we
(09:50) provided and it's working well but we are missing on some of these nicer trades as well so we could have been detecting something like this and the reason we don't have a signal here is that because these two candles or this particular candle the red one it's true it closed below the lower Bollinger band curve but at the same time it crossed the v-wap curve and one of the conditions of our algorithm is not valid anymore so we needed the last 15 candles including the current candle to be above the v-wap curve so we are confirming an
(10:25) uptrend so maybe this is one of the conditions we can maybe improve a bit something that I might work on for the next videos if you are interested in improving this particular strategy please drop a comment it's really of a big support when I see you sharing ideas I always get most of my ideas out from the comments section so now we can move on to the back testing part for this we are going to need the ATR the average true range to choose our stop loss and take profit values and this is where I'm Computing the ATR I'm adding it to my
(10:59) new data frame that I'm using this is simply a copy of a slice of my initial data frame just sometimes the um the whole data frame is kind of large so I don't want to wait and test on all the data it takes some time it's easier to take a small slice do your experiment change your values and then when you are happy with these parameters you can run on the whole set of data then I'm using the backtesting dot Pi Library package or my back testing and here I'm going to use the stop loss at R distance it's equal to
(11:35) 1.2 times the current ATR value so this is the coefficient I was talking about when I presented the strategy and the take profit stop loss ratio is set to 1.5 in this particular example I'm adding also a condition it doesn't make much of a difference in this case for this particular strategy here with these parameters it's that if we have a long position if the current trade is long and the RSI is crossing the value of 90.
(12:06) I'm closing the the trade even though I didn't reach the take profit value yet the same thing in the opposite direction if I have a short position and we are going below the RSI is going below 10 I will close the position even though I haven't reached my take profit value yet if I have a buying signal and we are allowing only one trade at a time so if the length of the current trades is equal to zero Computing the stop loss as we have have explained I'm Computing the take profit using the take profit stop loss ratio and I'm opening it by
(12:38) position the opposite case Works similarly so when we have a signal equal one a total signal that is one so it's a selling position we don't have any open trades I compute the stop loss that take profit and I open a selling position and if I start with 100 as cash and I use a margin of 1 over 10 we can run a back test and we can check the results I'm getting 197 percent in return and an equity peak of three hundred dollars three hundred and thirteen dollars but the equity final is around 300 as well it's 297. remember that we started with
(13:15) one hundred dollars and the sharp ratio is 1.65 as we have mentioned at the beginning the reason I like this strategy is this particular average trade duration value here it's 51 minutes so most of our trades are going to be closed within an hour so you you don't have to wait much the win rate is not very high it's 45 percent but remember that we're using a take profit stop loss ratio of 1.
(13:43) 5 and if we look at the equity we can see that we have a constantly increasing Capital we have a small drawdown period right here but overall the equity for sculpting is really good it might be also interesting to check parts of the history for example if I go for the first year I'm going to cut my data for the first 75 000 rows we have a sharp ratio of 2.
(14:08) 12 and we have a return of 53 percent per year so it's an annual return average annual return of 53 percent a total return of 72 percent and then average trade duration of 47 minutes okay so this was it for this video please let me know if you want me to expand on the strategy and try to improve it adding more custom indicators and so on I would like to investigate the V web more so stay tuned for our next video Until our next one trade safe and see you next time


## Summary

VWAP, 볼린저 밴드, RSI를 활용한 스캘핑 전략의 주요 내용을 요약해드리겠습니다:

5분봉 기준으로 VWAP, 볼린저 밴드, RSI 지표를 결합한 전략으로, 3년간의 백테스팅 결과 약 300%의 수익률과 1.65의 샤프 지수를 기록
평균 거래 시간이 51분으로, 상대적으로 빠른 스캘핑 전략이며 이는 오버나잇 수수료를 최소화하고 신속한 ��과 확인이 가능함
진입 조건:

매수 포지션: VWAP 위로 15개 캔들 유지(상승추세), 가격이 하단 볼린저 밴드 아래로 종가 형성, RSI 45 미만
매도 포지션: VWAP 아래로 15개 캔들 유지(하락추세), 가격이 상단 볼린저 밴드 위로 종가 형성, RSI 55 초과


손절과 익절은 ATR(평균 실제 범위)을 기준으로 계산:

손절 = 1.2 × ATR
익절 = 손절 × 1.5 (리스크 대비 리워드 비율)


주요 성과 지표:

승률: 45%
첫 해 성과: 연간 수익률 53%, 샤프 지수 2.12
전략은 최소한의 손실 구간으로 지속적인 자본 증가를 보여줌


## 전략 분석

### 전략 개요
이 문서는 VWAP, 볼린저 밴드, RSI를 결합한 파이썬 기반 스캘핑 전략을 설명하고 있습니다.

### 주요 특징
1. **시간프레임과 성과**
- 5분봉 차트 사용
- 3년 백테스팅 결과 약 300% 수익률 
- 샤프 비율 1.65
- 평균 거래 시간 51분

2. **진입 조건**
- **매수 조건**:
  - VWAP 위로 15개 연속 캔들
  - 가격이 하단 볼린저 밴드 아래로 종가 형성
  - RSI 45 미만

- **매도 조건**:
  - VWAP 아래로 15개 연속 캔들
  - 가격이 상단 볼린저 밴드 위로 종가 형성
  - RSI 55 초과

3. **손익 관리**
- ATR 기반 손절/익절 설정
- 손절폭 = ATR × 1.2
- 익절폭 = 손절폭 × 1.5

### 기술적 구현
- 파이썬으로 구현
- pandas 라이브러리 사용
- backtesting.py 패키지 활용
- 데이터 전처리 및 지표 계산 포함

### 성과 지표
- 승률: 45%
- 첫 해 성과:
  - 연간 수익률 53%
  - 샤프 비율 2.12
- 안정적인 자본 증가 곡선

### 장점
1. 빠른 거래 회전율로 오버나잇 수수료 최소화
2. 신속한 결과 확인 가능
3. 스캘핑 전략임에도 안정적인 수익 곡선

### 한계점
- 일부 좋은 거래 기회를 놓칠 수 있음
- VWAP 조건이 다소 엄격하여 진입 기회가 제한될 수 있음
- 파라미터 최적화 여지가 있음

이 전략은 스캘핑 전략임에도 불구하고 안정적인 성과를 보여주는 것이 특징이며, 다양한 파라미터 조정을 통해 더 나은 결과를 얻을 수 있는 가능성이 있습니다.


## VWAP (Volume Weighted Average Price) 분석

### VWAP의 기본 개념
- VWAP는 거래량을 고려한 평균 가격을 나타내는 지표입니다
- 각 가격대에서 발생한 거래량을 가중치로 사용하여 평균 가격을 계산합니다
- 일반적으로 하루 단위로 계산되며, 장 시작부터 누적됩니다

### 계산 방법

```python
VWAP = Σ(가격 × 거래량) / Σ(거래량)
```

### VWAP의 주요 특징
1. **기관투자자들의 벤치마크**
- 기관투자자들이 매매 성과를 평가하는 기준으로 사용
- VWAP보다 낮은 가격에 매수하고 높은 가격에 매도하는 것이 목표

2. **가격 레벨 판단**
- VWAP 위의 가격: 상대적으로 고평가 구간
- VWAP 아래의 가격: 상대적으로 저평가 구간

3. **트렌드 확인**
- 가격이 VWAP 위에서 유지: 상승 트렌드
- 가격이 VWAP 아래에서 유지: 하락 트렌드

### 트레이딩에서의 활용
1. **진입 시점 결정**
- VWAP 돌파 시 트렌드 전환 신호로 활용
- 가격이 VWAP에서 반등할 때 매매 기회 포착

2. **리스크 관리**
- VWAP를 스탑로스 레벨로 활용 가능
- 포지션 진입 후 VWAP 반대편 도달 시 청산 고려

3. **거래량 분석**
- VWAP 근처에서 거래량 증가는 중요한 가격 레벨임을 시사
- 큰 거래량과 함께 VWAP 돌파 시 강한 신호로 해석

### 장점
- 거래량을 반영하여 더 현실적인 가격 수준 제시
- 기관투자자들의 관심 가격대 파악 가능
- 객관적인 매매 기준점 제공

### 단점
- 일중(Intraday) 지표로 장기 분석에는 제한적
- 거래량이 적은 종목에서는 신뢰성 ���어짐
- 과거 데이터에 기반하므로 선행성 부족

### 스캘핑에서의 VWAP 활용
- 단기 가격 움직임의 방향성 판단
- 빠른 진입/청산 지점 결정
- 시장의 전반적인 세력 방향 확인

이러한 VWAP의 특성들이 스캘핑 전략에서 효과적으로 활용될 수 있으며, 다른 지표들과 결합하여 더욱 신뢰성 있는 매매 신호를 만들어낼 수 있습니다.


## VWAP 신호 생성 코드 분석

### 코드 구조

```python
VWAPsignal = [0]*len(df)
backcandles = 15

for row in range(backcandles, len(df)):
    upt = 1
    dnt = 1
    for i in range(row-backcandles, row+1):
        if max(df.Open[i], df.Close[i])>=df.VWAP[i]:
            dnt=0
        if min(df.Open[i], df.Close[i])<=df.VWAP[i]:
            upt=0
    if upt==1 and dnt==1:
        VWAPsignal[row]=3
    elif upt==1:
        VWAPsignal[row]=2
    elif dnt==1:
        VWAPsignal[row]=1

df['VWAPSignal'] = VWAPsignal
```

### 신호 값의 의미
- **0**: 기본값 (특별한 신호 없음)
- **1**: 하락 트렌드 (15개 캔들이 모두 VWAP 아래)
- **2**: 상승 트렌드 (15개 캔들이 모두 VWAP 위)
- **3**: 중립/교차 (15개 캔들이 VWAP에 걸쳐있음)

### 주요 특징
1. **트렌드 강도 측정**
   - 15개 연속 캔들의 위치로 트렌드 강도 판단
   - 더 긴 기간의 트렌드 방향 확인 가능

2. **엄격한 조건**
   - 모든 캔들이 VWAP 위/아래에 있어야 신호 발생
   - 이는 강한 트렌드 확인을 위한 것

3. **캔들 위치 판단**
   - 캔들의 시가/종가 중 최대/최소값 사용
   - 캔들의 전체 범위가 아닌 실체만 고려

### 장단점
**장점:**
- 트렌드의 강도를 명확하게 측정
- 허위 신호 최소화
- 구현이 단순하고 이해하기 쉬움

**단점:**
- 조건이 너무 엄격하여 많은 기회 놓칠 수 있음
- 지연된 신호 발생 가능
- 급격한 시장 변화에 대응 늦을 수 있음

### 개선 가능한 부분
1. backcandles 수 조정으로 민감도 조절
2. 캔들의 실체뿐만 아니라 꼬리까지 고려
3. 신호 조건을 좀 더 유연하게 수정
4. 거래량 가중치 추가 고려

이 코드는 README.md에서 설명한 전략의 핵심 부분을 구현한 것으로, VWAP를 기준으로 한 트렌드 판단에 중요한 역할을 합니다.


## 최종 매매 신호 생성 코드 분석

### 코드 구조
```python
def TotalSignal(l):
    # 매수 신호 조건
    if (df.VWAPSignal[l]==2                     # VWAP 상승 트렌드
        and df.Close[l]<=df['BBL_14_2.0'][l]    # 종가가 볼린저 밴드 하단 이하
        and df.RSI[l]<45):                      # RSI가 45 미만
            return 2
    
    # 매도 신호 조건
    if (df.VWAPSignal[l]==1                     # VWAP 하락 트렌드
        and df.Close[l]>=df['BBU_14_2.0'][l]    # 종가가 볼린저 밴드 상단 이상
        and df.RSI[l]>55):                      # RSI가 55 초과
            return 1
            
    return 0  # 신호 없음
```

### 신호 생성 로직
1. **매수 신호 (return 2)**
   - VWAP 기준 상승 트렌드
   - 가격이 볼린저 밴드 하단 터치/돌파
   - RSI 과매도 구간(45 미만)

2. **매도 신호 (return 1)**
   - VWAP 기준 하락 트렌드
   - 가격이 볼린저 밴드 상단 터치/돌파
   - RSI 과매수 구간(55 초과)

3. **중립 (return 0)**
   - 위 조건들을 만족하지 않는 경우

### 전략적 의미
1. **반전 매매 전략**
   - 추세 방향의 극단치를 이용한 반전 매매
   - 과매수/과매도 구간을 활용한 진입

2. **다중 지표 확인**
   - VWAP: 전체적인 추세 방향
   - 볼린저 밴드: 가격 변동성 범위
   - RSI: 모멘텀/과매수/과매도 확인

3. **리스크 관리**
   - 여러 지표의 조��으로 허위 신호 최소화
   - 명확한 진입 조건으로 객관적 매매 가능


## 백테스팅 전략 분석

### 전략 클래스 구조
```python
class MyStrat(Strategy):
    initsize = 0.99        # 초기 거래 크기
    mysize = initsize
```

### 주요 매매 로직
1. **포지션 진입 조건**
   - 매수 진입: TotalSignal이 2일 때 (VWAP 상승 + 볼린저 하단 + RSI 과매도)
   - 매도 진입: TotalSignal이 1일 때 (VWAP 하락 + 볼린저 상단 + RSI 과매수)
   - 동시에 열린 포지션이 없어야 함 (len(self.trades)==0)

2. **손익 관리**
   - 손절폭(Stop Loss): ATR × 1.2
   - 익절폭(Take Profit): 손절폭 × 1.5
   - 리스크:리워드 비율 = 1:1.5

3. **추가 청산 조건**
   - 롱 포지션: RSI가 90 이상일 때 청산
   - 숏 포지션: RSI가 10 이하일 때 청산

### 자금 관리
- 초기자본: $100
- 레버리지: 10배 (margin=1/10)
- 거래 크기: 계좌의 99% (initsize = 0.99)
- 수수료: 0%

### 전략의 특징
1. **보수적인 리스크 관리**
   - ATR 기반의 동적 손절/익절 설정
   - RSI 극단치에서의 자동 청산
   - 단일 포지션 운영

2. **멀티 타임프레임 접근**
   - VWAP: 중기 트렌드 확인 (15캔들)
   - 볼린저 밴드: 단기 가격 변동성
   - RSI: 초단기 모멘텀

3. **반전 매매 특성**
   - 추세 방향으로의 과도한 움직임을 역이용
   - 기술적 지표의 극단치 활용

### 장점
1. 명확한 진입/청산 규칙
2. 체계적인 리스크 관리
3. 과매수/과매도 구간에서의 추가 보호 장치
4. 동적 손익비 설정으로 시장 상황 반영

### 단점
1. 단일 포지션 제한으로 수익 기회 제한
2. 극단적 추세 장에서 불리
3. RSI 기반 청산이 수익 제한 가능

### 최적화 가능 파라미터
1. ATR 승수 (현재 1.2)
2. 익절/손절 비율 (현재 1.5)
3. RSI 청산 레벨 (현재 90/10)
4. 거래 크기 비율 (현재 0.99)
5. VWAP 기간 (현재 15캔들)

이 전략은 안정적인 수익을 목표로 하는 보수적인 스캘핑 접근법을 보여주며, 리스크 관리에 중점을 둔 것이 특징입니다.

### 백테스팅 결과

End                       2020-09-30 04:25:00
Duration                    366 days 04:25:00
Exposure Time [%]                    6.694667
Equity Final [$]                   172.713956
Equity Peak [$]                    173.665736
Return [%]                          72.713956
Buy & Hold Return [%]                7.246403
Return (Ann.) [%]                   53.432392
Volatility (Ann.) [%]               25.126177
Sharpe Ratio                         2.126563
Sortino Ratio                        5.880902
Calmar Ratio                         5.285867
Max. Drawdown [%]                   -10.10854
Avg. Drawdown [%]                   -0.707265
Max. Drawdown Duration       53 days 00:40:00
Avg. Drawdown Duration        1 days 19:34:00
Trades                                  713
Win Rate [%]                        48.527349
Best Trade [%]                        0.42012
Worst Trade [%]                      -0.27659
Avg. Trade [%]                       0.007964
Max. Trade Duration           2 days 05:30:00
Avg. Trade Duration           0 days 00:47:00
Profit Factor                        1.346955
Expectancy [%]                       0.007989
SQN                                   2.84368
_strategy                             MyStrat
_equity_curve                             ...
_trades                        Size  Entry...
dtype: object