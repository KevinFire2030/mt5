//+------------------------------------------------------------------+
//|                                                    tick_chart.mq5   |
//|                                  Copyright 2024, MetaQuotes Ltd.    |
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// 입력 파라미터
//input int InpTickCount = 100;        // 틱 개수
input int InpTickCount = 5;        // 틱 개수
input bool InpShowDebug = true;      // 디버그 메시지 표시 (테스트를 위해 true로 변경)

// 전역 변수
long g_lastTickTime_msc = 0;    // datetime -> long (밀리초 단위)
bool g_hasTradeTicks = false;        // 매수/매도 플래그 존재 여부

// 봉 데이터 구조체
struct TickBarData {
    datetime time;        // 시간 (초)
    long time_msc;       // 시간 (밀리초) 추가
    double open;         // 시가
    double high;         // 고가
    double low;          // 저가
    double close;        // 종가
    ulong volume;        // 거래량
    int tickCount;       // 틱 수
    
    void Reset() {
        time = 0;
        time_msc = 0;    // 밀리초 초기화 추가
        open = 0;
        high = 0;
        low = 0;
        close = 0;
        volume = 0;
        tickCount = 0;
    }
};

// 봉 데이터 검증 구조체
struct BarValidation {
    bool isValid;           // 전체 유효성
    string errorMessage;    // 오류 메시지
    
    // OHLC 검증
    bool isValidOpen;       // 시가 유효성
    bool isValidHigh;       // 고가 유효성
    bool isValidLow;        // 저가 유효성
    bool isValidClose;      // 종가 유효성
    bool isValidVolume;     // 거래량 유효성
    bool isValidTime;       // 시간 유효성
    
    void Reset() {
        isValid = true;
        errorMessage = "";
        isValidOpen = true;
        isValidHigh = true;
        isValidLow = true;
        isValidClose = true;
        isValidVolume = true;
        isValidTime = true;
    }
};

// 전역 변수
TickBarData g_currentBar;    // 현재 봉 데이터
BarValidation g_validation;  // 봉 데이터 검증 결과

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // 입력값 검증
    if(InpTickCount <= 0) {
        Print("틱 개수는 0보다 커야 합니다");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    g_lastTickTime_msc = 0;
    
    Print("=== EA 초기화 ===");
    Print("설정된 틱 개수: ", InpTickCount);
    Print("디버그 모드: ", InpShowDebug ? "켜짐" : "꺼짐");
    
    // 현재 봉 초기화
    g_currentBar.Reset();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== EA 종료 ===");
    Print("종료 이유: ", GetUninitReasonText(reason));
}

//+------------------------------------------------------------------+
//| 과거 틱 데이터에서 매수/매도 플래그 확인                            |
//+------------------------------------------------------------------+
bool CheckTradeFlags()
{
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    
    // 최근 10000개의 틱 데이터 복사
    ulong copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 10000);
    
    if(copied <= 0) {
        Print("틱 데이터를 가져오는데 실패했습니다. Error: ", GetLastError());
        return false;
    }
    
    int buyCount = 0;
    int sellCount = 0;
    
    // 틱 데이터 분석
    for(ulong i = 0; i < copied; i++) {
        if((ticks[i].flags & TICK_FLAG_BUY) != 0) buyCount++;
        if((ticks[i].flags & TICK_FLAG_SELL) != 0) sellCount++;
        
        // 매수/매도 플래그가 모두 발견되면 종료
        if(buyCount > 0 && sellCount > 0) {
            Print("=== 매수/매도 플래그 발견 ===");
            Print("분석한 틱 수: ", i + 1);
            Print("매수 틱: ", buyCount);
            Print("매도 틱: ", sellCount);
            return true;
        }
    }
    
    Print("=== 매수/매도 플래그 분석 결과 ===");
    Print("분석한 틱 수: ", copied);
    Print("매수 틱: ", buyCount);
    Print("매도 틱: ", sellCount);
    
    return (buyCount > 0 || sellCount > 0);
}

//+------------------------------------------------------------------+
//| 과거 틱 데이터에서 Last 가격 변경 틱 확인                           |
//+------------------------------------------------------------------+
bool CheckLastPriceFlags()
{
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    
    // 최근 10000개의 틱 데이터 복사
    ulong copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 10000);
    
    if(copied <= 0) {
        Print("틱 데이터를 가져오는데 실패했습니다. Error: ", GetLastError());
        return false;
    }
    
    long lastCount = 0;
    long volumeCount = 0;
    ulong totalVolume = 0;
    
    // 틱 데이터 분석
    for(ulong i = 0; i < copied; i++) {
        if((ticks[i].flags & TICK_FLAG_LAST) != 0) {
            lastCount++;
            if(ticks[i].volume > 0) {
                volumeCount++;
                totalVolume += ticks[i].volume;
            }
        }
    }
    
    Print("=== Last 가격 틱 분석 결과 ===");
    Print("분석한 틱 수: ", copied);
    Print("Last 가격 변경 틱: ", lastCount);
    Print("거래량 포함 틱: ", volumeCount);
    Print("총 거래량: ", totalVolume);
    
    return (lastCount > 0);
}

//+------------------------------------------------------------------+
//| 봉 데이터 검증                                                     |
//+------------------------------------------------------------------+
bool ValidateBarData(const TickBarData& bar)
{
    g_validation.Reset();
    
    // 1. 시간 검증
    if(bar.time == 0 || bar.time > TimeCurrent()) {
        g_validation.isValidTime = false;
        g_validation.errorMessage += "잘못된 시간값; ";
    }
    
    // 2. OHLC 검증
    if(bar.open <= 0) {
        g_validation.isValidOpen = false;
        g_validation.errorMessage += "잘못된 시가; ";
    }
    if(bar.high <= 0) {
        g_validation.isValidHigh = false;
        g_validation.errorMessage += "잘못된 고가; ";
    }
    if(bar.low <= 0) {
        g_validation.isValidLow = false;
        g_validation.errorMessage += "잘못된 저가; ";
    }
    if(bar.close <= 0) {
        g_validation.isValidClose = false;
        g_validation.errorMessage += "잘못된 종가; ";
    }
    
    // OHLC 관계 검증
    if(bar.high < bar.low) {
        g_validation.isValidHigh = false;
        g_validation.isValidLow = false;
        g_validation.errorMessage += "고가가 저가보다 낮음; ";
    }
    if(bar.high < bar.open || bar.high < bar.close) {
        g_validation.isValidHigh = false;
        g_validation.errorMessage += "고가가 시가/종가보다 낮음; ";
    }
    if(bar.low > bar.open || bar.low > bar.close) {
        g_validation.isValidLow = false;
        g_validation.errorMessage += "저가가 시가/종가보다 높음; ";
    }
    
    // 3. 거래량 검증
    if(bar.volume <= 0) {
        g_validation.isValidVolume = false;
        g_validation.errorMessage += "���못된 거래량; ";
    }
    
    // 4. 틱 카운트 검증
    if(bar.tickCount <= 0 || bar.tickCount > InpTickCount) {
        g_validation.isValid = false;
        g_validation.errorMessage += "잘못된 틱 카운트; ";
    }
    
    // 전체 유효성 설정
    g_validation.isValid = g_validation.isValidTime && 
                          g_validation.isValidOpen && 
                          g_validation.isValidHigh && 
                          g_validation.isValidLow && 
                          g_validation.isValidClose && 
                          g_validation.isValidVolume;
    
    // 검증 결과 출력
    if(!g_validation.isValid && InpShowDebug) {
        Print("=== 봉 데이터 검증 실패 ===");
        Print("시간: ", TimeToString(bar.time));
        Print("OHLC: ", bar.open, ", ", bar.high, ", ", bar.low, ", ", bar.close);
        Print("거래량: ", bar.volume);
        Print("틱수: ", bar.tickCount);
        Print("오류: ", g_validation.errorMessage);
    }
    
    return g_validation.isValid;
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol, tick)) return;
    
    // 틱 정보 출력
    if(InpShowDebug) {
        string timeStr = TimeToString(tick.time, TIME_DATE|TIME_SECONDS) + 
                        "." + IntegerToString(tick.time_msc % 1000, 3, '0');  // 밀리초 3자리 포맷
        
        Print("=== 틱 정보 ===");
        Print("Time(ms): ", timeStr, " (", tick.time_msc, ")");
        Print("Last: ", tick.last);
        Print("Volume: ", tick.volume);
        Print("Flags: ", tick.flags);
    }
    
    // Last 가격이 변경된 틱만 처리
    if((tick.flags & TICK_FLAG_LAST) == 0) return;
    if(tick.last <= 0) return;
    
    // 동일한 시간의 틱은 한번만 처리 (밀리초 단위로 비교)
    if(tick.time_msc == g_lastTickTime_msc) return;
    g_lastTickTime_msc = tick.time_msc;
    
    // 첫 틱인 경우 새로운 봉 시작
    if(g_currentBar.tickCount == 0) {
        g_currentBar.time = tick.time;
        g_currentBar.time_msc = tick.time_msc;  // 밀리초 정보 저장
        g_currentBar.open = tick.last;
        g_currentBar.high = tick.last;
        g_currentBar.low = tick.last;
        g_currentBar.close = tick.last;
        g_currentBar.volume = tick.volume;
        g_currentBar.tickCount = 1;
    }
    // 기존 봉 업데이트
    else {
        g_currentBar.high = MathMax(g_currentBar.high, tick.last);
        g_currentBar.low = MathMin(g_currentBar.low, tick.last);
        g_currentBar.close = tick.last;
        g_currentBar.volume += tick.volume;
        g_currentBar.tickCount++;
    }
    
    // 지정된 틱 수에 도달하면 봉 완성
    if(g_currentBar.tickCount >= InpTickCount) {
        // 봉 데이터 검증
        if(ValidateBarData(g_currentBar)) {
            if(InpShowDebug) {
                Print("=== 봉 완성 (검증 통과) ===");
                Print("시간: ", TimeToString(g_currentBar.time, TIME_DATE|TIME_SECONDS), 
                      ".", g_currentBar.time_msc % 1000);  // 밀리초 표시 추가
                Print("OHLC: ", g_currentBar.open, ", ", g_currentBar.high, 
                      ", ", g_currentBar.low, ", ", g_currentBar.close);
                Print("거래량: ", g_currentBar.volume);
                Print("틱수: ", g_currentBar.tickCount);
            }
        }
        
        // 새로운 봉 시작
        g_currentBar.Reset();
    }
}

//+------------------------------------------------------------------+
//| 종료 이유를 텍스트로 변환                                           |
//+------------------------------------------------------------------+
string GetUninitReasonText(int reason)
{
    switch(reason) {
        case REASON_PROGRAM:     return "프로그램 정상 종료";
        case REASON_REMOVE:      return "차트에서 EA 제거";
        case REASON_RECOMPILE:   return "프로그램 리컴파일";
        case REASON_CHARTCHANGE: return "심볼 또는 주기 변경";
        case REASON_CHARTCLOSE:  return "차트 종료";
        case REASON_PARAMETERS:  return "입력 파라미터 변경";
        case REASON_ACCOUNT:     return "다른 계정 활성화";
        default:                 return "알 수 없는 이유 (" + IntegerToString(reason) + ")";
    }
} 