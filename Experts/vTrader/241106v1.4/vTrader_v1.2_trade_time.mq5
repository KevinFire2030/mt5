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