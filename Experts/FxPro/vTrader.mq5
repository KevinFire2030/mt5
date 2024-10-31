//+------------------------------------------------------------------+
//|                                                       vTrader.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// 필요한 include 파일들
#include "Include/vTrader.mqh"

// 입력 파라미터
input ENUM_TIMEFRAMES   InpTimeframe = PERIOD_M1;     // 타임프레임
input double           InpRisk = 0.01;               // 리스크 (%)
input int              InpMaxPositions = 15;          // 최대 포지션 수
input int              InpMaxPyramiding = 4;          // 최대 피라미딩 수

// 전역 변수
CvTrader* g_vTrader = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // vTrader 인스턴스 생성
    g_vTrader = new CvTrader();
    if(g_vTrader == NULL)
        return INIT_FAILED;
        
    // vTrader 초기화
    if(!g_vTrader.Init(InpTimeframe, InpRisk, InpMaxPositions, InpMaxPyramiding))
        return INIT_FAILED;
        
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(g_vTrader != NULL)
    {
        g_vTrader.Deinit();
        delete g_vTrader;
        g_vTrader = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(g_vTrader != NULL)
        g_vTrader.OnTick();
} 