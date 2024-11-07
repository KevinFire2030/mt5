//+------------------------------------------------------------------+
//|                                                 vTrader_v1.4.mq5    |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.40"

#include <Trade\Trade.mqh>

// 거래 시간 설정
input group "=== 트레이딩 시간 설정 ==="
input bool   InpTradeTimeFilter = true;     // 시간 필터 사용
input bool   InpTradeNYOpen = true;         // 뉴욕 개장 (16:30-18:30)
input bool   InpTradeNYPeak = true;         // 뉴욕 피크 (17:00-20:00)
input bool   InpTradeNYClose = true;        // 뉴욕 마감 (21:00-22:00)

// 거래량 필터
input group "=== 거래량 필터 ==="
input bool   InpVolumeFilter = true;        // 거래량 필터 사용
input double InpVolumeFactor = 1.5;         // 평균 거래량 대비 배수

// 변동성 필터
input group "=== 변동성 필터 ==="
input bool   InpVolatilityFilter = true;    // 변동성 필터 사용
input double InpMinATR = 50.0;              // 최소 ATR
input double InpMaxATR = 200.0;             // 최대 ATR

// 모멘텀 필터
input group "=== 모멘텀 필터 ==="
input bool   InpMomentumFilter = true;      // 모멘텀 필터 사용
input double InpMinSpeed = 0.5;             // 최소 가격 변화 속도
input double InpMinStrength = 1.0;          // 최소 모멘텀 강도

// 리스크 관리
input group "=== 리스크 관리 ==="
input double InpRiskPercent = 1.0;          // 거래당 리스크 비율(%)
input double InpMaxDailyLoss = 5.0;         // 일일 최대 손실(%)
input int    InpMaxPositions = 2;           // 최대 동시 포지션 수

// 디버깅 설정
input group "=== 디버깅 설정 ==="
input bool   InpDebugMode = true;          // 디버깅 모드 사용
input bool   InpDebugPrint = true;         // 디버그 메시지 출력
input bool   InpDebugAlert = false;        // 디버그 알림 사용

// 전역 변수
CTrade trade;
int ATR_handle;
datetime lastBarTime;
double dailyLoss = 0;
double ATR[];

//+------------------------------------------------------------------+
//| 실시간 가격 모멘텀 구조체                                           |
//+------------------------------------------------------------------+
struct PriceMomentum {
    double speed;        // 가격 변화 속도
    double acceleration; // 가격 변화 가속도
    double direction;    // 방향 (-1: 하락, 0: 중립, 1: 상승)
    double strength;     // 움직임 강도
};

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
{
    // ATR 지표 초기화
    ATR_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
    if(ATR_handle == INVALID_HANDLE) {
        Print("ATR 지표 초기화 실패!");
        return INIT_FAILED;
    }
    
    // ATR 배열을 시계열로 설정
    ArraySetAsSeries(ATR, true);
    
    // 매직넘버 설정
    trade.SetExpertMagicNumber(20241106);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(ATR_handle != INVALID_HANDLE)
        IndicatorRelease(ATR_handle);
}

//+------------------------------------------------------------------+
//| 실시간 가격 모멘텀 분석                                            |
//+------------------------------------------------------------------+
PriceMomentum AnalyzePriceMomentum()
{
    PriceMomentum result = {0};
    
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    
    // 최근 100개의 틱 데이터 수집
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 100);
    
    if(copied < 10) {
        DebugPrint("틱 데이터 부족: " + string(copied) + " ticks");
        return result;
    }
    
    // 가격 변화량 계산 (최근 10틱 기준)
    double price_changes[10] = {0};
    double time_changes[10] = {0};
    double volume_sum = 0;
    
    for(int i=0; i<9; i++) {
        price_changes[i] = ticks[i].bid - ticks[i+1].bid;  // bid 가격 사용
        time_changes[i] = (double)(ticks[i].time_msc - ticks[i+1].time_msc) / 1000.0;
        volume_sum += ticks[i].volume_real;  // 실제 거래량 사용
        
        DebugPrint(StringFormat(
            "틱[%d]: 가격변화=%.5f, 시간변화=%.3f, 거래량=%d",
            i, price_changes[i], time_changes[i], ticks[i].volume_real
        ));
    }
    
    // 속도 계산 (최근 5틱의 평균 변화율)
    double total_price_change = 0;
    double total_time_change = 0;
    
    for(int i=0; i<5; i++) {
        total_price_change += price_changes[i];
        total_time_change += time_changes[i];
    }
    
    if(total_time_change > 0) {
        result.speed = total_price_change / total_time_change;
    }
    
    // 방향성 판단 (최근 10틱 기준)
    int up_count = 0, down_count = 0;
    for(int i=0; i<9; i++) {
        if(price_changes[i] > 0) up_count++;
        if(price_changes[i] < 0) down_count++;
    }
    
    // 방향성이 명확할 때만 설정
    if(up_count > down_count + 2) result.direction = 1;
    else if(down_count > up_count + 2) result.direction = -1;
    
    // 가속도 계산 (현재 속도와 이전 속도의 차이)
    double prev_total_price_change = 0;
    double prev_total_time_change = 0;
    
    for(int i=5; i<10; i++) {
        prev_total_price_change += price_changes[i];
        prev_total_time_change += time_changes[i];
    }
    
    if(prev_total_time_change > 0) {
        double prev_speed = prev_total_price_change / prev_total_time_change;
        result.acceleration = (result.speed - prev_speed) / ((total_time_change + prev_total_time_change) / 2);
    }
    
    // 강도 계산 (가격 변화 * 거래량)
    result.strength = MathAbs(total_price_change) * (volume_sum / 10);
    
    DebugPrint(StringFormat(
        "모멘텀 상세 - 가격변화: %.5f, 시간변화: %.3f, 거래량: %.2f",
        total_price_change, total_time_change, volume_sum
    ));
    
    return result;
}

//+------------------------------------------------------------------+
//| 서머타임 체크                                                      |
//+------------------------------------------------------------------+
bool IsDaylightSavingTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    if(dt.mon < 3 || dt.mon > 11) return false;  // 1-2월, 12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 11) return true;   // 4-10월: 서머타임
    
    int year = dt.year;
    
    // 3월의 둘째 일요일 계산
    int secondSun = 14 - (5 * year / 4 + 1) % 7;
    
    // 11월의 첫째 일요일 계산
    int firstSun = 1;
    while(firstSun <= 7) {
        MqlDateTime tmp;
        TimeToStruct(StringToTime(string(year) + ".11." + string(firstSun)), tmp);
        if(tmp.day_of_week == 0) break;
        firstSun++;
    }
    
    if(dt.mon == 3)
        return dt.day > secondSun || (dt.day == secondSun && dt.hour >= 2);
    else if(dt.mon == 11)
        return dt.day < firstSun || (dt.day == firstSun && dt.hour < 2);
        
    return false;
}

//+------------------------------------------------------------------+
//| 거래 시간 체크                                                     |
//+------------------------------------------------------------------+
bool IsTradeTime()
{
    if(!InpTradeTimeFilter) return true;
    
    datetime current = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current, dt);
    
    int current_hour = dt.hour;
    int current_min = dt.min;
    bool isUSDST = IsDaylightSavingTime();
    
    // 1. 뉴욕 개장 시간대
    if(InpTradeNYOpen) {
        if(isUSDST) {
            if((current_hour == 15 && current_min >= 30) || 
               current_hour == 16 || 
               (current_hour == 17 && current_min <= 30))
                return true;
        } else {
            if((current_hour == 16 && current_min >= 30) || 
               current_hour == 17 || 
               (current_hour == 18 && current_min <= 30))
                return true;
        }
    }
    
    // 2. 뉴욕 피크 시간대
    if(InpTradeNYPeak) {
        if(isUSDST) {
            if(current_hour >= 17 && current_hour < 20)
                return true;
        } else {
            if(current_hour >= 18 && current_hour < 21)
                return true;
        }
    }
    
    // 3. 뉴욕 마감 시간대
    if(InpTradeNYClose) {
        if(isUSDST) {
            if(current_hour == 21)
                return true;
        } else {
            if(current_hour == 22)
                return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 거래량 체크                                                        |
//+------------------------------------------------------------------+
bool CheckVolume()
{
    if(!InpVolumeFilter) return true;
    
    double currentVolume = iRealVolume(_Symbol, PERIOD_CURRENT, 0);
    double avgVolume = 0;
    
    // 최근 20봉의 평균 거래량 계산
    for(int i=1; i<=20; i++)
        avgVolume += iRealVolume(_Symbol, PERIOD_CURRENT, i);
    avgVolume /= 20;
    
    return currentVolume >= avgVolume * InpVolumeFactor;
}

//+------------------------------------------------------------------+
//| 변동성 체크                                                        |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
    if(!InpVolatilityFilter) return true;
    
    double ATR[];
    ArraySetAsSeries(ATR, true);
    
    if(CopyBuffer(ATR_handle, 0, 0, 1, ATR) != 1) return false;
    
    return (ATR[0] >= InpMinATR && ATR[0] <= InpMaxATR);
}

//+------------------------------------------------------------------+
//| 디버그 메시지 출력                                                  |
//+------------------------------------------------------------------+
void DebugPrint(string message, bool alert = false)
{
    if(!InpDebugMode) return;
    
    if(InpDebugPrint) {
        Print("DEBUG: ", message);
    }
    
    if(InpDebugAlert && alert) {
        Alert("DEBUG ALERT: ", message);
    }
}

//+------------------------------------------------------------------+
//| 실시간 상태 모니터링                                               |
//+------------------------------------------------------------------+
void ShowStatus()
{
    if(!InpDebugMode) return;
    
    // 현재 시간 정보
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string timeInfo = StringFormat(
        "MT5: %02d:%02d (뉴욕: %02d:%02d)",
        dt.hour, dt.min,
        dt.hour - (IsDaylightSavingTime() ? 6 : 7), dt.min
    );
    
    // 거래 조건 상태
    string tradeConditions = StringFormat(
        "거래시간: %s\n거래량: %s\n변동성: %s",
        IsTradeTime() ? "YES" : "NO",
        CheckVolume() ? "OK" : "NO",
        CheckVolatility() ? "OK" : "NO"
    );
    
    // 모멘텀 정보
    PriceMomentum momentum = AnalyzePriceMomentum();
    string momentumInfo = StringFormat(
        "속도: %.5f\n가속도: %.5f\n방향: %s\n강도: %.2f",
        momentum.speed,
        momentum.acceleration,
        momentum.direction > 0 ? "상승" : momentum.direction < 0 ? "하락" : "중립",
        momentum.strength
    );
    
    // 포지션 정보
    string positionInfo = StringFormat(
        "포지션 수: %d/%d\n일일손실: %.2f%%",
        PositionsTotal(),
        InpMaxPositions,
        (dailyLoss / AccountInfoDouble(ACCOUNT_BALANCE)) * 100
    );
    
    // 화면에 정보 표시
    Comment(
        "\n=== vTrader v1.4 상태 ===\n",
        "시간: ", timeInfo, "\n\n",
        "=== 거래 조건 ===\n", tradeConditions, "\n\n",
        "=== 모멘텀 분석 ===\n", momentumInfo, "\n\n",
        "=== 포지션 정보 ===\n", positionInfo
    );
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    // 새로운 봉 체크
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(currentBarTime == lastBarTime) {
        ShowStatus();  // 실시간 상태 업데이트
        return;
    }
    lastBarTime = currentBarTime;
    
    // ATR 값 복사
    if(CopyBuffer(ATR_handle, 0, 0, 1, ATR) != 1) {
        DebugPrint("ATR 데이터 복사 실패", true);
        return;
    }
    
    // 포지션 수 체크
    if(PositionsTotal() >= InpMaxPositions) {
        DebugPrint("최대 포지션 수 도달");
        return;
    }
    
    // 일일 손실 체크
    if(dailyLoss <= -(AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxDailyLoss / 100)) {
        DebugPrint("일일 최대 손실 도달", true);
        return;
    }
    
    // 실시간 가격 모멘텀 분석
    PriceMomentum momentum = AnalyzePriceMomentum();
    DebugPrint(StringFormat(
        "모멘텀 분석 - 속도: %.5f, 가속도: %.5f, 방향: %d, 강도: %.2f",
        momentum.speed, momentum.acceleration, momentum.direction, momentum.strength
    ));
    
    // 거래 신호 생성
    if(momentum.direction > 0 && momentum.strength > InpMinStrength * 2) {
        // 매수 신호
        double sl = SymbolInfoDouble(_Symbol, SYMBOL_BID) - ATR[0] * 2;
        double tp = SymbolInfoDouble(_Symbol, SYMBOL_BID) + ATR[0] * 3;
        
        DebugPrint(StringFormat(
            "매수 신호 - 가격: %.5f, SL: %.5f, TP: %.5f",
            SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp
        ), true);
        
        trade.Buy(0.1, _Symbol, 0, sl, tp);
    }
    else if(momentum.direction < 0 && momentum.strength > InpMinStrength * 2) {
        // 매도 신호
        double sl = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + ATR[0] * 2;
        double tp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - ATR[0] * 3;
        
        DebugPrint(StringFormat(
            "매도 신호 - 가격: %.5f, SL: %.5f, TP: %.5f",
            SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp
        ), true);
        
        trade.Sell(0.1, _Symbol, 0, sl, tp);
    }
    
    ShowStatus();  // 상태 업데이트
}
