//
// Ticks-Main.mq5
// Based on Seconds-Main.mq5 by getYourNet.ch
//

#property copyright "Copyright 2023, Your Name"
#property link      "http://www.yourwebsite.com"
#property version   "1.00"
#property description "Press the key 'T' to toggle the tick chart."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1 "Bid"
#property indicator_label2 "Ask"
#property indicator_color1  clrBlue
#property indicator_color2  clrRed

enum TickIntervals
{
   T1 = 1,    // 1 Tick
   T5 = 5,    // 5 Ticks
   T10 = 10,  // 10 Ticks
   T20 = 20,  // 20 Ticks
   T50 = 50,  // 50 Ticks
   T100 = 100 // 100 Ticks
};

input int MaxBars = 500; // Maximum Bars
input string Font = "Arial";
input int FontSize = 10; // Font Size
input color Color = clrGray;
input color ColorSelected = clrBlack; // Color Selected
input int MarginX = 10; // Left Margin
input int MarginY = 10; // Bottom Margin

double bid[], ask[];
bool init, historyloaded, visible;
datetime lasttime, time0;
TickIntervals Ticks;
int currentTicks;
string appnamespace = "TicksChartIndicator";

// ... (기타 전역 변수 및 구조체 정의)

void OnInit()
{
   init = true;
   historyloaded = false;
   visible = false;
   lasttime = 0;
   time0 = 0;
   Ticks = T10;
   currentTicks = T10;
   
   SetIndexBuffer(0, bid, INDICATOR_DATA);
   SetIndexBuffer(1, ask, INDICATOR_DATA);
   
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);

   IndicatorSetString(INDICATOR_SHORTNAME, "Ticks Chart");

   if(GlobalVariableCheck(appnamespace + IntegerToString(ChartID()) + "Ticks"))
      Ticks = (TickIntervals)GlobalVariableGet(appnamespace + IntegerToString(ChartID()) + "Ticks");

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   EventSetMillisecondTimer(1);
}

// ... (OnDeinit, SetIndicatorView 함수 등)

void LoadHistoryTicks()
{
   MqlTick ticks[];
   int received = CopyTicks(Symbol(), ticks, COPY_TICKS_ALL, 0, MaxBars * (int)Ticks);
   
   if(received > 0)
   {
      ArraySetAsSeries(ticks, true);
      ArrayResize(bid, MaxBars);
      ArrayResize(ask, MaxBars);
      
      int tickCounter = 0;
      int barIndex = MaxBars - 1;
      
      for(int i = 0; i < received && barIndex >= 0; i++)
      {
         if(tickCounter == 0)
         {
            bid[barIndex] = ticks[i].bid;
            ask[barIndex] = ticks[i].ask;
         }
         
         tickCounter++;
         
         if(tickCounter >= Ticks)
         {
            barIndex--;
            tickCounter = 0;
         }
      }
      
      historyloaded = true;
   }
}

void OnTimer()
{
   if(init || TimeTradeServer() < time0)
      return;

   if(!historyloaded)
   {
      LoadHistoryTicks();
   }

   // 실시간 업데이트 로직
   MqlTick last_tick;
   if(SymbolInfoTick(Symbol(), last_tick))
   {
      ShiftBuffers();
      bid[MaxBars-1] = last_tick.bid;
      ask[MaxBars-1] = last_tick.ask;
   }
}

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
   if(rates_total > 0)
   {
      int i = rates_total - 1;
      time0 = time[i];

      if(!init && historyloaded)
      {
         MqlTick last_tick;
         SymbolInfoTick(Symbol(), last_tick);
         
         ShiftBuffers();
         bid[MaxBars-1] = last_tick.bid;
         ask[MaxBars-1] = last_tick.ask;
      }

      if(init)
      {
         init = false;
      }
   }

   return(rates_total);
}

void ShiftBuffers()
{
   for(int i = 0; i < MaxBars - 1; i++)
   {
      bid[i] = bid[i+1];
      ask[i] = ask[i+1];
   }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id == CHARTEVENT_KEYDOWN)
   {
      if(lparam == 84) // Key T
      {
         if(!visible)
            Enable();
         else
            Disable();
         visible = !visible;
      }
   }

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      int f1 = StringFind(sparam, "TCButton");
      if(f1 > -1)
      {
         Ticks = (TickIntervals)StringToInteger(StringSubstr(sparam, f1 + 8));
         historyloaded = false;
         DeleteButtons();
         CreateButtons();
      }
   }
}

void Enable()
{
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   CreateButtons();
}

void Disable()
{
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   DeleteButtons();
}

void CreateButtons()
{
   for(int i = 0; i < 6; i++)
   {
      string text = "T" + IntegerToString(TickIntervals(MathPow(2, i)));
      CreateButton(i, text, (Ticks == TickIntervals(MathPow(2, i))));
   }
}

void CreateButton(int index, string text, bool selected = false)
{
   string objname = appnamespace + "TCButton" + IntegerToString(index);
   ObjectCreate(0, objname, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objname, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, objname, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   int space = (index + 1) * 25;
   ObjectSetInteger(0, objname, OBJPROP_XDISTANCE, MarginX + space);
   ObjectSetInteger(0, objname, OBJPROP_YDISTANCE, MarginY);
   color c = Color;
   if(selected)
      c = ColorSelected;
   ObjectSetInteger(0, objname, OBJPROP_COLOR, c);
   ObjectSetInteger(0, objname, OBJPROP_FONTSIZE, FontSize);
   ObjectSetString(0, objname, OBJPROP_FONT, Font);
   ObjectSetString(0, objname, OBJPROP_TEXT, text);
}

void DeleteButtons()
{
   ObjectsDeleteAll(0, appnamespace + "TCButton");
}
