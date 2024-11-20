//+------------------------------------------------------------------+
//|                                           ZeroLagTrendSignals.mq5 |
//|                                                          AlgoAlpha |
//+------------------------------------------------------------------+
#property copyright "AlgoAlpha"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Zero Lag Trend Signals"

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   4

// ZLEMA 라인
#property indicator_label1  "Zero Lag"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLime,clrRed     // 상승/하락 색상
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// 상단 밴드 (하락 트렌드에서만 표시)
#property indicator_label2  "Upper Band"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

// 하단 밴드 (상승 트렌드에서만 표시)
#property indicator_label3  "Lower Band"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLime
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

// 입력 파라미터
input int    InpPeriod=120;          // Period
input double InpMultiplier=0.5;      // Band Multiplier

// 버퍼
double       ZLBuffer[];       // ZLEMA
double       ColorBuffer[];    // ZLEMA 색상
double       UpperBuffer[];    // 상단 밴드
double       LowerBuffer[];    // 하단 밴드
double       TrendBuffer[];    // 트렌드 방향
double       VolatilityBuffer[]; // ATR 기반 변동성

//+------------------------------------------------------------------+
void OnInit()
{
   // 버퍼 매핑
   SetIndexBuffer(0, ZLBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, UpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LowerBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, TrendBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, VolatilityBuffer, INDICATOR_CALCULATIONS);
   
   // 플롯 시작점 설정
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, InpPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, InpPeriod);
   
   // 빈 값 설정
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   
   // 지표 이름
   IndicatorSetString(INDICATOR_SHORTNAME, "Zero Lag Trend Signals");
   
   // 소수점 자리수
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits+1);
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
   if(rates_total < InpPeriod) return(0);
   
   int start;
   if(prev_calculated == 0) 
   {
      start = InpPeriod;
      ArrayInitialize(ZLBuffer, 0);
      ArrayInitialize(ColorBuffer, 0);
      ArrayInitialize(UpperBuffer, 0);
      ArrayInitialize(LowerBuffer, 0);
      ArrayInitialize(TrendBuffer, 0);
      ArrayInitialize(VolatilityBuffer, 0);
   }
   else start = prev_calculated - 1;
   
   int lag = (int)MathFloor((InpPeriod - 1) / 2);
   
   for(int i = start; i < rates_total; i++)
   {
      // Zero-Lag EMA 계산
      if(i >= lag)
      {
         double src = close[i];
         double lag_price = close[i - lag];
         ZLBuffer[i] = SimpleMA(i, InpPeriod, close) + (src - lag_price);
         
         // ATR 기반 변동성 계산
         double atr = 0;
         for(int j = 0; j < InpPeriod && (i-j) >= 1; j++)
         {
            double curr_atr = MathMax(high[i-j] - low[i-j],
                             MathMax(MathAbs(high[i-j] - close[i-j-1]),
                                    MathAbs(low[i-j] - close[i-j-1])));
            atr = MathMax(atr, curr_atr);
         }
         VolatilityBuffer[i] = atr * InpMultiplier;
         
         // 트렌드 계산
         if(i > 0)
         {
            if(close[i] > ZLBuffer[i] + VolatilityBuffer[i])
               TrendBuffer[i] = 1;
            else if(close[i] < ZLBuffer[i] - VolatilityBuffer[i])
               TrendBuffer[i] = -1;
            else
               TrendBuffer[i] = TrendBuffer[i-1];
         }
         
         // 밴드 계산 - 트렌드에 따라 표시
         if(TrendBuffer[i] == -1)  // 하락 트렌드
         {
            UpperBuffer[i] = ZLBuffer[i] + VolatilityBuffer[i];
            LowerBuffer[i] = 0;  // 하단 밴드 숨김
         }
         else if(TrendBuffer[i] == 1)  // 상승 트렌드
         {
            UpperBuffer[i] = 0;  // 상단 밴드 숨김
            LowerBuffer[i] = ZLBuffer[i] - VolatilityBuffer[i];
         }
         else  // 트렌드 없음
         {
            UpperBuffer[i] = 0;
            LowerBuffer[i] = 0;
         }
         
         // ZLEMA 색상 설정
         ColorBuffer[i] = TrendBuffer[i] == 1 ? 0 : 1;  // 0=녹색, 1=빨간색
      }
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
double SimpleMA(const int position, const int period, const double &price[])
{
   double sum = 0.0;
   for(int i = 0; i < period && (position-i) >= 0; i++)
      sum += price[position-i];
   return(sum/period);
} 