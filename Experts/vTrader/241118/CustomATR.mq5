//+------------------------------------------------------------------+
//|                                                    CustomATR.mq5   |
//|                             Copyright 2000-2024, MetaQuotes Ltd.   |
//|                                             https://www.mql5.com   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2024, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "Average True Range with EMA"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  DodgerBlue
#property indicator_label1  "ATR(EMA)"

//--- input parameters
input int InpAtrPeriod = 14;  // ATR period

//--- indicator buffers
double    ExtATRBuffer[];
double    ExtTRBuffer[];
int       ExtPeriodATR;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                           |
//+------------------------------------------------------------------+
void OnInit()
{
   // 입력값 검증
   if(InpAtrPeriod <= 0)
   {
      ExtPeriodATR = 14;
      PrintFormat("Incorrect input parameter InpAtrPeriod = %d. Indicator will use value %d for calculations.",
                 InpAtrPeriod, ExtPeriodATR);
   }
   else
      ExtPeriodATR = InpAtrPeriod;

   // 버퍼 매핑
   SetIndexBuffer(0, ExtATRBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtTRBuffer, INDICATOR_CALCULATIONS);

   // 지표 설정
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ExtPeriodATR);

   // 지표 이름 설정
   string short_name = StringFormat("ATR_EMA(%d)", ExtPeriodATR);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   PlotIndexSetString(0, PLOT_LABEL, short_name);
}

//+------------------------------------------------------------------+
//| EMA 계산 함수                                                      |
//+------------------------------------------------------------------+
double CalculateEMA(const double &price, const double &prev_ema, const int period)
{
   double alpha = 2.0 / (period + 1.0);
   return price * alpha + prev_ema * (1.0 - alpha);
}

//+------------------------------------------------------------------+
//| True Range 계산 함수                                               |
//+------------------------------------------------------------------+
double CalculateTR(const double high, const double low, const double close_prev)
{
   double tr1 = high - low;                    // 당일 범위
   double tr2 = MathAbs(high - close_prev);    // 전일 종가 대비 고가
   double tr3 = MathAbs(low - close_prev);     // 전일 종가 대비 저가
   
   return MathMax(tr1, MathMax(tr2, tr3));     // 세 값 중 최대값
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                                |
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
   if(rates_total <= ExtPeriodATR)
      return(0);

   int i, start;

   // 초기 계산
   if(prev_calculated == 0)
   {
      ExtTRBuffer[0] = 0.0;
      ExtATRBuffer[0] = 0.0;

      // TR 값 계산
      for(i = 1; i < rates_total && !IsStopped(); i++)
         ExtTRBuffer[i] = CalculateTR(high[i], low[i], close[i-1]);

      // 첫 ATR 값 계산 (단순평균)
      double firstValue = 0.0;
      for(i = 1; i <= ExtPeriodATR; i++)
      {
         ExtATRBuffer[i] = 0.0;
         firstValue += ExtTRBuffer[i];
      }
      firstValue /= ExtPeriodATR;
      ExtATRBuffer[ExtPeriodATR] = firstValue;
      start = ExtPeriodATR + 1;
   }
   else
      start = prev_calculated - 1;

   // 메인 계산 루프
   for(i = start; i < rates_total && !IsStopped(); i++)
   {
      // TR 계산
      ExtTRBuffer[i] = CalculateTR(high[i], low[i], close[i-1]);
      
      // EMA를 사용한 ATR 계산
      ExtATRBuffer[i] = CalculateEMA(ExtTRBuffer[i], ExtATRBuffer[i-1], ExtPeriodATR);
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
