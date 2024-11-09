// ... 기존 코드 ...

//+------------------------------------------------------------------+
//| Function to print last 100 ticks with all details                |
//+------------------------------------------------------------------+
void PrintHistoricalTicks()
  {
   MqlTick ticks[];
   int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 100);
   
   if(copied > 0)
     {
      Print("최근 100개의 틱 데이터:");
      for(int i = 0; i < copied; i++)
        {
         string time_with_milliseconds = TimeToString(ticks[i].time, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + "." + IntegerToString(ticks[i].time_msc % 1000, 3, '0');
         Print("시간: ", time_with_milliseconds,
               " 매수호가: ", ticks[i].bid,
               " 매도호가: ", ticks[i].ask,
               " 마지막 거래 가격: ", ticks[i].last,
               " 거래량: ", ticks[i].volume,
               " 실거래량: ", ticks[i].volume_real,
               " 플래그: ", ticks[i].flags);
        }
     }
   else
     {
      Print("틱 데이터를 가져오지 못했습니다.");
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 초기화 코드 작성
   Print("EA 초기화 완료");
   
   // 과거 틱 데이터 출력 함수 호출
   PrintHistoricalTicks();
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // 종료 시 실행할 코드 작성
   Print("EA 종료: 이유 코드 ", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 매 틱마다 실행할 코드 작성
   //Print("새로운 틱 발생");
  }
//+------------------------------------------------------------------+

// ... 기존 코드 ...
