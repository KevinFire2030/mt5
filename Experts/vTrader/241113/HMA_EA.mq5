//+------------------------------------------------------------------+
//|                                                        HMA_EA.mq5 |
//|                                                           vTrader |
//+------------------------------------------------------------------+
#property copyright "vTrader"
#property link      ""
#property version   "1.00"

// 입력 파라미터
input double   Lot = 0.01;              // 거래량
input int      HMAPeriod = 20;         // HMA 기간
input int      Magic = 241112;         // 매직 넘버

// 전역 변수
int hmaHandle;           // HMA 지표 핸들
double hmaBuffer[];      // HMA 값 저장
double colorBuffer[];    // HMA 색상 저장
int barCount;           // 계산된 봉 수

//+------------------------------------------------------------------+
int OnInit()
{
   // HMA 지표 초기화
   hmaHandle = iCustom(_Symbol, PERIOD_CURRENT, "Hull_Moving_Average", 
                      HMAPeriod, 0, MODE_LWMA, PRICE_TYPICAL);
   
   if(hmaHandle == INVALID_HANDLE)
   {
      Print("HMA 지표 생성 실패");
      return(INIT_FAILED);
   }
   
   // 버퍼 초기화
   ArraySetAsSeries(hmaBuffer, true);
   ArraySetAsSeries(colorBuffer, true);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(hmaHandle != INVALID_HANDLE)
      IndicatorRelease(hmaHandle);
}


// 추세 확인 함수
int TrendSignalCheck()
{
   // 하락 -> 상승 전환
   if(hmaBuffer[0] > hmaBuffer[1] && hmaBuffer[1] < hmaBuffer[2])
   {
      return 1;  // 상승 전환
   }
   
   // 상승 -> 하락 전환
   if(hmaBuffer[0] < hmaBuffer[1] && hmaBuffer[1] > hmaBuffer[2])
   {
      return -1;  // 하락 전환
   }
   
   return 0;  // 추세 유지
} 


//+------------------------------------------------------------------+
void OnTick()
{

   //if(!IsNewBar()) return;
   
   double cPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // 버퍼 복사
   if(CopyBuffer(hmaHandle, 1, 0, 5, hmaBuffer) <= 0) return;    // HMA 값

   // 추세 신호확인
   int trendSignal = TrendSignalCheck();

   if (trendSignal == 0) return;
   
   
   // 현재 포지션 확인
   bool hasLong = false;
   bool hasShort = false;
   
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetInteger(POSITION_MAGIC) == Magic)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               hasLong = true;
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
               hasShort = true;
         }
      }
   }
  
   
   if(trendSignal == 1) // 상승 전환
   {
   
      Print("상승 전환");
   
      // 숏 포지션 청산
      if(hasShort) ClosePosition(POSITION_TYPE_SELL);
         
      // 롱 포지션 진입
      if(!hasLong) OpenBuy();
   
   }
   
   if(trendSignal == -1) // 하락 전환
   {
   
      Print("하락 전환");
   
      // 롱 포지션 청산
      if(hasLong) ClosePosition(POSITION_TYPE_BUY);
      
      // 숏 포지션 진입
      if(!hasShort) OpenSell();
   
   }
     
   
}

//+------------------------------------------------------------------+
void OpenBuy()
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = Lot;
   request.type = ORDER_TYPE_BUY;
   request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = 10;
   request.magic = Magic;
   request.type_filling = ORDER_FILLING_IOC;
   
   if(!OrderSend(request, result))
   {
      Print("OrderSend error: ", GetLastError());
      return;
   }
   
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("OrderSend failed: ", result.retcode);
      return;
   }
}

//+------------------------------------------------------------------+
void OpenSell()
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = Lot;
   request.type = ORDER_TYPE_SELL;
   request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = 10;
   request.magic = Magic;
   request.type_filling = ORDER_FILLING_IOC;
   
   if(!OrderSend(request, result))
   {
      Print("OrderSend error: ", GetLastError());
      return;
   }
   
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("OrderSend failed: ", result.retcode);
      return;
   }
}

//+------------------------------------------------------------------+
void ClosePosition(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetInteger(POSITION_MAGIC) == Magic &&
            PositionGetInteger(POSITION_TYPE) == posType)
         {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = PositionGetTicket(i);
            request.symbol = _Symbol;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.deviation = 10;
            request.magic = Magic;
            request.type_filling = ORDER_FILLING_IOC;
            
            if(posType == POSITION_TYPE_BUY)
            {
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               request.type = ORDER_TYPE_SELL;
            }
            else
            {
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               request.type = ORDER_TYPE_BUY;
            }
            
            if(!OrderSend(request, result))
            {
               Print("OrderSend error: ", GetLastError());
               continue;
            }
            
            if(result.retcode != TRADE_RETCODE_DONE)
            {
               Print("OrderSend failed: ", result.retcode);
               continue;
            }
         }
      }
   }
} 


//+------------------------------------------------------------------+
// 유틸리티 메서드
bool IsNewBar() {
  static datetime lastBar = 0;
  datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
  if(currentBar != lastBar) {
      lastBar = currentBar;
      return true;
  }
  return false;
}