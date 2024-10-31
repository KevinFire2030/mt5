//+------------------------------------------------------------------+
//|                                               every_minute.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "매 분마다 Market Watch 심볼의 EMA를 계산하는 EA"

#define TIMER_INTERVAL 60  // 60초 (1분) 간격
#define EMA_FAST 5
#define EMA_MEDIUM 20
#define EMA_SLOW 40

class EMAData
{
public:
    double fast;
    double medium;
    double slow;
};

// 심볼별 EMA 데이터를 저장할 맵
#include <Generic\HashMap.mqh>
CHashMap<string, EMAData*> emaCache;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // 다음 분의 시작까지 대기
    datetime current = TimeCurrent();
    MqlDateTime mql_time;
    TimeToStruct(current, mql_time);
    int secondsUntilNextMinute = 60 - mql_time.sec;
    
    // 다음 분의 시작에 타이머 설정
    EventSetTimer(secondsUntilNextMinute);
    Print("EA가 시작되었습니다. 다음 분의 시작에 첫 실행이 이루어집니다.");
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
    EMAData* values[];
    emaCache.CopyTo(keys, values);
    for(int i=0; i<ArraySize(keys); i++)
    {
        if(values[i] != NULL)
        {
            delete values[i];
        }
    }
    emaCache.Clear();
    Print("EA가 종료되었습니다.");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    static bool isFirstRun = true;
    
    if(isFirstRun)
    {
        // 첫 실행 후 타이머를 1분으로 재설정
        EventKillTimer();
        EventSetTimer(60);
        isFirstRun = false;
    }
    
    datetime currentTime = TimeCurrent();
    PrintTimeInfo(currentTime);
    
    for(int i=0; i<SymbolsTotal(true); i++)
    {
        string symbol = SymbolName(i, true);
        CalculateEMA(symbol);
    }
}

//+------------------------------------------------------------------+
//| Calculate EMA for a symbol                                       |
//+------------------------------------------------------------------+
void CalculateEMA(string symbol)
{
    MqlRates rates[];
    if(CopyRates(symbol, PERIOD_M1, 0, 60, rates) != 60)
    {
        Print("데이터 복사 실패: ", symbol);
        return;
    }
    
    EMAData* ema;
    if(!emaCache.ContainsKey(symbol))
    {
        ema = new EMAData();
        emaCache.Add(symbol, ema);
    }
    else
    {
        emaCache.TryGetValue(symbol, ema);
    }
    
    ema.fast = CalculateEMAValue(rates, EMA_FAST);
    ema.medium = CalculateEMAValue(rates, EMA_MEDIUM);
    ema.slow = CalculateEMAValue(rates, EMA_SLOW);
    
    Print(symbol, " EMA - Fast: ", ema.fast, ", Medium: ", ema.medium, ", Slow: ", ema.slow);
}

//+------------------------------------------------------------------+
//| Calculate EMA value                                              |
//+------------------------------------------------------------------+
double CalculateEMAValue(const MqlRates &rates[], int period)
{
    double multiplier = 2.0 / (period + 1);
    double ema = rates[0].close;
    
    for(int i = 1; i < ArraySize(rates); i++)
    {
        ema = (rates[i].close - ema) * multiplier + ema;
    }
    
    return NormalizeDouble(ema, _Digits);
}

//+------------------------------------------------------------------+
//| Print time information                                           |
//+------------------------------------------------------------------+
void PrintTimeInfo(datetime currentTime)
{
    datetime localTime = TimeLocal();
    
    datetime nyTime = currentTime - 7 * 3600;
    datetime londonTime = currentTime - 3 * 3600;
    
    Print("현재 뉴욕 시간: ", TimeToString(nyTime, TIME_DATE|TIME_SECONDS), " (UTC-4)");
    Print("현재 런던 시간: ", TimeToString(londonTime, TIME_DATE|TIME_SECONDS), " (UTC+0)");
    Print("현재 서버 시간: ", TimeToString(currentTime, TIME_DATE|TIME_SECONDS), " (UTC+3)");
    Print("현재 로컬 시간: ", TimeToString(localTime, TIME_DATE|TIME_SECONDS), " (UTC", TimeGMTOffset() / 3600, ")");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 이 EA는 타이머 이벤트를 사용하므로 OnTick()에서는 아무 작업도 하지 않습니다.
}
//+------------------------------------------------------------------+
