//+------------------------------------------------------------------+
//|                                         turtle_trading_v0.1.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "0.10"
#property description "터틀 트레이딩 전략 v0.1"

#include <Trade\Trade.mqh>

#define TIMER_INTERVAL 60  // 60초 (1분) 간격
#define EMA_FAST 5
#define EMA_MEDIUM 20
#define EMA_SLOW 40
#define ATR_PERIOD 14
#define MAX_RISK_PERCENT 20 // 최대 리스크 비율 (%)

input double RiskPercent = 1.0; // 거래당 리스크 비율 (%)

#define MAGIC_NUMBER 081009  // Magic 번호 정의 추가

class SymbolData
{
public:
    double emaFast;
    double emaMedium;
    double emaSlow;
    double atr;
    double position;
    double units;
};

// 심볼별 데이터를 저장할 맵
#include <Generic\HashMap.mqh>
CHashMap<string, SymbolData*> symbolDataMap;

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MAGIC_NUMBER);
    EventSetTimer(TIMER_INTERVAL);
    Print("터틀 트레이딩 EA가 시작되었습니다.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    // 메모리 해제
    string keys[];
    SymbolData* values[];
    symbolDataMap.CopyTo(keys, values);
    for(int i=0; i<ArraySize(keys); i++)
    {
        if(values[i] != NULL)
        {
            delete values[i];
        }
    }
    symbolDataMap.Clear();
    Print("터틀 트레이딩 EA가 종료되었습니다.");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    Print("--- OnTimer 함수 시 ---");
    for(int i=0; i<SymbolsTotal(true); i++)
    {
        string symbol = SymbolName(i, true);
        Print("처리 중인 심볼: ", symbol);
        CalculateIndicators(symbol);
        CheckForTrades(symbol);
    }
    Print("--- OnTimer 함수 종료 ---");
}

//+------------------------------------------------------------------+
//| Calculate indicators for a symbol                                |
//+------------------------------------------------------------------+
void CalculateIndicators(string symbol)
{
    Print("CalculateIndicators 시작: ", symbol);
    MqlRates rates[];
    if(CopyRates(symbol, PERIOD_M1, 0, ATR_PERIOD, rates) != ATR_PERIOD)
    {
        Print("데이터 복사 실패: ", symbol);
        return;
    }
    
    SymbolData* data;
    if(!symbolDataMap.ContainsKey(symbol))
    {
        Print("새 SymbolData 객체 생성: ", symbol);
        data = new SymbolData();
        symbolDataMap.Add(symbol, data);
    }
    else
    {
        symbolDataMap.TryGetValue(symbol, data);
    }
    
    data.emaFast = CalculateEMA(rates, EMA_FAST);
    data.emaMedium = CalculateEMA(rates, EMA_MEDIUM);
    data.emaSlow = CalculateEMA(rates, EMA_SLOW);
    data.atr = CalculateATR(rates, ATR_PERIOD);
    
    Print(symbol, " - EMA Fast: ", data.emaFast, ", Medium: ", data.emaMedium, ", Slow: ", data.emaSlow, ", ATR: ", data.atr);
    Print("CalculateIndicators 종료: ", symbol);
}

double CalculateEMA(const MqlRates &rates[], int period)
{
    double multiplier = 2.0 / (period + 1);
    double ema = rates[0].close;
    
    for(int i = 1; i < ArraySize(rates); i++)
    {
        ema = (rates[i].close - ema) * multiplier + ema;
    }
    
    return NormalizeDouble(ema, _Digits);
}

double CalculateATR(const MqlRates &rates[], int period)
{
    double sum = 0;
    for(int i = 1; i < period; i++)
    {
        double trueRange = MathMax(rates[i].high - rates[i].low,
                            MathMax(MathAbs(rates[i].high - rates[i-1].close),
                                    MathAbs(rates[i].low - rates[i-1].close)));
        sum += trueRange;
    }
    return NormalizeDouble(sum / (period - 1), _Digits);
}

//+------------------------------------------------------------------+
//| Check for trade signals                                          |
//+------------------------------------------------------------------+
void CheckForTrades(string symbol)
{
    Print("CheckForTrades 시작: ", symbol);
    SymbolData* data;
    if(!symbolDataMap.TryGetValue(symbol, data))
    {
        Print("심볼 데이터를 찾을 수 없음: ", symbol);
        return;
    }
    
    bool isUptrend = (data.emaFast > data.emaMedium) && (data.emaMedium > data.emaSlow);
    bool isDowntrend = (data.emaFast < data.emaMedium) && (data.emaMedium < data.emaSlow);
    
    Print(symbol, " - Uptrend: ", isUptrend, ", Downtrend: ", isDowntrend, ", Current Position: ", data.position);
    
    if(isUptrend && data.position <= 0)
    {
        Print(symbol, " - 롱 포지션 진입 시도");
        double units = CalculateUnits(symbol, data.atr);
        if(OpenTrade(symbol, ORDER_TYPE_BUY, units))
        {
            data.position = 1;
            data.units += units;
            AdjustStopLoss(symbol, ORDER_TYPE_BUY);
            Print(symbol, " - 롱 포지션 진입 성공. Units: ", units);
        }
    }
    else if(isDowntrend && data.position >= 0)
    {
        Print(symbol, " - 숏 포지션 진입 시도");
        double units = CalculateUnits(symbol, data.atr);
        if(OpenTrade(symbol, ORDER_TYPE_SELL, units))
        {
            data.position = -1;
            data.units += units;
            AdjustStopLoss(symbol, ORDER_TYPE_SELL);
            Print(symbol, " - 숏 포지션 진입 성공. Units: ", units);
        }
    }
    else if(!isUptrend && !isDowntrend)
    {
        if(data.position != 0)
        {
            Print(symbol, " - 포지션 청산 시도");
            CloseTrade(symbol);
            data.position = 0;
            data.units = 0;
            Print(symbol, " - 포지션 청산 완료");
        }
    }
    Print("CheckForTrades 종료: ", symbol);
}

//+------------------------------------------------------------------+
//| Calculate trading units based on ATR                             |
//+------------------------------------------------------------------+
double CalculateUnits(string symbol, double atr)
{
    double initialCapital = 100.0;
    double riskAmount = initialCapital * RiskPercent / 100;
    double symbolPoint = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    double units = riskAmount / (atr * tickValue / symbolPoint);
    units = MathFloor(units / lotStep) * lotStep;
    units = MathMax(minLot, MathMin(units, maxLot));
    
    return units;
}

//+------------------------------------------------------------------+
//| Open a trade                                                     |
//+------------------------------------------------------------------+
bool OpenTrade(string symbol, ENUM_ORDER_TYPE orderType, double volume)
{
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
    
    SymbolData* data;
    if(!symbolDataMap.TryGetValue(symbol, data))
    {
        Print("심볼 데이터를 찾을 수 없습니다: ", symbol);
        return false;
    }
    
    int stopLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * SymbolInfoDouble(symbol, SYMBOL_POINT);
    double atrStopDistance = 2 * data.atr;
    double stopLossDistance = MathMax(atrStopDistance, minStopDistance);
    
    double stopLoss;
    if(orderType == ORDER_TYPE_BUY)
    {
        stopLoss = bid - stopLossDistance;  // bid 기준으로 계산
    }
    else
    {
        stopLoss = ask + stopLossDistance;  // ask 기준으로 계산
    }
    
    // 소수점 자릿수 정규화
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    
    Print("손절가 설정 - 심볼: ", symbol, ", 주문 유형: ", EnumToString(orderType),
          ", ATR: ", data.atr, ", ATR 기반 손절 거리: ", atrStopDistance,
          ", 최소 손절 거리: ", minStopDistance, ", 적용된 손절 거리: ", stopLossDistance);
    
    if(trade.PositionOpen(symbol, orderType, volume, price, stopLoss, 0))
    {
        Print("주문 전송 성공: ", symbol, ", Type: ", EnumToString(orderType), ", Volume: ", volume, 
              ", Price: ", price, ", StopLoss: ", stopLoss, ", Spread: ", (ask - bid));
        return true;
    }
    else
    {
        Print("주문 전송 실패: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Close all trades for a symbol                                    |
//+------------------------------------------------------------------+
void CloseTrade(string symbol)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == MAGIC_NUMBER)
            {
                if(!trade.PositionClose(ticket))
                {
                    Print("포지션 종료 실패: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
                }
                else
                {
                    Print("포지션 종료 성공: ", symbol);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Adjust stop loss for all positions of a symbol                   |
//+------------------------------------------------------------------+
void AdjustStopLoss(string symbol, ENUM_ORDER_TYPE orderType)
{
    double newStopLoss = 0;
    SymbolData* data;
    if(!symbolDataMap.TryGetValue(symbol, data))
    {
        Print("심볼 데이터를 찾을 수 없습니다: ", symbol);
        return;
    }
    
    double stopLoss = 2 * data.atr;
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    
    if(orderType == ORDER_TYPE_BUY)
    {
        newStopLoss = bid - stopLoss;  // bid 기준으로 계산
    }
    else
    {
        newStopLoss = ask + stopLoss;  // ask 기준으로 계산
    }
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    newStopLoss = NormalizeDouble(newStopLoss, digits);
    
    Print("손절가 조정 시도 - 심볼: ", symbol, ", 주문 유형: ", EnumToString(orderType),
          ", ATR: ", data.atr, ", 새 손절가: ", newStopLoss);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == MAGIC_NUMBER)
            {
                double currentStopLoss = PositionGetDouble(POSITION_SL);
                bool needModify = false;
                
                if(orderType == ORDER_TYPE_BUY && newStopLoss > currentStopLoss)
                {
                    needModify = true;
                }
                else if(orderType == ORDER_TYPE_SELL && newStopLoss < currentStopLoss)
                {
                    needModify = true;
                }
                
                if(needModify)
                {
                    Print("손절가 조정 필요 - 티켓: ", ticket, ", 현재 손절가: ", currentStopLoss, ", 새 손절가: ", newStopLoss);
                    if(!trade.PositionModify(ticket, newStopLoss, 0))
                    {
                        Print("손절가 조정 실패: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
                    }
                    else
                    {
                        Print("손절가 조정 성공: ", symbol, ", Ticket: ", ticket, ", New StopLoss: ", newStopLoss);
                    }
                }
                else
                {
                    Print("손절가 조정 불필요 - 티켓: ", ticket, ", 현재 손절가: ", currentStopLoss, ", 계산된 손절가: ", newStopLoss);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 이 EA는 타이머 이벤트를 사용하므로 OnTick()에서는 아무 작업도 하지 않습니다.
}
//+------------------------------------------------------------------+

