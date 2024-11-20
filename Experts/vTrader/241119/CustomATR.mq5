//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "ATR"

//--- input parameters
input int ATR_Period = 20;  // ATR period

//--- indicator buffers
double ATRBuffer[];

int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ATRBuffer,INDICATOR_DATA);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- name for DataWindow and indicator subwindow label
   string short_name=StringFormat("ATR(%d)",ATR_Period);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Average True Range                                               |
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
   if(rates_total < ATR_Period) return(0);

   int start;

   if(prev_calculated == 0)
     {
      double sum = 0;
      for(int i = 1; i < ATR_Period + 1; i++)
         sum += TrueRange(high, low, close, i);
            
      ATRBuffer[ATR_Period] = sum / ATR_Period;
      start = ATR_Period + 1;
     }
   else
      start = prev_calculated - 1;

   for(int i = start; i < rates_total; i++)
     {
      double tr = TrueRange(high, low, close, i);
      ATRBuffer[i] = ((ATR_Period-1) * ATRBuffer[i-1] + tr * 2) / (ATR_Period + 1);
     }

   return(rates_total);
   
  }

  //+------------------------------------------------------------------+
//| True Range 계산 함수                                               |
//+------------------------------------------------------------------+
double TrueRange(const double &high[], const double &low[], const double &close[], int pos)
{
    double tr = high[pos] - low[pos];
    if(pos > 0)
    {
        double tr1 = MathAbs(high[pos] - close[pos-1]);
        double tr2 = MathAbs(low[pos] - close[pos-1]);
        tr = MathMax(tr, MathMax(tr1, tr2));
    }
    return tr;
}