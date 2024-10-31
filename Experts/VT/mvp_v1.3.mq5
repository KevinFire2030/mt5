#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.30"
#property description "MVP v1.3 - EMA(5/20/40) 기반 진입/청산 로직, 고정 수량 1 계약"

#property strict

#include <Trade\Trade.mqh>

// 전역 변수
datetime lastBarTime = 0;
int ema5Handle, ema20Handle, ema40Handle;
CTrade Trade;

// 사용자 정의 상수
#define POSITION_TYPE_NONE -1

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // EMA 지표 초기화
    ema5Handle = iMA(Symbol(), PERIOD_M1, 5, 0, MODE_EMA, PRICE_CLOSE);
    ema20Handle = iMA(Symbol(), PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE);
    ema40Handle = iMA(Symbol(), PERIOD_M1, 40, 0, MODE_EMA, PRICE_CLOSE);
    
    if(ema5Handle == INVALID_HANDLE || ema20Handle == INVALID_HANDLE || ema40Handle == INVALID_HANDLE)
    {
        Print("EMA 지표 초기화 실패");
        return(INIT_FAILED);
    }
    
    Print("MVP v1.3 초기화됨");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 지표 핸들 해제
    IndicatorRelease(ema5Handle);
    IndicatorRelease(ema20Handle);
    IndicatorRelease(ema40Handle);
    
    Print("MVP v1.3 종료됨");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(Period() != PERIOD_M1)
    {
        Print("이 EA는 1분 차트에서만 작동합니다.");
        return;
    }
    
    datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);
    if(currentBarTime == lastBarTime)
        return;
    
    lastBarTime = currentBarTime;
    
    // EMA 값 가져오기
    double ema5[], ema20[], ema40[];
    ArraySetAsSeries(ema5, true);
    ArraySetAsSeries(ema20, true);
    ArraySetAsSeries(ema40, true);
    
    if(CopyBuffer(ema5Handle, 0, 0, 1, ema5) == 1 &&
       CopyBuffer(ema20Handle, 0, 0, 1, ema20) == 1 &&
       CopyBuffer(ema40Handle, 0, 0, 1, ema40) == 1)
    {
        bool isUptrend = (ema5[0] > ema20[0]) && (ema20[0] > ema40[0]);
        bool isDowntrend = (ema5[0] < ema20[0]) && (ema20[0] < ema40[0]);
        
        // 포지션 관리
        ManagePositions(isUptrend, isDowntrend);
    }
    else
    {
        Print("EMA 데이터 가져오기 실패");
    }
}

//+------------------------------------------------------------------+
//| 포지션 관리 함수                                                  |
//+------------------------------------------------------------------+
void ManagePositions(bool isUptrend, bool isDowntrend)
{
    // 현재 포지션 확인
    long positionType = PositionType();
    
    // 청산 로직
    if((positionType == POSITION_TYPE_BUY && !isUptrend) ||
       (positionType == POSITION_TYPE_SELL && !isDowntrend))
    {
        CloseAllPositions();
    }
    
    // 진입 로직
    if(positionType == POSITION_TYPE_NONE)
    {
        if(isUptrend)
        {
            Trade.Buy(1, Symbol(), 0, 0, 0, "Long Entry");
        }
        else if(isDowntrend)
        {
            Trade.Sell(1, Symbol(), 0, 0, 0, "Short Entry");
        }
    }
}

//+------------------------------------------------------------------+
//| 모든 포지션 청산 함수                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            Trade.PositionClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| 현재 포지션 타입 확인 함수                                         |
//+------------------------------------------------------------------+
long PositionType()
{
    if(PositionsTotal() == 0)
        return POSITION_TYPE_NONE;
    
    ulong ticket = PositionGetTicket(0);
    if(ticket <= 0)
        return POSITION_TYPE_NONE;
    
    if(!PositionSelectByTicket(ticket))
        return POSITION_TYPE_NONE;
    
    return PositionGetInteger(POSITION_TYPE);
}

