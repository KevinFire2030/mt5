#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.21"

// 필요한 라이브러리 포함
#include <Trade\Trade.mqh>
#include <Expert\Expert.mqh>
#include "vTrader_v1.3.mqh"

// EA 파라미터
input ulong InpMagicNumber = 20241105;  // 매직 넘버
input bool   InpTradeOverlapOnly = true;    // 시장 겹침 시간대만 거래
input bool   InpTradeLondonNY = true;       // 런던-뉴욕 겹침 시간 거래
input bool   InpTradeTokyoLondon = false;   // 도쿄-런던 겹침 시간 거래
input bool   InpAvoidNews = true;           // 주요 뉴스 시간 제외
input int    InpNewsMinutes = 15;           // 뉴스 전후 제외 시간(분)
input bool   InpCheckVolatility = true;     // 변동성 체크
input double InpMaxSpread = 3.0;            // 최대 허용 스프레드
input bool   InpTradeNYMarketOnly = false;  // 뉴욕 증시 시간만 거래
input group "=== 트레이딩 시간 설정 ==="
input bool   InpTradeTimeFilter = true;     // 시간 필터 사용
input bool   InpTradeNYOpen = true;         // 뉴욕 개장 시간대 (16:30-18:30)
input bool   InpTradeNYPeak = true;         // 뉴욕 피크 시간대 (17:00-20:00)
input bool   InpTradeNYClose = true;        // 뉴욕 마감 시간대 (21:00-22:00)

// 전역 변수
CvTrader* g_trader = NULL;
int g_testResultsFile = INVALID_HANDLE;
datetime g_testStartTime;
datetime g_testEndTime;

// OnTesterInit을 파일 상단으로 이동
void OnTesterInit()
{
    if(!MQLInfoInteger(MQL_TESTER)) {
        Print("테스터 모드가 아닙니다!");
        return;
    }
    
    Print("=== OnTesterInit 호출됨 ===");
    
    // 테스터에서 설정한 시작/종료 시간 가져오기
    datetime fromDate = (datetime)GlobalVariableGet("TestFromDate");
    datetime toDate = (datetime)GlobalVariableGet("TestToDate");
    
    // 테스터 설정 정보 출력
    Print("=== 테스트 설정 ===");
    Print("초기 증거금: ", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("레버리지: 1:", AccountInfoInteger(ACCOUNT_LEVERAGE));
    Print("통화: ", AccountInfoString(ACCOUNT_CURRENCY));
    Print("수익 계산 단위: Pips");  // 현재는 고정값
    
    // 테스트 모델 정보 출력
    string test_model = "알 수 없음";
    if(MQLInfoInteger(MQL_TESTER)) 
    {
        if(MQLInfoInteger(MQL_VISUAL_MODE))
            test_model = "시각화 모드";
        else if(MQLInfoInteger(MQL_OPTIMIZATION))
            test_model = "최적화 모드";
        else if(MQLInfoInteger(MQL_FRAME_MODE))
            test_model = "프레임 수집 모드";
        else
            test_model = "일반 테스트 모드";
    }
    Print("테스트 모델: ", test_model);
    
    // 추가 테스트 정보
    Print("틱 생성 모드: ", SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE));
    Print("틱 볼륨: ", SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
    
    // 심볼 정보
    Print("스프레드: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), " 포인트");
    Print("틱 사이즈: ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
    Print("포인트 크기: ", SymbolInfoDouble(_Symbol, SYMBOL_POINT));
    
    Print("=== 테스트 시작 ===");
    Print("테스트 시작 시간: ", TimeToString(fromDate));
    Print("테스트 종료 시간: ", TimeToString(toDate));
    Print(": ", _Symbol);
    Print("주기: ", EnumToString(Period()));
        
    // 전역변수에 저장
    g_testStartTime = fromDate;
    g_testEndTime = toDate;
}

// EA 초기화
int OnInit() {
    // 테스터 모드일 때 시작/종료 시간 저장
    if(MQLInfoInteger(MQL_TESTER)) {
        datetime currentTime = TimeCurrent();
        datetime endTime = currentTime + PeriodSeconds(PERIOD_D1);
        
        // long을 string으로 변환 후 다시 double로 변환하여 정밀도 손실 방지
        GlobalVariableSet("TestFromDate", StringToDouble(IntegerToString(currentTime)));
        GlobalVariableSet("TestToDate", StringToDouble(IntegerToString(endTime)));
        
        OnTesterInit();
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
//| Tester function                                                    |
//+------------------------------------------------------------------+
double OnTester()
{
    // 1. 테스트 종료 시간 기록
    datetime testEndTime = TimeCurrent();
    
    // 2. 테스트 결과 분석
    Print("=== 테스트 결과 분석 ===");
    
    // 기본 통계
    double initial_deposit = TesterStatistics(STAT_INITIAL_DEPOSIT);
    double profit = TesterStatistics(STAT_PROFIT);
    double gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
    double gross_loss = TesterStatistics(STAT_GROSS_LOSS);
    double profit_factor = TesterStatistics(STAT_PROFIT_FACTOR);
    double expected_payoff = TesterStatistics(STAT_EXPECTED_PAYOFF);
    
    Print("초기 증거금: ", DoubleToString(initial_deposit, 2));
    Print("순손익: ", DoubleToString(profit, 2));
    Print("총 수익: ", DoubleToString(gross_profit, 2));
    Print("총 손실: ", DoubleToString(gross_loss, 2));
    Print("수익 팩터: ", DoubleToString(profit_factor, 2));
    Print("기대 수익: ", DoubleToString(expected_payoff, 2));
    
    // 드로우다운 통계
    double balance_dd = TesterStatistics(STAT_BALANCE_DD);
    double balance_ddrel_percent = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
    double balance_dd_relative = TesterStatistics(STAT_BALANCE_DD_RELATIVE);
    
    Print("최대 자금 인출: ", DoubleToString(balance_dd, 2));
    Print("최대 자금 인출 % (상대): ", DoubleToString(balance_ddrel_percent, 2), "%");
    Print("상대적 자금 인출: ", DoubleToString(balance_dd_relative, 2));
    
    // 거래 통계
    int trades = (int)TesterStatistics(STAT_TRADES);
    int profit_trades = (int)TesterStatistics(STAT_PROFIT_TRADES);
    int loss_trades = (int)TesterStatistics(STAT_LOSS_TRADES);
    int short_trades = (int)TesterStatistics(STAT_SHORT_TRADES);
    int long_trades = (int)TesterStatistics(STAT_LONG_TRADES);
    
    Print("총 거래 횟수: ", trades);
    Print("수익 거래: ", profit_trades);
    Print("손실 거래: ", loss_trades);
    Print("숏 포지션: ", short_trades);
    Print("롱 포지션: ", long_trades);
    
    // 연속 거래 통계
    double conprofit_max = TesterStatistics(STAT_CONPROFITMAX);
    int conprofit_max_trades = (int)TesterStatistics(STAT_CONPROFITMAX_TRADES);
    double conloss_max = TesterStatistics(STAT_CONLOSSMAX);
    int conloss_max_trades = (int)TesterStatistics(STAT_CONLOSSMAX_TRADES);
    
    Print("최대 연속 수익: ", DoubleToString(conprofit_max, 2), " (", conprofit_max_trades, "거래)");
    Print("최대 연속 손실: ", DoubleToString(conloss_max, 2), " (", conloss_max_trades, "거래)");
    
    // 추가 지표
    double recovery_factor = TesterStatistics(STAT_RECOVERY_FACTOR);
    double sharpe_ratio = TesterStatistics(STAT_SHARPE_RATIO);
    double min_margin_level = TesterStatistics(STAT_MIN_MARGINLEVEL);
    
    Print("회복 팩터: ", DoubleToString(recovery_factor, 2));
    Print("샤프 비율: ", DoubleToString(sharpe_ratio, 2));
    Print("최소 마진 레벨: ", DoubleToString(min_margin_level, 2));
    
    // 사용자 정의 최적화 기준값 계산
    double custom_criterion = 0;
    if(trades > 0)
    {
        // (수익 * 회복팩터 * 샤프비율) / 최대드로우다운%
        custom_criterion = (profit * recovery_factor * (sharpe_ratio > 0 ? sharpe_ratio : 1)) 
                          / (balance_ddrel_percent > 0 ? balance_ddrel_percent : 1);
    }
    
    Print("최적화 기준값: ", DoubleToString(custom_criterion, 2));
    
    return custom_criterion;  // 최적화를 위한 기준값 반환
}

//+------------------------------------------------------------------+
//| Tester deinitialization function                                   |
//+------------------------------------------------------------------+
void OnTesterDeinit()
{
    // 리소스 정리
    if(g_testResultsFile != INVALID_HANDLE)
    {
        FileClose(g_testResultsFile);
        g_testResultsFile = INVALID_HANDLE;
    }
}

// 서머타임 체크 함수
bool IsDaylightSavingTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // 미국 서머타임: 3월 둘째 일요일 ~ 11월 첫째 ���요일
    if(dt.mon < 3 || dt.mon > 11) return false;  // 1-2월, 12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 11) return true;   // 4-10월: 서머타임
    
    int year = dt.year;
    
    // 3월의 둘째 일요일 계산
    int secondSun = 14 - (5 * year / 4 + 1) % 7;
    
    // 11월의 첫째 일요일 계산
    int firstSun = 7 - (5 * year / 4 + 4) % 7;
    
    if(dt.mon == 3)
        return dt.day > secondSun || (dt.day == secondSun && dt.hour >= 2);
    else  // dt.mon == 11
        return dt.day < firstSun || (dt.day == firstSun && dt.hour < 2);
}

// 영국 서머타임 체크 함수
bool IsUKDaylightSavingTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // 영국 서머타임: 3월 마지막 일요일 ~ 10월 마지막 일요일
    if(dt.mon < 3 || dt.mon > 10) return false;  // 1-2월, 11-12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 10) return true;   // 4-9월: 서머타임
    
    // 해당 월의 마지막 일요일 계산
    int lastSunday = 31;
    while(lastSunday > 0) {
        MqlDateTime tmp;
        TimeToStruct(StringToTime(string(dt.year) + "." + string(dt.mon) + "." + string(lastSunday)), tmp);
        if(tmp.day_of_week == 0) break;  // 일요일 찾기
        lastSunday--;
    }
    
    if(dt.mon == 3)
        return dt.day > lastSunday || (dt.day == lastSunday && dt.hour >= 2);
    else  // dt.mon == 10
        return dt.day < lastSunday || (dt.day == lastSunday && dt.hour < 2);
}

// 거래 시간 체크 함수
bool IsTradeTime()
{
    if(!InpTradeTimeFilter) return true;
    
    datetime current = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current, dt);
    
    int current_hour = dt.hour;
    int current_min = dt.min;
    bool isUSDST = IsDaylightSavingTime();
    
    // 1. 뉴욕 개장 시간대 (거래량 급증)
    if(InpTradeNYOpen) {
        if(isUSDST) {
            // 서머타임: MT5 시간 15:30-17:30
            if((current_hour == 15 && current_min >= 30) || 
               current_hour == 16 || 
               (current_hour == 17 && current_min <= 30))
                return true;
        } else {
            // 겨울시간: MT5 시간 16:30-18:30
            if((current_hour == 16 && current_min >= 30) || 
               current_hour == 17 || 
               (current_hour == 18 && current_min <= 30))
                return true;
        }
    }
    
    // 2. 뉴욕 피크 시간대 (최대 거래량)
    if(InpTradeNYPeak) {
        if(isUSDST) {
            // 서머타임: MT5 시간 17:00-20:00
            if(current_hour >= 17 && current_hour < 20)
                return true;
        } else {
            // 겨울시간: MT5 시간 18:00-21:00
            if(current_hour >= 18 && current_hour < 21)
                return true;
        }
    }
    
    // 3. 뉴욕 마감 시간대
    if(InpTradeNYClose) {
        if(isUSDST) {
            // 서머타임: MT5 시간 21:00-22:00
            if(current_hour == 21)
                return true;
        } else {
            // 겨울시간: MT5 시간 22:00-23:00
            if(current_hour == 22)
                return true;
        }
    }
    
    return false;
} 