#property copyright "vTrader"
#property link      "https://github.com/vTrader"
#property version   "1.00"
#property description "간단한 EMA + 모멘텀 전략 EA"

// 필요한 헤더 파일 포함
#include <Trade\Trade.mqh>

// 입력 파라미터
input double LotSize = 0.1;              // 거래량
input int StopLoss = 1000;                // 손절가 (포인트)
input double PartialClosePercent = 50.0; // 부분 청산 비율 (%)

// 지표 핸들
int ema10Handle;
int ema34Handle;
int momentum10Handle;
int momentum34Handle;

// 지표 버퍼
double ema10Buffer[];
double ema34Buffer[];
double momentum10Buffer[];
double momentum34Buffer[];

// 포지션 관리 변수
bool inPosition = false;
int positionType = 0;  // 1: 롱, -1: 숏

// 트레이드 객체
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // 트레이드 설정
    trade.SetExpertMagicNumber(123456);  // 매직 넘버 설정
    trade.SetDeviationInPoints(10);      // 슬리피지 설정
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    trade.LogLevel(LOG_LEVEL_ALL);
    
    // 지표 초기화
    ema10Handle = iMA(_Symbol, PERIOD_CURRENT, 10, 0, MODE_EMA, PRICE_CLOSE);
    ema34Handle = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    momentum10Handle = iMomentum(_Symbol, PERIOD_CURRENT, 10, PRICE_CLOSE);
    momentum34Handle = iMomentum(_Symbol, PERIOD_CURRENT, 34, PRICE_CLOSE);
    
    // 버퍼 초기화
    ArraySetAsSeries(ema10Buffer, true);
    ArraySetAsSeries(ema34Buffer, true);
    ArraySetAsSeries(momentum10Buffer, true);
    ArraySetAsSeries(momentum34Buffer, true);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // 새로운 봉 확인
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    // 같은 봉에서는 처리하지 않음
    if(lastBarTime == currentBarTime)
        return;
        
    // 새로운 봉의 시작
    lastBarTime = currentBarTime;
    
    // 지표 데이터 복사
    CopyBuffer(ema10Handle, 0, 0, 3, ema10Buffer);
    CopyBuffer(ema34Handle, 0, 0, 3, ema34Buffer);
    CopyBuffer(momentum10Handle, 0, 0, 3, momentum10Buffer);
    CopyBuffer(momentum34Handle, 0, 0, 3, momentum34Buffer);
    
    // 현재 포지션 확인
    if(!inPosition)
    {
        // 매수 시그널 체크
        if(CheckBuySignal())
        {
            Buy();
        }
        // 매도 시그널 체크
        else if(CheckSellSignal())
        {
            Sell();
        }
    }
    else
    {
        // 포지션 관리
        ManagePosition();
    }
}

//+------------------------------------------------------------------+
//| 매수 시그널 체크                                                   |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
    // 정배열 확인
    bool isUptrend = ema10Buffer[0] > ema34Buffer[0];
    
    // 모멘텀 조건 확인
    bool momentum34Above = momentum34Buffer[0] > 100;
    bool momentum10CrossUp = momentum10Buffer[1] < 100 && momentum10Buffer[0] > 100;
    
    return isUptrend && momentum34Above && momentum10CrossUp;
}

//+------------------------------------------------------------------+
//| 매도 시그널 체크                                                   |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
    // 역배열 확인
    bool isDowntrend = ema10Buffer[0] < ema34Buffer[0];
    
    // 모멘텀 조건 확인
    bool momentum34Below = momentum34Buffer[0] < 100;
    bool momentum10CrossDown = momentum10Buffer[1] > 100 && momentum10Buffer[0] < 100;
    
    return isDowntrend && momentum34Below && momentum10CrossDown;
}

//+------------------------------------------------------------------+
//| 매수 실행                                                          |
//+------------------------------------------------------------------+
void Buy()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = ask - StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(trade.Buy(LotSize, _Symbol, ask, sl, 0, "Buy Order"))
    {
        inPosition = true;
        positionType = 1;
    }
}

//+------------------------------------------------------------------+
//| 매도 실행                                                          |
//+------------------------------------------------------------------+
void Sell()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = bid + StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(trade.Sell(LotSize, _Symbol, bid, sl, 0, "Sell Order"))
    {
        inPosition = true;
        positionType = -1;
    }
}

//+------------------------------------------------------------------+
//| 포지션 관리                                                        |
//+------------------------------------------------------------------+
void ManagePosition()
{
    // 현재 포지션 정보 가져오기
    ulong ticket = PositionGetTicket(0);
    if(ticket <= 0) return;
    
    if(positionType == 1)  // 롱 포지션
    {
        // 10 EMA 하향 돌파 시 전량 청산
        if(SymbolInfoDouble(_Symbol, SYMBOL_BID) < ema10Buffer[0])
        {
            trade.PositionClose(ticket);
            inPosition = false;
            positionType = 0;
        }
        // 34 EMA 하향 돌파 시 전량 청산
        else if(SymbolInfoDouble(_Symbol, SYMBOL_BID) < ema34Buffer[0])
        {
            trade.PositionClose(ticket);
            inPosition = false;
            positionType = 0;
        }
    }
    else if(positionType == -1)  // 숏 포지션
    {
        // 10 EMA 상향 돌파 시 전량 청산
        if(SymbolInfoDouble(_Symbol, SYMBOL_ASK) > ema10Buffer[0])
        {
            trade.PositionClose(ticket);
            inPosition = false;
            positionType = 0;
        }
        // 34 EMA 상향 돌파 시 전량 청산
        else if(SymbolInfoDouble(_Symbol, SYMBOL_ASK) > ema34Buffer[0])
        {
            trade.PositionClose(ticket);
            inPosition = false;
            positionType = 0;
        }
    }
} 