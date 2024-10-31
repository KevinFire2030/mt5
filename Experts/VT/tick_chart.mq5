#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property strict

input int InpTicksPerBar = 100; // 캔들당 틱 수

int tickCount = 0;
double openPrice, highPrice, lowPrice, closePrice;
datetime lastBarTime;

int tickChartHandle;

int OnInit()
{
   tickChartHandle = iCustom(_Symbol, PERIOD_CURRENT, "Examples\\Tick_Chart", InpTicksPerBar);
   if(tickChartHandle == INVALID_HANDLE)
   {
      Print("Failed to create Tick Chart indicator: ", GetLastError());
      return INIT_FAILED;
   }
   
   Print("OnInit called. Tick chart EA initialized.");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(tickChartHandle != INVALID_HANDLE)
      IndicatorRelease(tickChartHandle);
   Print("OnDeinit called. Reason: ", reason);
}

void OnTick()
{
   MqlTick last_tick;
   if(SymbolInfoTick(_Symbol, last_tick))
   {
      if(tickCount == 0)
      {
         openPrice = last_tick.ask;
         highPrice = last_tick.ask;
         lowPrice = last_tick.bid;
         lastBarTime = TimeCurrent();
      }
      else
      {
         highPrice = MathMax(highPrice, last_tick.ask);
         lowPrice = MathMin(lowPrice, last_tick.bid);
      }
      
      closePrice = last_tick.ask;
      tickCount++;
      
      if(tickCount >= InpTicksPerBar)
      {
         // Send data to indicator
         MqlRates rates;
         rates.time = lastBarTime;
         rates.open = openPrice;
         rates.high = highPrice;
         rates.low = lowPrice;
         rates.close = closePrice;
         rates.tick_volume = InpTicksPerBar;
         rates.spread = 0;
         rates.real_volume = 0;
         
         if(!CustomRatesUpdate(_Symbol, rates))
         {
            Print("Failed to update custom rates: ", GetLastError());
         }
         
         Print("New candle data sent. Time: ", TimeToString(lastBarTime), ", Open: ", openPrice, ", High: ", highPrice, ", Low: ", lowPrice, ", Close: ", closePrice);
         
         tickCount = 0;
      }
   }
}
