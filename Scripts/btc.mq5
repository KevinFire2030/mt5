//+------------------------------------------------------------------+
//|                                                      mvp_mt5.mql
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property strict

void OnStart()
{
    // 심볼 설정
    string symbol = "BITCOIN";

    // 30일 전 날짜 계산
    datetime utc_from = TimeCurrent() - 30 * 86400;

    // 30일간의 일봉 데이터 가져오기
    MqlRates rates[];
    int copied = CopyRates(symbol, PERIOD_D1, utc_from, 30, rates);

    // 데이터가 비어있는지 확인
    if (copied <= 0)
    {
        Print("데이터가 없습니다.");
    }
    else
    {
        // 데이터 출력
        for (int i = 0; i < ArraySize(rates); i++)
        {
            Print("Time: ", TimeToString(rates[i].time, TIME_DATE | TIME_MINUTES), 
                  " Open: ", rates[i].open, 
                  " High: ", rates[i].high, 
                  " Low: ", rates[i].low, 
                  " Close: ", rates[i].close, 
                  " Volume: ", rates[i].tick_volume);
        }
    }
}