#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'173,216,230'  // 얇은 파란색
#property indicator_color2  C'255,182,193'  // 얇은 빨간색

input int EMA_Period_1 = 5;   // EMA 기간 1
input int EMA_Period_2 = 20;  // EMA 기간 2
input int EMA_Period_3 = 40;  // EMA 기간 3

// 허용 오차 정의 (더 큰 값으로 설정)
input double EPSILON = 0.01;  // 허용 오차

input int AnglePeriod = 20;  // 각도 계산을 위한 기간을 20으로 늘림

double EMA1Buffer[];
double EMA2Buffer[];
double EMA3Buffer[];

int EMA1_handle;
int EMA2_handle;
int EMA3_handle;

int OnInit()
{
   SetIndexBuffer(0, EMA1Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, EMA2Buffer, INDICATOR_DATA);
   SetIndexBuffer(2, EMA3Buffer, INDICATOR_DATA);
   
   PlotIndexSetString(0, PLOT_LABEL, "EMA Zone " + IntegerToString(EMA_Period_1) + "/" + IntegerToString(EMA_Period_2) + "/" + IntegerToString(EMA_Period_3));
   
   EMA1_handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Period_1, 0, MODE_EMA, PRICE_CLOSE);
   EMA2_handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Period_2, 0, MODE_EMA, PRICE_CLOSE);
   EMA3_handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Period_3, 0, MODE_EMA, PRICE_CLOSE);
   
   if(EMA1_handle == INVALID_HANDLE || EMA2_handle == INVALID_HANDLE || EMA3_handle == INVALID_HANDLE)
   {
      Print("Error creating EMA indicator handles");
      return(INIT_FAILED);
   }
   
   // 추가: EMA 핸들 값과 기간 출력
   Print("EMA1_handle: ", EMA1_handle, " Period: ", EMA_Period_1);
   Print("EMA2_handle: ", EMA2_handle, " Period: ", EMA_Period_2);
   Print("EMA3_handle: ", EMA3_handle, " Period: ", EMA_Period_3);
   
   return(INIT_SUCCEEDED);
}

string DeterminePhase(double ema5, double ema20, double ema40)
{
   if(MathAbs(ema5 - ema20) < EPSILON && MathAbs(ema20 - ema40) < EPSILON && MathAbs(ema5 - ema40) < EPSILON)
      return "횡보";
   
   if(ema5 > ema20 + EPSILON && ema20 > ema40 + EPSILON) return "1국면";
   if(ema20 > ema5 + EPSILON && ema5 > ema40 + EPSILON) return "2국면";
   if(ema20 > ema40 + EPSILON && ema40 > ema5 + EPSILON) return "3국면";
   if(ema40 > ema20 + EPSILON && ema20 > ema5 + EPSILON) return "4국면";
   if(ema40 > ema5 + EPSILON && ema5 > ema20 + EPSILON) return "5국면";
   if(ema5 > ema40 + EPSILON && ema40 > ema20 + EPSILON) return "6국면";
   
   return "불명확";
}

// 각도 계산 함수 추가
double CalculateAngle(const double &values[], int period, int shift)
{
   if(ArraySize(values) < period + shift) return 0;
   
   double x_sum = 0, y_sum = 0, xy_sum = 0, x2_sum = 0;
   for(int i = 0; i < period; i++)
   {
      x_sum += i;
      y_sum += values[shift + i];
      xy_sum += i * values[shift + i];
      x2_sum += i * i;
   }
   
   double slope = (period * xy_sum - x_sum * y_sum) / (period * x2_sum - x_sum * x_sum);
   return MathArctan(slope) * 180 / M_PI;
}

// EMA 직접 계산 함수
double CalculateEMA(const double &price[], int period, int index)
{
   if(index < period - 1 || index >= ArraySize(price))
      return 0; // 유효하지 않은 인덱스

   double alpha = 2.0 / (period + 1);
   double ema = price[index - period + 1];
   
   for(int i = index - period + 2; i <= index; i++)
   {
      ema = price[i] * alpha + ema * (1 - alpha);
   }
   
   return ema;
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
   int start;
   if(prev_calculated == 0)
      start = MathMax(EMA_Period_3 - 1, 0); // 가장 긴 EMA 기간부터 시작
   else
      start = prev_calculated - 1;
   
   // 직접 EMA 계산
   for(int i = start; i < rates_total; i++)
   {
      EMA1Buffer[i] = CalculateEMA(close, EMA_Period_1, i);
      EMA2Buffer[i] = CalculateEMA(close, EMA_Period_2, i);
      EMA3Buffer[i] = CalculateEMA(close, EMA_Period_3, i);
   }
   
   int i = rates_total - 1;
   
   string phase = DeterminePhase(EMA1Buffer[i], EMA2Buffer[i], EMA3Buffer[i]);
   
   double angle5 = CalculateAngle(EMA1Buffer, AnglePeriod, i - AnglePeriod + 1);
   double angle20 = CalculateAngle(EMA2Buffer, AnglePeriod, i - AnglePeriod + 1);
   double angle40 = CalculateAngle(EMA3Buffer, AnglePeriod, i - AnglePeriod + 1);
   
   string trend;
   if(angle5 > 0 && angle20 > 0 && angle40 > 0)
      trend = "상승";
   else if(angle5 < 0 && angle20 < 0 && angle40 < 0)
      trend = "하락";
   else
      trend = "횡보";

   // 디버깅 출력 추가
   Print("Close price: ", close[i]);
   Print("현재 국면: ", phase);
   Print("현재 추세: ", trend);
   Print("각도 - EMA5: ", DoubleToString(angle5, 2), "° EMA20: ", DoubleToString(angle20, 2), "° EMA40: ", DoubleToString(angle40, 2), "°");
   
   // 추세 정보 표시 업데이트
   ObjectCreate(0, "TrendInfo", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "TrendInfo", OBJPROP_TEXT, "현재 추세: " + trend);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_COLOR, clrWhite);
   
   // 국면 정보 표시 업데이트
   ObjectCreate(0, "PhaseInfo", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "PhaseInfo", OBJPROP_TEXT, "현재 국면: " + phase);
   ObjectSetInteger(0, "PhaseInfo", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "PhaseInfo", OBJPROP_YDISTANCE, 40);
   ObjectSetInteger(0, "PhaseInfo", OBJPROP_COLOR, clrWhite);
   
   // 각도 정보 업데이트
   ObjectCreate(0, "AngleInfo", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "AngleInfo", OBJPROP_TEXT, StringFormat("각도 - EMA5: %.2f° EMA20: %.2f° EMA40: %.2f°", angle5, angle20, angle40));
   ObjectSetInteger(0, "AngleInfo", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "AngleInfo", OBJPROP_YDISTANCE, 60);
   ObjectSetInteger(0, "AngleInfo", OBJPROP_COLOR, clrWhite);
   
   // 직접 계산한 EMA 값 (더 많은 소수점 자리 표시)
   double calculatedEMA5 = CalculateEMA(close, EMA_Period_1, rates_total);
   double calculatedEMA20 = CalculateEMA(close, EMA_Period_2, rates_total);
   double calculatedEMA40 = CalculateEMA(close, EMA_Period_3, rates_total);
   
   Print("Calculated EMA5: ", DoubleToString(EMA1Buffer[i], 12),
         " EMA20: ", DoubleToString(EMA2Buffer[i], 12),
         " EMA40: ", DoubleToString(EMA3Buffer[i], 12));
   
   // iMA 함수로 계산된 EMA 값과 비교 (더 많은 소수점 자리 표시)
   Print("iMA EMA5: ", DoubleToString(EMA1Buffer[i], 12),
         " EMA20: ", DoubleToString(EMA2Buffer[i], 12),
         " EMA40: ", DoubleToString(EMA3Buffer[i], 12));
   
   // 디버깅 출력 추가
   Print("EMA5: ", DoubleToString(EMA1Buffer[i], 12));
   Print("EMA20: ", DoubleToString(EMA2Buffer[i], 12));
   Print("EMA40: ", DoubleToString(EMA3Buffer[i], 12));
   
   ChartRedraw();  // 차트를 강제로 다시 그립니다.
   
   return(rates_total);
}
