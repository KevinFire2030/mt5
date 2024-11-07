//+------------------------------------------------------------------+
//| 손익 계산 테스트                                                    |
//+------------------------------------------------------------------+
void TestProfitCalculation()
{
    string symbol = "#USNDAQ100";
    double lotSize = 0.14;
    double entryPrice = 19983.20;
    double exitPrice = 19975.95;
    
    // 계약 정보
    double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    
    // 포인트 차이
    double priceDiff = exitPrice - entryPrice;
    double points = priceDiff / tickSize;
    
    // 손익 계산
    double profit = points * tickValue * lotSize;
    
    Print("=== 손익 계산 상세 ===");
    Print("Contract Size: ", contractSize);
    Print("가격 차이: ", priceDiff);
    Print("포인트 수: ", points);
    Print("Lot당 손익: ", points * tickValue);
    Print("최종 손익: ", profit);
    
    // 추가 정보
    Print("=== 추가 정보 ===");
    Print("Trade Mode: ", EnumToString((ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)));
    Print("Calc Mode: ", EnumToString((ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE)));
    Print("Margin Initial: ", SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL));
    Print("Margin Maintenance: ", SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE));
}

//+------------------------------------------------------------------+
void OnStart()
{
    TestProfitCalculation();
}