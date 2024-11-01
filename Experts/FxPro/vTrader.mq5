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

// 매직넘버 자동 계산 (YYMMDD)
int CalcTodayMagicNumber()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int magic = (dt.year % 100) * 10000 + dt.mon * 100 + dt.day;
    
    // 유효성 검사
    if(magic < 0)
    {
        Print("매직넘버 생성 오류!");
        return 0;
    }
    
    return magic;
}

input ENUM_TIMEFRAMES   InpTimeframe = PERIOD_CURRENT;  // 타임프레임
input double           InpRisk = 1.0;                   // 리스크 비율(%)
input int              InpMaxPositions = 5;             // 최대 포지션 수
input int              InpMaxPyramiding = 4;            // 최대 피라미딩 수
input int              InpMagicNumber = 0;    // 매직넘버 (자동: YYMMDD)
//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{

    int magicNumber = (InpMagicNumber == 0) ? CalcTodayMagicNumber() : InpMagicNumber;
    
    // 매직넘버 정보 출력
    if(InpMagicNumber == 0)
    {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        Print("매직넘버 자동 생성: ", magicNumber, " (", 
              dt.year, ".", dt.mon, ".", dt.day, ")");
    }
    else
    {
        Print("사용자 지정 매직넘버: ", magicNumber);
    }


    // vTrader 인스턴스 생성
    g_vTrader = new CvTrader();
    if(g_vTrader == NULL)
    {
        Print("vTrader 인스턴스 생성 실패");
        return INIT_FAILED;
    }
    
    // vTrader 초기화
    if(!g_vTrader.Init(InpTimeframe, InpRisk, InpMaxPositions, InpMaxPyramiding, magicNumber))
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