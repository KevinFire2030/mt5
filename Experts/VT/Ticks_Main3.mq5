//+------------------------------------------------------------------+
//|                                                 Ticks_Main3.mq5  |
//|                        Copyright 2023, Your Name                 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE

double tickCountBuffer[];
long initialTicks = 0;
datetime sessionStartTime;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // 세션 시작 시간 설정
   sessionStartTime = GetSessionStartTime();
   
   // 초기 틱 카운트 저장
   if(!SymbolInfoInteger(Symbol(), SYMBOL_SESSION_DEALS, initialTicks))
   {
      Print("Failed to get initial tick count");
      return INIT_FAILED;
   }
   
   SetIndexBuffer(0, tickCountBuffer, INDICATOR_DATA);
   
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
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Tick function                                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   long currentTicks = 0;
   if(!SymbolInfoInteger(Symbol(), SYMBOL_SESSION_DEALS, currentTicks))
   {
      Print("Failed to get current tick count");
      return;
   }
   
   long tickCount = currentTicks - initialTicks;
   
   string info = StringFormat("Session Start: %s\nTick Count: %lld", 
                              TimeToString(sessionStartTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                              tickCount);
   Comment(info);
}

//+------------------------------------------------------------------+
//| Get session start time                                           |
//+------------------------------------------------------------------+
datetime GetSessionStartTime()
{
   datetime from = 0, to = 0;
   datetime current_time = TimeCurrent();
   MqlDateTime time_struct;
   TimeToStruct(current_time, time_struct);
   
   // 현재 요일의 거래 세션 시작 시간 가져오기
   if(!SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)time_struct.day_of_week, 0, from, to))
   {
      Print("Failed to get trading session time for ", Symbol());
      return current_time; // 실패 시 현재 시간 반환
   }
   
   if(from == 0)
   {
      Print("Trading session start time is not set for ", Symbol());
      return current_time; // 실패 시 현재 시간 반환
   }
   
   MqlDateTime struct_current, struct_from;
   TimeToStruct(current_time, struct_current);
   TimeToStruct(from, struct_from);
   
   // 현재 날짜와 거래 세션 시작 시간을 조합
   struct_current.hour = struct_from.hour;
   struct_current.min = struct_from.min;
   struct_current.sec = struct_from.sec;
   
   return StructToTime(struct_current);
}
