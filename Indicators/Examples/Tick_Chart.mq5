#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1

input int InpTicksPerBar = 100; // 캔들당 틱 수

double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];

int OnInit()
{
   SetIndexBuffer(0, OpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, CloseBuffer, INDICATOR_DATA);
   
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_CANDLES);
   PlotIndexSetString(0, PLOT_LABEL, "Tick Chart");
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Tick Chart (" + IntegerToString(InpTicksPerBar) + " ticks)");
   
   return(INIT_SUCCEEDED);
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
   MqlRates rates[];
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, rates_total, rates);
   if(copied <= 0)
   {
      Print("Failed to copy rates: ", GetLastError());
      return(0);
   }
   
   for(int i = 0; i < copied; i++)
   {
      OpenBuffer[i] = rates[i].open;
      HighBuffer[i] = rates[i].high;
      LowBuffer[i] = rates[i].low;
      CloseBuffer[i] = rates[i].close;
   }
   
   return(rates_total);
}
