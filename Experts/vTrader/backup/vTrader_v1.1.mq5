#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.1"

#include "vTrader_v1.1.mqh"

// EA 파라미터
input ulong InpMagicNumber = 20240311;  // 매직 넘버

// 전역 변수
CvTrader* g_trader = NULL;

// EA 초기화
int OnInit() {
    Print("=== vTrader v1.1 초기화 ===");
    
    g_trader = new CvTrader();
    if(!g_trader.Init(_Symbol, InpMagicNumber)) {
        Print("트레이더 초기화 실패");
        return INIT_FAILED;
    }
    
    Print("매직넘버: ", InpMagicNumber);
    Print("=== 초기화 완료 ===");
    return INIT_SUCCEEDED;
}

// EA 해제
void OnDeinit(const int reason) {
    if(g_trader != NULL) {
        g_trader.Deinit();
        delete g_trader;
        g_trader = NULL;
    }
}

// 틱 이벤트
void OnTick() {
    if(g_trader != NULL) {
        g_trader.OnTick();
    }
}

// 거래 트랜잭션 이벤트
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    if(g_trader != NULL) {
        g_trader.OnTradeTransaction(trans, request, result);
    }
} 