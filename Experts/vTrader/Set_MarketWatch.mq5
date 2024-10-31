//+------------------------------------------------------------------+
//|                                             Set_MarketWatch.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Market Watch 심볼을 설정하는 EA"

//+------------------------------------------------------------------+
//| 사용자 정의 함수: Market Watch 설정                               |
//+------------------------------------------------------------------+
void SetMarketWatchSymbols()
{
    // 기존 Market Watch 심볼 모두 삭제
    for(int i=SymbolsTotal(true)-1; i>=0; i--)
    {
        string symbol = SymbolName(i, true);
        SymbolSelect(symbol, false);
    }
    
    // 지정된 심볼 추가
    string symbols[] = {"EURUSD", "#USNDAQ100", "BITCOIN"};
    
    for(int i=0; i<ArraySize(symbols); i++)
    {
        if(SymbolSelect(symbols[i], true))
        {
            Print(symbols[i], " 심볼이 Market Watch에 추가되었습니다.");
        }
        else
        {
            Print(symbols[i], " 심볼을 추가하는 데 실패했습니다.");
        }
    }
    
    Print("Market Watch 설정이 완료되었습니다.");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    SetMarketWatchSymbols();
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 필요한 경우 정리 작업을 여기에 추가
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 이 EA는 초기화 시에만 Market Watch를 설정하므로 OnTick()에서는 아무 작업도 하지 않습니다.
}
