//+------------------------------------------------------------------+
//|                                                 HMA_EA_241113.mq5 |
//|                                                           vTrader |
//+------------------------------------------------------------------+
#property copyright "vTrader"
#property link      ""
#property version   "1.01"

// 입력 파라미터
input double   Lot = 0.01;              // 거래량
input int      HMAPeriod = 20;          // HMA 기간
input int      Magic = 241113;          // 매직 넘버
input double   StopLoss = 1000;          // 손절값 (포인트)
input double   TakeProfit = 2000;        // 익절값 (포인트)
input double   TrailingStop = 500;       // 트레일링 스탑 (포인트)

// 전역 변수
int hmaHandle;           // HMA 지표 핸들
double hmaBuffer[];      // HMA 값 저장
double colorBuffer[];    // HMA 색상 저장
int barCount;           // 계산된 봉 수
datetime lastBarTime = 0;  // 전역 변수로 선언
datetime lastTickTime = 0;    // 마지막 틱 시간
int minStopLevel;  // 최소 스탑 레벨
double actualStopLoss;    // 실제 사용할 손절값
double actualTakeProfit;  // 실제 사용할 익절값
bool hasLong = false;
bool hasShort = false;

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
   
   // 최소 스탑 레벨 가져오기
   minStopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   
   // 실제 사용할 손절/익절값 설정
   actualStopLoss = StopLoss;
   actualTakeProfit = TakeProfit;
   
   if(actualStopLoss > 0 && actualStopLoss < minStopLevel)
   {
      Print("StopLoss가 최소 스탑 레벨(", minStopLevel, ")보다 작습니다. StopLoss를 ", minStopLevel, "로 조정합니다.");
      actualStopLoss = minStopLevel;
   }
   
   if(actualTakeProfit > 0 && actualTakeProfit < minStopLevel)
   {
      Print("TakeProfit이 최소 스탑 레벨(", minStopLevel, ")보다 작습니다. TakeProfit을 ", minStopLevel, "로 조정합니다.");
      actualTakeProfit = minStopLevel;
   }
   
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
    if(!IsFirstTickOfBar()) return;
   
   // 버퍼 복사
   if(CopyBuffer(hmaHandle, 1, 0, 5, hmaBuffer) <= 0) return;
   
   // 현재 포지션 상태 확인 및 업데이트
   UpdatePositionStatus();
   
   // 추세 전환 확인
   int trendChange = IsTrendChange();
   
   if(trendChange == 1)  // 상승 전환
   {
      Print("상승 전환");
      Print("현재 포지션 상태 - Long: ", hasLong, ", Short: ", hasShort);  // 디버깅용
      
      // 숏 포지션 청산
      if(hasShort) ClosePosition(POSITION_TYPE_SELL);
         
      // 롱 포지션 진입
      if(!hasLong) {
         double sl = actualStopLoss > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) - actualStopLoss * _Point : 0;
         double tp = actualTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) + actualTakeProfit * _Point : 0;
         OpenBuy(sl, tp);
      }
   }
   else if(trendChange == -1)  // 하락 전환
   {
      Print("하락 전환");
      Print("현재 포지션 상태 - Long: ", hasLong, ", Short: ", hasShort);  // 디버깅용
      
      // 롱 포지션 청산
      if(hasLong) ClosePosition(POSITION_TYPE_BUY);
      
      // 숏 포지션 진입
      if(!hasShort) {
         double sl = actualStopLoss > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) + actualStopLoss * _Point : 0;
         double tp = actualTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) - actualTakeProfit * _Point : 0;
         OpenSell(sl, tp);
      }
   }
   
   // 트레일링 스탑 관리
   if(TrailingStop > 0) ManageTrailingStop();
}

// 포지션 상태 업데이트 함수 추가
void UpdatePositionStatus()
{
   hasLong = false;
   hasShort = false;
   
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
   
   // 디버깅용 로그
   static bool lastLong = false;
   static bool lastShort = false;
   
   if(lastLong != hasLong || lastShort != hasShort)
   {
      Print("포지션 상태 변경 - Long: ", hasLong, ", Short: ", hasShort);
      lastLong = hasLong;
      lastShort = hasShort;
   }
}

//+------------------------------------------------------------------+
void OpenBuy(double sl = 0, double tp = 0)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // 스탑 레벨 확인 및 조정
   if(sl > 0)
   {
      double minSL = ask - minStopLevel * _Point;
      if(sl > minSL) sl = minSL;
   }
   
   if(tp > 0)
   {
      double maxTP = ask + minStopLevel * _Point;
      if(tp < maxTP) tp = maxTP;
   }
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = Lot;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
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
void OpenSell(double sl = 0, double tp = 0)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // 스탑 레벨 확인 및 조정
   if(sl > 0)
   {
      double minSL = bid + minStopLevel * _Point;
      if(sl < minSL) sl = minSL;
   }
   
   if(tp > 0)
   {
      double maxTP = bid - minStopLevel * _Point;
      if(tp > maxTP) tp = maxTP;
   }
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = Lot;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
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
void ManageTrailingStop()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      
      if(PositionGetInteger(POSITION_MAGIC) != Magic) continue;
      
      double currentSL = PositionGetDouble(POSITION_SL);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double currentTP = PositionGetDouble(POSITION_TP);
      
      // 최소 스탑 레벨 확인
      double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         double newSL = NormalizeDouble(currentPrice - TrailingStop * _Point, _Digits);
         
         // 새로운 손절가가 현재 손절가보다 높고, 진입가보다 높은 경우에만 수정
         if(newSL > currentSL + minDistance && newSL > openPrice)
         {
            if(ModifyPosition(ticket, newSL, currentTP))
               Print("트레일링 스탑 수정 - Buy SL: ", newSL);
         }
      }
      else // POSITION_TYPE_SELL
      {
         double newSL = NormalizeDouble(currentPrice + TrailingStop * _Point, _Digits);
         
         // 새로운 손절가가 현재 손절가보다 낮고, 진입가보다 낮은 경우에만 수정
         if((currentSL == 0 || newSL < currentSL - minDistance) && newSL < openPrice)
         {
            if(ModifyPosition(ticket, newSL, currentTP))
               Print("트레일링 스탑 수정 - Sell SL: ", newSL);
         }
      }
   }
}

//+------------------------------------------------------------------+
bool ModifyPosition(ulong ticket, double sl, double tp)
{
   if(!PositionSelectByTicket(ticket)) return false;
   
   // 최소 스탑 레벨 확인
   double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   
   // 스탑로스가 현재가와 너무 가까운지 확인
   if(MathAbs(currentPrice - sl) < minDistance)
      return false;
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_MODIFY;
   request.position = ticket;
   request.symbol = _Symbol;
   request.sl = NormalizeDouble(sl, _Digits);
   request.tp = NormalizeDouble(tp, _Digits);
   
   bool success = OrderSend(request, result);
   
   if(!success)
   {
      Print("ModifyPosition error: ", GetLastError());
      return false;
   }
   
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("ModifyPosition failed: ", result.retcode);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(lastBarTime == 0)  // 첫 실행시 초기화
   {
      lastBarTime = currentBarTime;
      return false;
   }
   
   if(currentBarTime > lastBarTime)  // 새로운 봉이 생성됨
   {
      lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

// 추세 전환 확인 함수 수정
int IsTrendChange()
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
bool IsFirstTickOfBar()
{
   datetime currentTickTime = TimeCurrent();     // 현재 틱의 시간
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);   // 현재 의 시작 시간
   
   // 첫 실행시 초기화
   if(lastTickTime == 0 || lastBarTime == 0)
   {
      lastTickTime = currentTickTime;
      lastBarTime = currentBarTime;
      return false;
   }
   
   // 새로운 봉이 생성되었고, 이 봉의 첫 틱인 ���우
   if(currentBarTime > lastBarTime && currentTickTime > lastTickTime)
   {
      lastBarTime = currentBarTime;
      lastTickTime = currentTickTime;
      return true;
   }
   
   // 틱 시간 업데이트
   lastTickTime = currentTickTime;
   return false;
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
   // 거래 추가된 경우만 처리
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   
   // 딜 티켓으로 거래 정보 가져오기
   ulong dealTicket = trans.deal;
   if(!HistoryDealSelect(dealTicket)) return;
   
   // 거래가 현재 EA의 것인지 확인
   if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != Magic) return;
   
   // 딜 정보 가져오기
   ulong posTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
   double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
   double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
   ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON);
   
   // 포지션 진입
   if(dealEntry == DEAL_ENTRY_IN)
   {
      string direction = (dealType == DEAL_TYPE_BUY) ? "매수" : "매도";
      Print("신규 포지션 ", direction, " 진입 - 가격: ", dealPrice, ", 수량: ", dealVolume);
      
      // 포지션 상태 업데이트
      if(dealType == DEAL_TYPE_BUY)
         hasLong = true;
      else
         hasShort = true;
   }
   // 포지션 청산
   else if(dealEntry == DEAL_ENTRY_OUT)
   {
      string reason = "";
      
      // 청산 사유 확인
      switch(dealReason)
      {
         case DEAL_REASON_SL:
            reason = "손절";
            break;
         case DEAL_REASON_TP:
            reason = "익절";
            break;
         case DEAL_REASON_CLIENT:
            reason = "EA 청산";
            break;
         default:
            reason = "기타";
      }
      
      string direction = (dealType == DEAL_TYPE_BUY) ? "매수" : "매도";
      Print("포지션 청산 [", reason, "] - ", direction, 
            ", 가격: ", dealPrice,
            ", 수량: ", dealVolume,
            ", 손익: ", dealProfit);
            
      // 청산 후 상태 업데이트
      if(dealType == DEAL_TYPE_BUY)
         hasLong = false;
      else
         hasShort = false;
   }
} 