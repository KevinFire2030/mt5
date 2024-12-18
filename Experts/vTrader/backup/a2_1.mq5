#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property strict

#include <JAson.mqh>
#include <Trade\Trade.mqh>

CTrade trade;

input int Minutes = 1; // 실행 간격 (분)

datetime lastRunTime = 0; // 마지막 실행 시간

// OnTick 함수
void OnTick()
{
   datetime currentTime = TimeCurrent();
   
   // 설정된 분 간격으로 실행
   if (currentTime >= lastRunTime + Minutes * 60)
   {
      lastRunTime = currentTime;

      double totalProfit = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetString(POSITION_SYMBOL) == "BITCOIN")
            {
               totalProfit += PositionGetDouble(POSITION_PROFIT);
            }
         }
      }
      Print("현재 BITCOIN의 총 손익: ", totalProfit);
      if(totalProfit > 50 || totalProfit < -30)
      {
         Print("현재 BITCOIN의 총 손익이 50$를 넘거나 -30$를 넘었습니다. 총 손익: ", totalProfit);
         ClosePositionsBySymbol("BITCOIN");
      }
      
      // 차트 데이터 가져오기
      string chartData = GetChartData();
      
      // AI에 차트 데이터 분석 요청
      AnalyzeChartData(chartData);
   }
}

// 모든 포지션을 닫는 함수
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         trade.PositionClose(ticket);
      }
   }
}

// 특정 심볼의 모든 포지션을 닫는 함수
void ClosePositionsBySymbol(string symbol)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == symbol)
      {
         trade.PositionClose(ticket);
      }
   }
}

// 차트 데이터를 가져오는 함수
string GetChartData()
{
   string symbol = "BITCOIN";
   ENUM_TIMEFRAMES timeframe = PERIOD_M1;  // 1분봉
   int bars_to_retrieve = 30;  // 가져올 봉의 개수
   
   MqlRates rates[];  // 차트 데이터를 저장할 배열
   
   ArraySetAsSeries(rates, true);
   
   int copied = CopyRates(symbol, timeframe, 0, bars_to_retrieve, rates);
   
   if(copied == bars_to_retrieve)
   {
      Print("성공적으로 ", bars_to_retrieve, "개의 봉을 가져왔습니다.");
      
      string chartData = "";
      for(int i = 0; i < bars_to_retrieve; i++)
      {
         chartData += StringFormat("%s,%.2f,%.2f,%.2f,%.2f,%.0f;",
                     TimeToString(rates[i].time),
                     rates[i].open,
                     rates[i].high,
                     rates[i].low,
                     rates[i].close,
                     rates[i].tick_volume);
      }
      return chartData;
   }
   else
   {
      PrintFormat("차트 데이터를 가져오는데 실패했습니다. 오류 코드: %d", GetLastError());
      return "";
   }
}

// AI에 차트 데이터 분석을 요청하는 함수
void AnalyzeChartData(string chartData)
{
   string url = "http://127.0.0.1:5000/analyze";
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   
   string postData = "chartData=" + chartData;
   uchar data[];
   StringToCharArray(postData, data, 0, StringLen(postData), CP_UTF8);
   
   uchar result[];
   string resultHeaders;
   
   int res = WebRequest("POST", url, headers, 5000, data, result, resultHeaders);
   
   if(res == -1)
   {
      Print("WebRequest 오류 발생. 오류 코드: ", GetLastError());
      // MessageBox 제거 (EA에서는 사용 불가)
   }
   else
   {
      if(res == 200)
      {
         string response = CharArrayToString(result);
         Print("서버 응답: ", response);
         
         CJAVal json;
         if(json.Deserialize(response))
         {
            string decision = json["decision"].ToStr();
            string reason = json["reason"].ToStr();
            Print("트레이딩 결정: ", decision);
            Print("결정 이유: ", reason);
            
            // AI 결정에 따른 주문 실행
            ExecuteTradeDecision(decision);
         }
         else
         {
            Print("JSON 파싱 실패. 응답: ", response);
         }
      }
      else
      {
         string errorResponse = CharArrayToString(result);
         PrintFormat("'%s' 요청 실패, 오류 코드 %d. 응답: %s", url, res, errorResponse);
      }
   }
}

// AI 결정에 따라 주문을 실행하는 함수
void ExecuteTradeDecision(string decision)
{
   string symbol = "BITCOIN";
   double volume;
   ENUM_ORDER_TYPE orderType;
   
   if(decision == "Positive")
   {
      volume = 0.01;
      orderType = ORDER_TYPE_BUY;
   }
   else if(decision == "Negative")
   {
      volume = 0.01;
      orderType = ORDER_TYPE_SELL;
   }
   else if(decision == "Neutral")
   {
      Print("중립 결정. 주문 실행 없음.");
      return;
   }
   else
   {
      Print("알 수 없는 결정. 주문 실행 없음.");
      return;
   }
   
   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(trade.PositionOpen(symbol, orderType, volume, price, 0, 0, "AI 결정 기반 주문"))
   {
      Print("주문 성공: ", EnumToString(orderType), " ", DoubleToString(volume, 2), " lots at ", DoubleToString(price, _Digits));
   }
   else
   {
      Print("주문 실패. 오류 코드: ", GetLastError());
   }
}
