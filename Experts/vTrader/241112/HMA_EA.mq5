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

//+------------------------------------------------------------------+
void OnTick()
{

   if(!IsNewBar()) return;
   
   // 버퍼 복사
   if(CopyBuffer(hmaHandle, 1, 0, 5, hmaBuffer) <= 0) return;    // HMA 값
   if(CopyBuffer(hmaHandle, 2, 0, 5, colorBuffer) <= 0) return;  // 색상 값
   
   // 현재 포지션 확인
   bool hasLong = false;
   bool hasShort = false;
   bool trend = false;
   
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
   
   // 색상 변화 확인 (1봉 전과 현재 비교)
   /*
   if(colorBuffer[1] != colorBuffer[0])  // 색상 변화 발생
   {
      if(colorBuffer[0] == 0)  // 녹색으로 변화
      {
         // 숏 포지션 청산
         if(hasShort) ClosePosition(POSITION_TYPE_SELL);
         
         // 롱 포지션 진입
         if(!hasLong) OpenBuy();
      }
      else  // 적색으로 변화
      {
         // 롱 포지션 청산
         if(hasLong) ClosePosition(POSITION_TYPE_BUY);
         
         // 숏 포지션 진입
         if(!hasShort) OpenSell();
      }
   }
   */
   
   // 색상 변화 확인 (1봉 전과 현재 비교)
   /*
   if(colorBuffer[1] != colorBuffer[0])  // 색상 변화 발생
   {
      if(colorBuffer[0] == 0)  // 녹색으로 변화
      {
         // 숏 포지션 청산
         if(hasShort) ClosePosition(POSITION_TYPE_SELL);
         
         // 롱 포지션 진입
         if(!hasLong) OpenBuy();
      }
      else  // 적색으로 변화
      {
         // 롱 포지션 청산
         if(hasLong) ClosePosition(POSITION_TYPE_BUY);
         
         // 숏 포지션 진입
         if(!hasShort) OpenSell();
      }
   }
   
   if ((movingAverage[i - 1] < movingAverage[i] && movingAverage[i + 1] < movingAverage[i]) || 
            (movingAverage[i - 1] > movingAverage[i] && movingAverage[i + 1] > movingAverage[i])) {
   */
   
   //trend = hmaBuffer[1] > hmaBuffer[0] ? 1 : 0 // 상승이면 녹색(1), 하락이면 적색(0)
   
   if(hmaBuffer[3] > hmaBuffer[2] && hmaBuffer[1] > hmaBuffer[2]) // 상승 전환
   {
   
      Print("상승 전환");
   
      // 숏 포지션 청산
      if(hasShort) ClosePosition(POSITION_TYPE_SELL);
         
      // 롱 포지션 진입
      if(!hasLong) OpenBuy();
   
   }
   
   if(hmaBuffer[3] < hmaBuffer[2] && hmaBuffer[1] < hmaBuffer[2]) // 하락 전환
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