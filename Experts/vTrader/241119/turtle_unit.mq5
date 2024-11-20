//+------------------------------------------------------------------+
//|                                                  turtle_unit.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

// 입력 파라미터
input int     ATR_Period = 20;       // ATR 기간
input double  Risk_Percent = 1.0;    // 리스크 비율(%)
input double  Account_Risk = 1000;   // 계좌 리스크($)

// 전역 변수
int atr_handle;                      // ATR 핸들
double atr_value;                    // ATR 값

// 클래스 포함
#include <Trade/Trade.mqh>
CTrade trade;

int OnInit()
{
    // ATR 지표 핸들 생성
    atr_handle = iCustom(_Symbol, _Period, "CustomATR", ATR_Period);
    if(atr_handle == INVALID_HANDLE)
    {
        Print("ATR 지표 생성 실패!");
        return(INIT_FAILED);
    }
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // 지표 핸들 해제
    if(atr_handle != INVALID_HANDLE)
        IndicatorRelease(atr_handle);
}

//+------------------------------------------------------------------+
//| 새로운 봉의 첫 틱인지 확인하는 함수                                |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime lastbar = iTime(_Symbol, _Period, 0);
    datetime curbar = iTime(_Symbol, _Period, 0);
    
    if(lastbar != curbar)
    {
        lastbar = curbar;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 거래량 계산 함수                                                   |
//+------------------------------------------------------------------+
double CalculateVolume(double current_atr)
{
    if(current_atr == 0.0) 
        return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    
    // 계좌 정보 가져오기
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 리스크 금액 계산
    double riskAmount = balance * Risk_Percent / 100.0;
    riskAmount = MathMin(riskAmount, Account_Risk);
    
    // 심볼 정보 가져오기
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    
    // ATR을 틱 단위로 변환
    double slInTicks = current_atr / tickSize;
    
    // 1 로트당 리스크 계산 (달러 변동성)
    double riskPerLot = slInTicks * tickValue;
    
    // 거래량 계산 (리스크 금액 / 달러 변동성)
    double volume = NormalizeDouble(riskAmount / riskPerLot, 2);
    volume = MathMax(volume, minLot);
    
    // 상세 정보 출력
    string info = StringFormat(
        "=== 거래량 계산 상세 ===\n" +
        "계좌 잔고: $%.2f\n" +
        "계좌 순자산: $%.2f\n" +
        "리스크 비율: %.1f%%\n" +
        "리스크 금액: $%.2f\n" +
        "ATR(N): %.5f\n" +
        "Tick Size: %.5f\n" +
        "Tick Value: %.5f\n" +
        "SL in Ticks: %.2f\n" +
        "Risk per Lot: %.2f\n" +
        "계산된 거래량: %.2f",
        balance,
        equity,
        Risk_Percent,
        riskAmount,
        current_atr,
        tickSize,
        tickValue,
        slInTicks,
        riskPerLot,
        volume
    );
    
    Comment(info);
    
    return volume;
}

//+------------------------------------------------------------------+
//| 터틀 진입 시그널 체크 함수                                          |
//+------------------------------------------------------------------+
int CheckEntrySignal()
{
    double close[];
    ArraySetAsSeries(close, true);
    
    // 최근 22개 봉 데이터 복사 (현재 봉 + 이전 21개 봉)
    if(CopyClose(_Symbol, _Period, 0, 22, close) <= 0) return 0;
    
    // 2봉전부터 21개 봉의 최고가/최저가 계산
    double highest = close[2];  // 2봉전부터 시작
    double lowest = close[2];
    
    for(int i = 2; i <= 21; i++)  // 2봉전부터 20개 봉 검사
    {
        if(close[i] > highest) highest = close[i];
        if(close[i] < lowest) lowest = close[i];
    }
    
    // 1봉전의 종가로 시그널 체크
    if(close[1] > highest) return 1;     // 롱 진입 시그널
    if(close[1] < lowest) return -1;     // 숏 진입 시그널
    
    return 0;  // 시그널 없음
}

void OnTick()
{
    // 새로운 봉이 아니면 리턴
    if(!IsNewBar())
        return;
    
    // 1봉전 ATR 값 가져오기
    double atr_buffer[];
    ArraySetAsSeries(atr_buffer, true);
    if(CopyBuffer(atr_handle, 0, 1, 1, atr_buffer) <= 0)
        return;
        
    atr_value = atr_buffer[0];
    
    // 거래량 계산
    double volume = CalculateVolume(atr_value);
    
    // 진입 시그널 체크
    int signal = CheckEntrySignal();
    
    // 시그널 정보 출력
    string signal_info = "";
    if(signal > 0)
    {
        signal_info = "\n=== 롱 진입 시그널 발생! ===";
        OpenLongPosition(volume);
    }
    else if(signal < 0)
    {
        signal_info = "\n=== 숏 진입 시그널 발생! ===";
        OpenShortPosition(volume);
    }
    
    
}


//+------------------------------------------------------------------+
//| 롱 포지션 오픈 함수                                                |
//+------------------------------------------------------------------+
bool OpenLongPosition(double volume)
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = ask - (atr_value * 2);  // ATR의 2배를 손절로 설정
    double tp = ask + (atr_value * 3);  // ATR의 2배를 이익실현으로 설정
    
    // 주문 설정
    trade.SetDeviationInPoints(10);      // 슬리피지 설정
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    
    // 매수 주문 실행
    bool result = trade.Buy(
        volume,     // 거래량
        _Symbol,    // 심볼
        ask,        // 주문가격
        sl,         // 손절가
        tp,         // 이익실현가
        "Turtle Long Entry"  // 주문 코멘트
    );
    
    if(!result)
    {
        Print("롱 포지션 진입 실패! Error = ", GetLastError());
        return false;
    }
    
    return true;
}


//+------------------------------------------------------------------+
//| 숏 포지션 오픈 함수                                                |
//+------------------------------------------------------------------+
bool OpenShortPosition(double volume)
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = bid + (atr_value * 2);  // ATR의 2배를 손절로 설정
    double tp = bid - (atr_value * 3);  // ATR의 2배를 이익실현으로 설정
    
    // 주문 설정
    trade.SetDeviationInPoints(10);      // 슬리피지 설정
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    
    // 매도 주문 실행
    bool result = trade.Sell(
        volume,     // 거래량
        _Symbol,    // 심볼
        bid,        // 주문가격
        sl,         // 손절가
        tp,         // 이익실현가
        "Turtle Short Entry"  // 주문 코멘트
    );
    
    if(!result)
    {
        Print("숏 포지션 진입 실패! Error = ", GetLastError());
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Tester function                                                    |
//+------------------------------------------------------------------+
double OnTester()
{
    // 통계 변수 초기화
    double total_profit = 0;
    int winning_trades = 0;
    int losing_trades = 0;
    double total_wins = 0;    
    double total_losses = 0;  
    
    // 전체 거래 내역 가져오기
    HistorySelect(0, TimeCurrent());
    int deals_total = HistoryDealsTotal();
    
    // 각 거래 분석
    for(int i = 0; i < deals_total; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        
        // 매직 넘버 확인
        //int deal_magic = (int)HistoryDealGetInteger(ticket, DEAL_MAGIC);
        //if(deal_magic != InpMagicNumber) continue;  // 현재 EA의 거래만 분석
        
        // 거래 유형 확인
        ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
        if(deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL) continue;  // 실제 거래만 분석
        
        // 거래 정보 가져오기 및 보정
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) / 100.0;
        double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION) / 100.0;
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP) / 100.0;
        
        // 순손익 계산
        double net_profit = profit + commission + swap;
        
        // 통계 업데이트
        if(net_profit > 0) 
        {
            winning_trades++;
            total_wins += net_profit;
        }
        else if(net_profit < 0) 
        {
            losing_trades++;
            total_losses += MathAbs(net_profit);
        }
        total_profit += net_profit;
    }
    
    // 통계 계산
    int total_trades = winning_trades + losing_trades;
    double win_rate = total_trades > 0 ? (100.0 * winning_trades / total_trades) : 0;
    double loss_rate = total_trades > 0 ? (100.0 * losing_trades / total_trades) : 0;
    
    // 평균 수익/손실 계산
    double avg_win = (winning_trades > 0) ? total_wins / winning_trades : 0;
    double avg_loss = (losing_trades > 0) ? total_losses / losing_trades : 0;
    
    // RR비율과 TE 계산
    double rr_ratio = (avg_loss > 0) ? avg_win / avg_loss : 0;
    double te = (win_rate/100.0 * avg_win) - (loss_rate/100.0 * avg_loss);
    
    // Win RR 계산
    double win_rr = (win_rate > 0 && win_rate < 100) ? ((100.0 - win_rate) / win_rate) : 0;
    
    // 통계 출력
    Print("=== 거래 통계 ===");
    PrintFormat("총 거래 수: %d", total_trades);
    PrintFormat("승리: %d | 패배: %d", winning_trades, losing_trades);
    PrintFormat("승률: %.2f%%", win_rate);
    PrintFormat("총 손익: %.2f", total_profit);
    PrintFormat("평균 수익: %.2f", avg_win);
    PrintFormat("평균 손실: %.2f", avg_loss);
    PrintFormat("RR비율: %.2f (Win RR > %.2f)", rr_ratio, win_rr);
    PrintFormat("TE: %.2f", te);
    
    // TE를 반환 (전략 테스터의 최적화에 사용됨)
    return te;
}