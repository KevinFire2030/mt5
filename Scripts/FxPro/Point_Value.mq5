//+------------------------------------------------------------------+
//| 심볼의 Point Value 확인                                             |
//+------------------------------------------------------------------+
void CheckPointValue()
{
    string symbol = Symbol();  // 현재 차트의 심볼
    
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);        // 최소 가격 변동폭
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);      // 최소 가격 변동당 가치
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);                     // 포인트 크기
    double pointValue = tickValue * (point / tickSize);                        // 1 포인트당 가치
    
    Print("=== ", symbol, " Point Value 정보 ===");
    Print("Tick Size: ", tickSize);
    Print("Tick Value: ", tickValue);
    Print("Point: ", point);
    Print("Point Value: ", pointValue);
}

//+------------------------------------------------------------------+
void OnStart()
{
    CheckPointValue();
}