//+------------------------------------------------------------------+
//|                                                          vt.mq5 |
//|                        Copyright 2024, Your Name                |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| 유동성과 변동성을 계산하고 출력하는 함수                          |
//+------------------------------------------------------------------+
void CalculateAndPrintLiquidityVolatility(string symbol, int period = PERIOD_M1, int bars = 60)
{
   double volume[];
   double close[];
   
   ArraySetAsSeries(volume, true);
   ArraySetAsSeries(close, true);
   
   // 거래량과 종가 데이터 가져오기
   int copied_volume = CopyTickVolume(symbol, period, 0, bars, volume);
   int copied_close = CopyClose(symbol, period, 0, bars, close);
   
   if(copied_volume != bars || copied_close != bars)
   {
      Print("데이터를 가져오는 데 실패했습니다.");
      return;
   }
   
   // 유동성 계산 (평균 거래량)
   double avg_volume = 0;
   for(int i = 0; i < bars; i++)
   {
      avg_volume += volume[i];
   }
   avg_volume /= bars;
   
   // 변동성 계산 (60분 동안의 가격 변동 범위)
   double high = close[ArrayMaximum(close, 0, bars)];
   double low = close[ArrayMinimum(close, 0, bars)];
   double volatility = (high - low) / low * 100; // 백분율로 표시
   
   // 결과 출력
   Print("심볼: ", symbol);
   Print("기간: 최근 60분 (1분봉 기준)");
   Print("평균 거래량 (유동성): ", DoubleToString(avg_volume, 2));
   Print("60분 변동성: ", DoubleToString(volatility, 2), "%");
}

//+------------------------------------------------------------------+
//| 스크립트 프로그램 시작 함수                                        |
//+------------------------------------------------------------------+
void OnStart()
{
   string symbols[] = {"EURUSD", "GBPUSD", "USDJPY", "AUDUSD"}; // 분석할 심볼 목록
   
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      CalculateAndPrintLiquidityVolatility(symbols[i]);
      Print("------------------------");
   }
}
