//+------------------------------------------------------------------+
//|                                              OpenTrade_test.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "OpenTrade 함수 테스트 (Trade.mqh 사용)"

#include <Trade\Trade.mqh>

#define MAGIC_NUMBER 081009

input string   TestSymbol = "EURUSD";  // 테스트할 심볼
input double   TestVolume = 0.01;      // 테스트 거래량
input int      TestInterval = 10;      // 테스트 간격 (초)

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MAGIC_NUMBER);
    EventSetTimer(TestInterval);
    Print("OpenTrade 테스트가 시작되었습니다.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("OpenTrade 테스트가 종료되었습니다.");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    TestOpenTrade();
}

//+------------------------------------------------------------------+
//| Test OpenTrade function                                          |
//+------------------------------------------------------------------+
void TestOpenTrade()
{
    Print("--- OpenTrade 테스트 시작 ---");
    
    if(!IsTradeAllowed(TestSymbol) || !IsAccountReadyForTrading())
    {
        Print("거래가 허용되지 않거나 계정이 준비되지 않았습니다.");
        return;
    }
    
    // 매수 주문 테스트
    if(OpenTrade(TestSymbol, ORDER_TYPE_BUY, TestVolume))
    {
        Print("매수 주문 성공");
    }
    else
    {
        Print("매수 주문 실패");
    }
    
    // 매도 주문 테스트
    if(OpenTrade(TestSymbol, ORDER_TYPE_SELL, TestVolume))
    {
        Print("매도 주문 성공");
    }
    else
    {
        Print("매도 주문 실패");
    }
    
    Print("--- OpenTrade 테스트 종료 ---");
}

//+------------------------------------------------------------------+
//| Open a trade                                                     |
//+------------------------------------------------------------------+
bool OpenTrade(string symbol, ENUM_ORDER_TYPE orderType, double volume)
{
    double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
    double stopLoss = 0.0;  // 필요한 경우 손절가 설정
    double takeProfit = 0.0;  // 필요한 경우 이익실현가 설정

    if(trade.PositionOpen(symbol, orderType, volume, price, stopLoss, takeProfit))
    {
        Print("주문 전송 성공: ", symbol, ", Type: ", EnumToString(orderType), ", Volume: ", volume, 
              ", Price: ", price, ", StopLoss: ", stopLoss, ", TakeProfit: ", takeProfit);
        return true;
    }
    else
    {
        Print("주문 전송 실패: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradeAllowed(string symbol)
{
    return SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL &&
           MQLInfoInteger(MQL_TRADE_ALLOWED) &&
           TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
}

//+------------------------------------------------------------------+
//| Check if account is ready for trading                            |
//+------------------------------------------------------------------+
bool IsAccountReadyForTrading()
{
    return AccountInfoDouble(ACCOUNT_BALANCE) > 0 &&
           AccountInfoInteger(ACCOUNT_TRADE_EXPERT) == 1 &&
           AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) == 1;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 이 EA는 타이머 이벤트를 사용하므로 OnTick()에서는 아무 작업도 하지 않습니다.
}
//+------------------------------------------------------------------+
