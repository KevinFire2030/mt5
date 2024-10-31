//+------------------------------------------------------------------+
//|                                                         HMA.mq5 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

//--- plot HMA
#property indicator_label1  "HMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- input parameters
input int      InpPeriod=14;        // Period
input ENUM_APPLIED_PRICE InpPrice=PRICE_CLOSE; // Applied Price

//--- indicator buffers
double         HMABuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,HMABuffer,INDICATOR_DATA);
   
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
//--- set indicator name
   string short_name=StringFormat("HMA(%d)",InpPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
//--- set first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
   
//---
   return(INIT_SUCCEEDED);
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
   if(rates_total < InpPeriod)
      return(0);
      
   int start;
   if(prev_calculated == 0)
      start = InpPeriod - 1;
   else
      start = prev_calculated - 1;
   
   int handle_wma1 = iMA(_Symbol, PERIOD_CURRENT, InpPeriod / 2, 0, MODE_LWMA, InpPrice);
   int handle_wma2 = iMA(_Symbol, PERIOD_CURRENT, InpPeriod, 0, MODE_LWMA, InpPrice);
   
   if(handle_wma1 == INVALID_HANDLE || handle_wma2 == INVALID_HANDLE)
     {
      Print("지표 핸들 생성 실패");
      return(0);
     }
   
   double wma1_buffer[], wma2_buffer[], diff_buffer[];
   ArraySetAsSeries(wma1_buffer, true);
   ArraySetAsSeries(wma2_buffer, true);
   ArraySetAsSeries(diff_buffer, true);
   
   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      if(CopyBuffer(handle_wma1, 0, i, 1, wma1_buffer) <= 0) continue;
      if(CopyBuffer(handle_wma2, 0, i, 1, wma2_buffer) <= 0) continue;
      
      double wma1 = wma1_buffer[0];
      double wma2 = wma2_buffer[0];
      double diff = 2 * wma1 - wma2;
      
      diff_buffer[0] = diff;
      if(CopyBuffer(handle_hma, 0, i, 1, HMABuffer) <= 0) continue;
     }
   
   IndicatorRelease(handle_wma1);
   IndicatorRelease(handle_wma2);
   IndicatorRelease(handle_hma);
   
   return(rates_total);
  }
//+------------------------------------------------------------------+
