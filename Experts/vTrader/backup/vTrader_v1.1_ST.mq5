#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.1"



#include "vTrader_v1.1.mqh"

// EA 파라미터
input ulong InpMagicNumber = 20240311;  // 매직 넘버

// 전역 변수
CvTrader* g_trader = NULL;

// EA 초기화
int OnInit() {
    Print("=== vTrader v1.1 초기화 ===");
    
    g_trader = new CvTrader();
    if(!g_trader.Init(_Symbol, InpMagicNumber)) {
        Print("트레이더 초기화 실패");
        return INIT_FAILED;
    }
    
    Print("매직넘버: ", InpMagicNumber);
    Print("=== 초기화 완료 ===");
    
    OnTesterInit();
    
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

// 틱 이벤트
void OnTick() {
    if(g_trader != NULL) {
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
//| 테스터 초기화 시 심볼 정보 출력                                      |
//+------------------------------------------------------------------+
void OnTesterInit()  // double에서 int로 변경
{
    string symbol = Symbol();
    
    Print("┌─────────────────────────────");
    Print("│ ", symbol, " 심볼 상세 정보");
    Print("├─────────────────────────────");
    
    // 기본 정보
    Print("│ [기본 정보]");
    Print("│ 심볼: ", symbol);
    Print("│ 설명: ", SymbolInfoString(symbol, SYMBOL_DESCRIPTION));
    Print("│ 거래소: ", SymbolInfoString(symbol, SYMBOL_PATH));
    Print("│ 통화기준: ", SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE));
    Print("│ 결제통화: ", SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT));
    Print("│ 마진통화: ", SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN));
    
    // 거래 단위 정보
    Print("│ [거래 단위 정보]");
    Print("│ 계약 크기: ", SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE));
    Print("│ 최소 거래량: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
    Print("│ 최대 거래량: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
    Print("│ 거래량 단계: ", SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
    
    // 가격 정보
    Print("│ [가격 정보]");
    Print("│ 호가단위(틱): ", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));
    Print("│ 틱당 가치: ", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE));
    Print("│ 포인트: ", SymbolInfoDouble(symbol, SYMBOL_POINT));
    Print("│ 소수점 자리수: ", SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    
    // 스프레드 정보
    Print("│ [스프레드 정보]");
    Print("│ 스프레드: ", SymbolInfoInteger(symbol, SYMBOL_SPREAD));
    Print("│ 변동 스프레드: ", (bool)SymbolInfoInteger(symbol, SYMBOL_SPREAD_FLOAT) ? "예" : "아니오");
    
    // 마진 정보
    Print("│ [마진 정보]");
    Print("│ 초기 마진: ", SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL));
    Print("│ 유지 마진: ", SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE));
    Print("│ 마진 계산 모드: ", EnumToString((ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE)));
    
    // 스왑 정보
    Print("│ [스왑 정보]");
    Print("│ 롱 스왑: ", SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG));
    Print("│ 숏 스왑: ", SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT));
    Print("│ 스왑 계산 모드: ", EnumToString((ENUM_SYMBOL_SWAP_MODE)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE)));
    Print("│ 3일 스왑일: ", SymbolInfoInteger(symbol, SYMBOL_SWAP_ROLLOVER3DAYS));
    
    // 거래 모드
    Print("│ [거래 모드]");
    Print("│ 거래 허용 모드: ", EnumToString((ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)));
    Print("│ 거래 실행 모드: ", EnumToString((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE)));
    
    // 현재 가격
    MqlTick last_tick;
    SymbolInfoTick(symbol, last_tick);
    Print("│ [현재 가격]");
    Print("│ Bid: ", last_tick.bid);
    Print("│ Ask: ", last_tick.ask);
    
    Print("└─────────────────────────────");
    
}

//+------------------------------------------------------------------+
//| 테스터 종료 시 호출되는 함수                                        |
//+------------------------------------------------------------------+
void OnTesterDeinit()
{
    Print("=== 테스터 종료 ===");
}

//+------------------------------------------------------------------+
//| Expert optimization function                                       |
//+------------------------------------------------------------------+
double OnTester()
{
    // 테스트 통계 가져오기
    double profit = TesterStatistics(STAT_PROFIT);           // 순손익

    
    Print("=== 테스트 결과 ===");
    Print("순손익: ", profit);

    
    // NASDAQ100의 경우 승수 = 0.01 적용
    double adjustedProfit = profit * 0.01;
    Print("조정된 손익: ", adjustedProfit);
    
    return adjustedProfit;  // 이 값이 "Custom max" 열에 표시됨
}