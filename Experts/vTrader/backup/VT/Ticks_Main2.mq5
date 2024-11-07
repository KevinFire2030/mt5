//+------------------------------------------------------------------+
//|                                                  Ticks_Main2.mq5 |
//|                                  Copyright 2023, Your Name Here  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Name Here"
#property link      "https://www.mql5.com"
#property version   "1.10"
#property indicator_chart_window

long initialDeals = 0;
datetime marketOpenTime;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // 현재 거래일의 장 시작 시간 가져오기
   marketOpenTime = GetMarketOpenTime();
   
   // 초기 거래 수 저장
   initialDeals = SymbolInfoInteger(Symbol(), SYMBOL_SESSION_DEALS);
   if(initialDeals == -1)
   {
      Print("Failed to get initial deals count");
      return INIT_FAILED;
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment(""); // 차트에서 코멘트 제거
}

//+------------------------------------------------------------------+
//| Tick function                                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   UpdateInfo();
}

//+------------------------------------------------------------------+
//| Update info with current deals count and market open time        |
//+------------------------------------------------------------------+
void UpdateInfo()
{
   long currentDeals = SymbolInfoInteger(Symbol(), SYMBOL_SESSION_DEALS);
   if(currentDeals == -1)
   {
      Print("Failed to get current deals count");
      return;
   }
   
   long dealsDifference = currentDeals - initialDeals;
   
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   
   string info = StringFormat("Market Open Time: %s\nDeals Count: %lld\nDeals Difference: %lld\nBid: %f\nAsk: %f\nTime: %s", 
                              TimeToString(marketOpenTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                              currentDeals,
                              dealsDifference,
                              last_tick.bid,
                              last_tick.ask,
                              TimeToString(last_tick.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
   Comment(info);
}

//+------------------------------------------------------------------+
//| Get market open time for the current trading day                 |
//+------------------------------------------------------------------+
datetime GetMarketOpenTime()
{
   datetime from = 0, to = 0;
   datetime current_time = TimeCurrent();
   MqlDateTime struct_current_time;
   TimeToStruct(current_time, struct_current_time);
   
   // 현재 요일 가져오기
   ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK)struct_current_time.day_of_week;
   
   Print("Checking trading sessions for ", EnumToString(day_of_week));
   
   // 모든 거래 세션을 확인
   for(int session = 0; session < 7; session++)
   {
      if(SymbolInfoSessionTrade(Symbol(), day_of_week, session, from, to))
      {
         Print("Session ", session, ": From ", TimeToString(from), " To ", TimeToString(to));
         if(from != 0 && (from < to || to == 0))
         {
            Print("Valid session found: From ", TimeToString(from), " To ", TimeToString(to));
            break; // 유효한 거래 세션을 찾음
         }
      }
      else
      {
         Print("No session info for session ", session);
      }
   }
   
   if(from == 0)
   {
      Print("Trading session start time is not set for ", Symbol(), ". Using default time.");
      // 기본값으로 09:00:00 설정
      struct_current_time.hour = 9;
      struct_current_time.min = 0;
      struct_current_time.sec = 0;
   }
   else
   {
      MqlDateTime struct_from;
      TimeToStruct(from, struct_from);
      
      // 현재 날짜와 거래 세션 시작 시간을 조합
      struct_current_time.hour = struct_from.hour;
      struct_current_time.min = struct_from.min;
      struct_current_time.sec = struct_from.sec;
   }
   
   datetime result = StructToTime(struct_current_time);
   Print("Market open time set to: ", TimeToString(result));
   return result;
}
