//+------------------------------------------------------------------+
//|                                                 symbol_info.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Market Watch의 visible 심볼을 출력하는 EA"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Market Watch의 visible 심볼 목록:");
    
    for(int i=0; i<SymbolsTotal(true); i++)
    {
        string symbol = SymbolName(i, true);
        Print(i+1, ": ", symbol);
    }
    
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
    // 이 EA는 초기화 시에만 심볼을 출력하므로 OnTick()에서는 아무 작업도 하지 않습니다.
}
//+------------------------------------------------------------------+

