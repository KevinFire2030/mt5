//+------------------------------------------------------------------+
//| VWAP Scalping Strategy EA
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property version   "1.00"
#property tester_indicator "VWAP"

#include <Trade\Trade.mqh>
CTrade trade;  // 트레이드 객체 추가

// VWAP 가격 계산 방식 정의
enum PRICE_TYPE 
{
   OPEN,                    // 시가
   CLOSE,                   // 종가
   HIGH,                    // 고가
   LOW,                     // 저가
   OPEN_CLOSE,             // (시가+종가)/2
   HIGH_LOW,               // (고가+저가)/2
   CLOSE_HIGH_LOW,         // (종가+고가+저가)/3
   OPEN_CLOSE_HIGH_LOW     // (시가+종가+고가+저가)/4
};

// 입력 파라미터
input int      VWAP_Period = 15;        // VWAP 계산 기간
input int      BB_Period = 14;          // 볼린저밴드 기간
input double   BB_Deviation = 2.0;      // 볼린저밴드 표준편차
input int      RSI_Period = 14;         // RSI 기간
input double   RSI_UpperLevel = 55;     // RSI 매도 진입 레벨
input double   RSI_LowerLevel = 45;     // RSI 매수 진입 레벨
input double   RSI_UpperExit = 90;      // RSI 롱 포지션 청산 레벨
input double   RSI_LowerExit = 10;      // RSI 숏 포지션 청산 레벨
input double   ATR_Multiplier = 1.2;    // ATR 승수
input double   TP_SL_Ratio = 1.5;       // 익절/손절 비율
input double   RiskPercent = 1.0;       // 리스크 비율
input PRICE_TYPE Price_Type = CLOSE_HIGH_LOW;  // VWAP 가격 계산 방식

// 지표 핸들
int BB_Handle;
int RSI_Handle;
int ATR_Handle;
int VWAP_Handle;
int Volume_Handle;  // Volumes 지표로 변경

// 새로운 바 체크를 위한 전역변수
datetime lastbar_time;

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
{
    // 지표 초기화
    BB_Handle = iBands(_Symbol, Period(), BB_Period, 0, BB_Deviation, PRICE_CLOSE);
    RSI_Handle = iRSI(_Symbol, Period(), RSI_Period, PRICE_CLOSE);
    ATR_Handle = iATR(_Symbol, Period(), 7);
    VWAP_Handle = iCustom(_Symbol, Period(), "VWAP");
    Volume_Handle = iVolumes(_Symbol, Period(), VOLUME_REAL);  // VOLUME_TICK에서 VOLUME_REAL로 변경
    
    // 핸들 유효성 검사 추가
    if(BB_Handle==INVALID_HANDLE || RSI_Handle==INVALID_HANDLE || 
       ATR_Handle==INVALID_HANDLE || VWAP_Handle==INVALID_HANDLE ||
       Volume_Handle==INVALID_HANDLE)
    {
        Print("Error creating indicators");
        return(INIT_FAILED);
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 지표 핸들 해제
    IndicatorRelease(BB_Handle);
    IndicatorRelease(RSI_Handle);
    IndicatorRelease(ATR_Handle);
    IndicatorRelease(VWAP_Handle);
    IndicatorRelease(Volume_Handle);
}

//+------------------------------------------------------------------+
//| 매매 신호 확인                                                      |
//+------------------------------------------------------------------+
int CheckSignal()
{
    // VWAP 트렌드 확인 (완성된 봉까지만)
    bool vwapUpTrend = CheckVWAPTrend(true);
    bool vwapDownTrend = CheckVWAPTrend(false);
    
    // 볼린저밴드 값 가져오기 (완성된 봉)
    double bb_upper[], bb_lower[];
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_lower, true);
    CopyBuffer(BB_Handle, 1, 1, 1, bb_upper);  // 1번째 봉(완성봉)
    CopyBuffer(BB_Handle, 2, 1, 1, bb_lower);  // 1번째 봉(완성봉)
    
    // RSI 값 가져오기 (완성된 봉)
    double rsi[];
    ArraySetAsSeries(rsi, true);
    CopyBuffer(RSI_Handle, 0, 1, 1, rsi);      // 1번째 봉(완성봉)
    
    double close = iClose(_Symbol, Period(), 1); // 완성된 마지막 봉의 종가
    
    // 매수 신호
    if(vwapUpTrend && close <= bb_lower[0] && rsi[0] < RSI_LowerLevel)
        return 1;
        
    // 매도 신호
    if(vwapDownTrend && close >= bb_upper[0] && rsi[0] > RSI_UpperLevel)
        return -1;
        
    return 0;
}

//+------------------------------------------------------------------+
//| VWAP 트렌드 확인                                                   |
//+------------------------------------------------------------------+
bool CheckVWAPTrend(bool isUpTrend)
{
    int count = 0;
    double vwap[];
    ArraySetAsSeries(vwap, true);
    
    // 데이터 복사 성공 여부 확인
    if(CopyBuffer(VWAP_Handle, 0, 1, VWAP_Period, vwap) <= 0)
    {
        Print("Error copying VWAP data: ", GetLastError());
        return false;
    }
    
    for(int i = 0; i < VWAP_Period; i++)
    {
        double high = iHigh(_Symbol, Period(), i + 1);  // i + 1로 완성된 봉만 사용
        double low = iLow(_Symbol, Period(), i + 1);    // i + 1로 완성된 봉만 사용
        
        if(isUpTrend && low > vwap[i]) count++;
        else if(!isUpTrend && high < vwap[i]) count++;
    }
    
    return (count == VWAP_Period);
}

//+------------------------------------------------------------------+
//| 포지션 크기 계산                                                    |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLoss)
{
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * RiskPercent / 100.0;
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    if(stopLoss <= 0) return 0;
    
    double lotSize = (riskAmount / (stopLoss * tickValue / tickSize));
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| 매수 포지션 오픈                                                    |
//+------------------------------------------------------------------+
void OpenBuy(double stopLoss, double takeProfit)
{
    // double lotSize = CalculateLotSize(stopLoss);  // 기존 코드 주석처리
    double lotSize = 0.01;                           // 고정 로트 사이즈
    if(lotSize <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    trade.Buy(lotSize, _Symbol, ask, ask - stopLoss, ask + takeProfit);
}

//+------------------------------------------------------------------+
//| 매도 포지션 오픈                                                    |
//+------------------------------------------------------------------+
void OpenSell(double stopLoss, double takeProfit)
{
    // double lotSize = CalculateLotSize(stopLoss);  // 기존 코드 주석처리
    double lotSize = 0.01;                           // 고정 로트 사이즈
    if(lotSize <= 0) return;
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    trade.Sell(lotSize, _Symbol, bid, bid + stopLoss, bid - takeProfit);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsNewBar()) return;
    
    // 포지션 확인
    if(PositionsTotal() > 0) 
    {
        CheckForExit();
        return;
    }
    
    // 신호 확인
    int signal = CheckSignal();
    if(signal == 0) return;
    
    // ATR 기반 손절/익절 계산
    double atr[];
    ArraySetAsSeries(atr, true);
    CopyBuffer(ATR_Handle, 0, 0, 1, atr);
    
    double stopLoss = atr[0] * ATR_Multiplier;
    double takeProfit = stopLoss * TP_SL_Ratio;
    
    // 주문 실행
    if(signal > 0)
        OpenBuy(stopLoss, takeProfit);
    else
        OpenSell(stopLoss, takeProfit);
}

//+------------------------------------------------------------------+
//| 새로운 바 확인 함수                                                 |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime curbar_time = iTime(_Symbol, Period(), 0);
   if(curbar_time != lastbar_time)
   {
      lastbar_time = curbar_time;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| 청산 조건 확인                                                      |
//+------------------------------------------------------------------+
void CheckForExit()
{
    double rsi[];
    ArraySetAsSeries(rsi, true);
    CopyBuffer(RSI_Handle, 0, 0, 1, rsi);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)  // 포지션 선택 성공
        {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && rsi[0] >= RSI_UpperExit)
                trade.PositionClose(ticket);
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && rsi[0] <= RSI_LowerExit)
                trade.PositionClose(ticket);
        }
    }
} 