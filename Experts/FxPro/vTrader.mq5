//+------------------------------------------------------------------+
//|                                                       vTrader.mq5  |
//|                                 Copyright 2024, MetaQuotes Ltd.    |
//|                                       https://www.mq15.com/       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mq15.com"
#property version   "1.00"

// Include 파일
#include <Trade\Trade.mqh>
#include <FxPro\vTrader.mqh>  // 경로 수정

// 전역 변수
CvTrader* g_vTrader = NULL;     // vTrader 인스턴스

// 입력 파라미터
input ENUM_TIMEFRAMES   InpTimeframe = PERIOD_CURRENT;  // 타임프레임
input double           InpRisk = 0.01;                  // 리스크 비율(%)
input int              InpMaxPositions = 15;            // 최대 포지션 수
input int              InpMaxPyramiding = 4;           // 최대 피라미딩 수

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // vTrader 인스턴스 생성
    g_vTrader = new CvTrader();
    if(g_vTrader == NULL)
    {
        Print("vTrader 인스턴스 생성 실패");
        return INIT_FAILED;
    }
    
    // vTrader 초기화
    if(!g_vTrader.Init(InpTimeframe, InpRisk, InpMaxPositions, InpMaxPyramiding))
    {
        Print("vTrader 초기화 실패");
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(g_vTrader != NULL)
    {
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
    {
        g_vTrader.OnTick();
    }
} 