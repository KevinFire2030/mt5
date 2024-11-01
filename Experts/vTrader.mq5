#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/FxPro/vTrader.mqh"

// === 입력 파라미터 ===
input int InpMaxPositions = 5;      // 최대 포지션 수
input int InpMaxPyramid = 4;        // 최대 피라미딩 수
input double InpRiskPercent = 1.0;  // 리스크 비율(%)

// === 글로벌 변수 ===
CvTrader *g_trader = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // 매직넘버 자동 생성 (YYMMDD 형식)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int magic = (dt.year % 100) * 10000 + dt.mon * 100 + dt.day;
    
    g_trader = new CvTrader(_Symbol, magic, InpMaxPositions, InpMaxPyramid, InpRiskPercent);
    if(!g_trader.Init()) {
        Print("vTrader 초기화 실패");
        return INIT_FAILED;
    }
    
    Print("=== 라이브 테스트 시작 ===");
    Print("시작 시간: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
    Print("단축키 안내:");
    Print("  B: 매수 포지션 열기");
    Print("  S: 매도 포지션 열기");
    Print("  P: 피라미딩 시도");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(g_trader != NULL) {
        delete g_trader;
        g_trader = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(g_trader != NULL) g_trader.OnTick();
}
