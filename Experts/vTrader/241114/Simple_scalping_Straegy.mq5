//+------------------------------------------------------------------+
//| Expert Advisor 기본 구조
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input int    FastEMA = 30;         // 단기 EMA 기간
input int    SlowEMA = 50;         // 장기 EMA 기간
input int    BBPeriod = 15;        // 볼린저밴드 기간
input double BBDeviation = 1.5;    // 볼린저밴드 표준편차
input int    BackCandles = 7;      // EMA 확인 기간
input int    ATRPeriod = 7;        // ATR 기간
input double SLCoef = 1.1;         // 손절 계수
input double TPSLRatio = 1.5;      // 익절/손절 비율
input double LotSize = 0.1;        // 거래 수량

CTrade trade;  // 거래 객체

// 지표 핸들
int handle_fast_ema;
int handle_slow_ema;
int handle_bands;
int handle_atr;

//+------------------------------------------------------------------+
//| 거래 결과 분석을 위한 구조체                                        |
//+------------------------------------------------------------------+
struct TradeStats
{
   int     totalTrades;    // 총 거래 수
   int     winTrades;      // 수익 거래 수
   double  totalProfit;    // 총 수익
   double  totalLoss;      // 총 손실
   double  avgProfit;      // 평균 수익
   double  avgLoss;        // 평균 손실
};

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   // 지표 핸들 초기화
   handle_fast_ema = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   handle_slow_ema = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   handle_bands = iBands(_Symbol, PERIOD_CURRENT, BBPeriod, 0, BBDeviation, PRICE_CLOSE);
   handle_atr = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   // 새로운 봉이 생성되었는지 확인
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   // 새로운 봉이 아니면 리턴
   if(lastBarTime == currentBarTime) return;
   lastBarTime = currentBarTime;

   // 포지션이 있는지 확인
   if(PositionsTotal() > 0) return;
   
   // 지표값 계산을 위한 배열
   double ema_fast[], ema_slow[], bb_upper[], bb_lower[], atr[];
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(atr, true);
   
   // 지표값 복사
   CopyBuffer(handle_fast_ema, 0, 0, 2, ema_fast);
   CopyBuffer(handle_slow_ema, 0, 0, 2, ema_slow);
   CopyBuffer(handle_bands, 1, 0, 2, bb_upper);  // 상단밴드
   CopyBuffer(handle_bands, 2, 0, 2, bb_lower);  // 하단밴드
   CopyBuffer(handle_atr, 0, 0, 1, atr);
   
   // 현재 가격
   double current_close = iClose(_Symbol, PERIOD_CURRENT, 0);
   
   // EMA 신호 확인
   int ema_signal = CheckEMASignal();
   
   // 매매 신호 생성 및 주문 실행
   if(ema_signal == 2 && current_close <= bb_lower[0])  // 매수 신호
   {
      double sl = NormalizeDouble(current_close - (atr[0] * SLCoef), _Digits);
      double tp = NormalizeDouble(current_close + (atr[0] * SLCoef * TPSLRatio), _Digits);
      trade.Buy(LotSize, _Symbol, 0, sl, tp);
   }
   else if(ema_signal == 1 && current_close >= bb_upper[0])  // 매도 신호
   {
      double sl = NormalizeDouble(current_close + (atr[0] * SLCoef), _Digits);
      double tp = NormalizeDouble(current_close - (atr[0] * SLCoef * TPSLRatio), _Digits);
      trade.Sell(LotSize, _Symbol, 0, sl, tp);
   }
}

//+------------------------------------------------------------------+
//| EMA 신호 확인 함수                                                 |
//+------------------------------------------------------------------+
int CheckEMASignal()
{
   double ema_fast[], ema_slow[];
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   
   CopyBuffer(handle_fast_ema, 0, 0, BackCandles, ema_fast);
   CopyBuffer(handle_slow_ema, 0, 0, BackCandles, ema_slow);
   
   bool all_above = true;
   bool all_below = true;
   
   for(int i=0; i < BackCandles; i++)
   {
      if(ema_fast[i] <= ema_slow[i]) all_above = false;
      if(ema_fast[i] >= ema_slow[i]) all_below = false;
   }
   
   if(all_above) return 2;  // 상승 추세
   if(all_below) return 1;  // 하락 추세
   return 0;  // 중립
}

//+------------------------------------------------------------------+
//| Trading Edge 분석 함수                                             |
//+------------------------------------------------------------------+
void AnalyzeTradingEdge()
{
   TradeStats stats = {0};
   
   // 거래 내역 분석
   HistorySelect(0, TimeCurrent());  // 전체 거래 내역 선택
   
   for(int i=0; i<HistoryDealsTotal(); i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
         {
            stats.totalTrades++;
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
            double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            double totalProfit = profit + swap + commission;
            
            if(totalProfit > 0)
            {
               stats.winTrades++;
               stats.totalProfit += totalProfit;
            }
            else
            {
               stats.totalLoss += MathAbs(totalProfit);
            }
         }
      }
   }
   
   // 0으로 나누기 방지
   if(stats.totalTrades == 0 || stats.winTrades == 0 || 
      (stats.totalTrades - stats.winTrades) == 0)
   {
      Print("거래 내역이 충분하지 않습니다.");
      return;
   }
   
   // 계산
   double winRate = (double)stats.winTrades / stats.totalTrades;
   stats.avgProfit = stats.totalProfit / stats.winTrades;
   stats.avgLoss = stats.totalLoss / (stats.totalTrades - stats.winTrades);
   
   // Trading Edge 계산
   double TE = (winRate * stats.avgProfit) - ((1 - winRate) * stats.avgLoss);
   
   // 필요 RR비율 계산
   double requiredRR = (1 - winRate) / winRate;
   double actualRR = stats.avgProfit / stats.avgLoss;
   
   // 결과 출력
   Print("=== Trading Edge 분석 ===");
   PrintFormat("총 거래 수: %d", stats.totalTrades);
   PrintFormat("승률: %.2f%%", winRate * 100);
   PrintFormat("평균 수익: $%.2f", stats.avgProfit);
   PrintFormat("평균 손실: $%.2f", stats.avgLoss);
   PrintFormat("Trading Edge: $%.2f", TE);
   PrintFormat("필요 RR비율: %.2f", requiredRR);
   PrintFormat("실제 RR비율: %.2f", actualRR);
   PrintFormat("RR비율 평가: %s", actualRR > requiredRR ? "충족" : "미달");
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // 전략 테스터 종료시 분석 실행
   if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE || 
      reason == REASON_PROGRAM || reason == REASON_TEMPLATE)
   {
      AnalyzeTradingEdge();
   }
}

