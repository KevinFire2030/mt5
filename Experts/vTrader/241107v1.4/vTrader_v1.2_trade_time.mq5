#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.21"

// vTrader_v1.2.mqh 파일을 같은 디렉토리에서 포함
#include "vTrader_v1.2_trade_time.mqh"

// EA 파라미터
input ulong InpMagicNumber = 20241106;  // 매직 넘버

// 전역 변수
CvTrader* g_trader = NULL;
int g_testResultsFile = INVALID_HANDLE;
datetime g_testStartTime;

// OnTesterInit을 파일 상단으로 이동
void OnTesterInit()
{
    if(!MQLInfoInteger(MQL_TESTER)) {
        Print("테스터 모드가 아닙니다!");
        return;
    }
    
    Print("=== OnTesterInit 호출됨 ===");
    g_testStartTime = TimeCurrent();
    Print("=== 테스트 시작 ===");
    Print("시작 시간: ", TimeToString(g_testStartTime));
    Print("심볼: ", _Symbol);
    Print("주기: ", EnumToString(Period()));
}

// EA 초기화
int OnInit() {
    // 테스터 모드 확인
    if(MQLInfoInteger(MQL_TESTER)) {
        Print("테스터에서 실행 중입니다 - OnInit");
    }
    
    Print("=== vTrader v1.2 초기화 ===");
    
    g_trader = new CvTrader();
    if(!g_trader.Init(_Symbol, InpMagicNumber)) {
        Print("트레이더 초기화 실패");
        return INIT_FAILED;
    }
    
    Print("매직넘버: ", InpMagicNumber);
    Print("=== 초기화 완료 ===");
    return INIT_SUCCEEDED;
}

// EA 해제
void OnDeinit(const int reason) {
    if(g_trader != NULL) {
        g_trader.Deinit();
        delete g_trader;
        g_trader = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    if(g_trader != NULL) {
        // 거래 시간 체크
        if(!IsTradeTime()) {
            return;  // 거래 시간이 아니면 종료
        }
        
        g_trader.OnTick();
    }
}

// 거래 트랜잭션 이벤트
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    if(g_trader != NULL) {
        g_trader.OnTradeTransaction(trans, request, result);
    }
}

//+------------------------------------------------------------------+
//| Tester deinitialization function                                  |
//+------------------------------------------------------------------+
void OnTesterDeinit()
{
    // 1. 테스트 종료 시간 기록
    datetime testEndTime = TimeCurrent();
    
    // 2. 테스트 결과 출력
    Print("=== 테스트 종료 ===");
    Print("종료 시간: ", TimeToString(testEndTime));
    Print("테스트 소요시간: ", testEndTime - g_testStartTime, "초");
    
    // 3. 리소스 정리
    if(g_testResultsFile != INVALID_HANDLE)
    {
        FileClose(g_testResultsFile);
        g_testResultsFile = INVALID_HANDLE;
    }
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
    double total_wins = 0;    // 승리 거래의 총 수익
    double total_losses = 0;  // 패배 거래의 총 손실
    
    // 전체 거래 내역 가져오기
    HistorySelect(0, TimeCurrent());
    int deals_total = HistoryDealsTotal();
    
    // 각 거래 분석
    for(int i = 0; i < deals_total; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        
        // 거래 정보 가져오기 및 보정
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) / 100.0;  // profit 보정
        double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION) / 100.0;  // commission 보정
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP) / 100.0;  // swap 보정
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