//+------------------------------------------------------------------+
//|                                                 Hull_Moving_Average.mq5 |
//|                                                           jnr314 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "jnr314"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2

//--- plot HMA
#property indicator_label1  "HMA_Diff"
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrBlack
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "HMA"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrLime,clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- input parameters
input int                HMAPeriod=13;           // Period
input int                HMAShift=0;             // Shift
input ENUM_MA_METHOD     InpMAMethod=MODE_LWMA;  // Method
input ENUM_APPLIED_PRICE InpMAPrice=PRICE_TYPICAL; // Price

//--- indicator buffers
double    HMABuffer[];
double    ExtSignalBuffer[];
double    ColorBuffer[];

//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   SetIndexBuffer(0,HMABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
   
   //--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,HMAPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,HMAPeriod);
   
   //--- sets indicator shift
   PlotIndexSetInteger(0,PLOT_SHIFT,HMAShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,HMAShift);
   
   //--- name for DataWindow and indicator subwindow label
   string short_name="Hull Moving Average("+string(HMAPeriod)+","+string(HMAShift)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
   //--- check for input parameters
   if(HMAPeriod<=1)
   {
      Print("Wrong input parameters");
      return(INIT_FAILED);
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
double iMAOnArray(double &array[],int total,int period,int ma_shift,int ma_method,int shift)
{
   double buf[],arr[];
   if(total==0) total=ArraySize(array);
   if(total>0 && total<=period) return(0);
   
   if(shift>total-period-ma_shift) return(0);
   
   switch(ma_method)
   {
      case MODE_SMA:
      {
         double sum=0;
         for(int i=0; i<period; i++) sum+=array[shift+i];
         return(sum/period);
      }
      case MODE_LWMA:
      {
         double sum=0;
         double weight=0;
         for(int i=0; i<period; i++)
         {
            sum+=array[shift+i]*(period-i);
            weight+=(period-i);
         }
         return(sum/weight);
      }
      // 다른 MA 방식들도 필요하다면 추가 가능
   }
   return(0);
}

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
   if(rates_total<=HMAPeriod) return(0);
   
   int limit;
   if(prev_calculated==0)
      limit=rates_total-HMAPeriod-1;
   else
      limit=rates_total-prev_calculated;
   
   ArraySetAsSeries(HMABuffer,true);
   ArraySetAsSeries(ExtSignalBuffer,true);
   ArraySetAsSeries(ColorBuffer,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   
   int p = (int)MathFloor(MathSqrt(HMAPeriod));
   int medp = (int)MathFloor(HMAPeriod/2);
   
   double price[];
   ArrayResize(price,rates_total);
   ArraySetAsSeries(price,true);
   
   //--- get price data
   for(int i=0; i<rates_total; i++)
   {
      switch(InpMAPrice)
      {
         case PRICE_CLOSE:  price[i]=close[i]; break;
         case PRICE_OPEN:   price[i]=open[i]; break;
         case PRICE_HIGH:   price[i]=high[i]; break;
         case PRICE_LOW:    price[i]=low[i]; break;
         case PRICE_MEDIAN: price[i]=(high[i]+low[i])/2.0; break;
         case PRICE_TYPICAL: price[i]=(high[i]+low[i]+close[i])/3.0; break;
         case PRICE_WEIGHTED: price[i]=(high[i]+low[i]+close[i]+close[i])/4.0; break;
      }
   }
   
   //--- hull moving average calculation
   for(int i=limit; i>=0; i--)
   {
      //--- first buffer
      HMABuffer[i]=2*iMAOnArray(price,0,medp,0,InpMAMethod,i)
                   -iMAOnArray(price,0,HMAPeriod,0,InpMAMethod,i);
                   
      //--- second buffer
      if(i<=rates_total-p)
      {
         double sum=0;
         double weight=0;
         for(int j=0; j<p; j++)
         {
            sum+=HMABuffer[i+j]*(p-j);
            weight+=(p-j);
         }
         ExtSignalBuffer[i]=sum/weight;
         
         //--- 색상 설정
         if(i < rates_total-1)
         {
            ColorBuffer[i] = ExtSignalBuffer[i] > ExtSignalBuffer[i+1] ? 0 : 1;  // 상승이면 녹색(0), 하락이면 적색(1)
         }
      }
   }
   
   return(rates_total);
}