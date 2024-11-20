//+------------------------------------------------------------------+
//|                                                       turtle.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
// 전역 변수 선언
double atrBuffer[];  // ATR 값을 저장할 배열
int atrHandle;      // ATR 지표 핸들

int OnInit()
{
   // ATR 지표 핸들 생성
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   
   // 핸들 유효성 검사
   if(atrHandle == INVALID_HANDLE)
   {
      Print("ATR 지표 초기화 실패!");
      return INIT_FAILED;
   }
   
   // 배열을 시계열로 설정
   ArraySetAsSeries(atrBuffer, true);
   
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // 지표 핸들 해제
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // ATR 값 복사 (더 많은 데이터)
   int copied = CopyBuffer(atrHandle, 0, 0, 50, atrBuffer);  // 50개의 데이터 복사
   if(copied <= 0)
   {
      Print("ATR 데이터 복사 실패");
      return;
   }
   
   // ATR 값 사용 (14기간 이후부터)
   for(int i = 14; i < copied; i++)
   {
      if(atrBuffer[i] > 0)
      {
         Print("ATR[", i, "]: ", atrBuffer[i]);
      }
   }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
