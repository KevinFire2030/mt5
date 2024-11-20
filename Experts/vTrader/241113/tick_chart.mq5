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
input int InpTickCount = 100;        // 틱 개수
input bool InpShowDebug = true;      // 디버그 메시지 표시 (테스트를 위해 true로 변경)

// 전역 변수
long g_lastTickTime_msc = 0;    // datetime -> long (밀리초 단위)
bool g_hasTradeTicks = false;        // 매수/매도 플래그 존재 여부
double g_barSpeed = 0;     // 봉 생성 속도 (초)
double g_prevClose = 0;     // 이전 봉의 종가
double g_lastPrice = 0;     // 이전 체결가

// 전역 변수에 추가
#define STRENGTH_PERIOD 20      // 강도 계산을 위한 이동평균 기간
double g_volumeMA = 0;          // 거래량 이동평균
double g_trueRangeMA = 0;       // TR 이동평균
double g_priceRangeMA = 0;      // 가격변동폭 이동평균

// 봉 데이터 구조체
struct TickBarData {
    datetime time;        // 시간 (초)
    long time_msc;       // 시간 (밀리초) 추가
    long end_time_msc;   // 마지막 틱 시간 (밀리초) 추가
    double open;         // 시가
    double high;         // 고가
    double low;          // 저가
    double close;        // 종가
    ulong volume;        // 거래량
    int tickCount;       // 틱 수
    ulong buyVolume;     // 매수 체결량
    ulong sellVolume;    // 매도 체결량
    
    void Reset() {
        time = 0;
        time_msc = 0;    
        end_time_msc = 0;  // 마지막 틱 시간 초기화 추가
        open = 0;
        high = 0;
        low = 0;
        close = 0;
        volume = 0;
        tickCount = 0;
        buyVolume = 0;
        sellVolume = 0;
    }
};



// 전역 변수
TickBarData g_currentBar;    // 현재 봉 데이터

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


// 봉 데이터 저장 함수 추가
void SaveBarData(const TickBarData& bar, int index) {
    string prefix = "TickChart_" + _Symbol + "_";
    
    GlobalVariableSet(prefix + "Index", index);
    GlobalVariableSet(prefix + "Time", bar.time);
    GlobalVariableSet(prefix + "TimeMsc", bar.time_msc);
    GlobalVariableSet(prefix + "Open", bar.open);
    GlobalVariableSet(prefix + "High", bar.high);
    GlobalVariableSet(prefix + "Low", bar.low);
    GlobalVariableSet(prefix + "Close", bar.close);
    GlobalVariableSet(prefix + "Volume", bar.volume);
    GlobalVariableSet(prefix + "IsNewBar", 1);  // 새로운 봉 플래그
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol, tick)) return;
    
    // Last 가격이 변경된 틱만 처리
    if((tick.flags & TICK_FLAG_LAST) == 0) return;
    if(tick.last <= 0) return;
    
    // 동일한 시간 틱은 한번만 처리 (밀리초 단위로 비교)
    if(tick.time_msc == g_lastTickTime_msc) return;
    g_lastTickTime_msc = tick.time_msc;
    
    // 틱 정보 출력
    if(InpShowDebug) {
        string timeStr = TimeToString(tick.time, TIME_DATE|TIME_SECONDS) + 
                        "." + IntegerToString(tick.time_msc % 1000, 3, '0');
        //Print("틱>> [", timeStr, "] Last: ", tick.last, ", Volume: ", tick.volume, ", Flags: ", tick.flags);
    }
    
    // 첫 틱인 경우 새로운 봉 시작
    if(g_currentBar.tickCount == 0) {
        g_currentBar.time = tick.time;
        g_currentBar.time_msc = tick.time_msc;
        g_currentBar.open = tick.last;
        g_currentBar.high = tick.last;
        g_currentBar.low = tick.last;
        g_currentBar.close = tick.last;
        g_currentBar.volume = tick.volume;
        g_currentBar.tickCount = 1;
        g_lastPrice = tick.last;  // 첫 틱의 가격 저장
    }
    // 기존 봉 업데이트
    else {
        g_currentBar.high = MathMax(g_currentBar.high, tick.last);
        g_currentBar.low = MathMin(g_currentBar.low, tick.last);
        g_currentBar.close = tick.last;
        g_currentBar.volume += tick.volume;
        
        // 매수/매도 체결량 업데이트 (가격 변화 기준)
        if(g_lastPrice > 0) {  // 첫 틱이 아닌 경우에만
            if(tick.last > g_lastPrice) g_currentBar.buyVolume += tick.volume;
            else if(tick.last < g_lastPrice) g_currentBar.sellVolume += tick.volume;
            // 동일 가격은 이전 추세 유지 또는 중립으로 처리
        }
        
        g_lastPrice = tick.last;  // 현재 가격 저장
        g_currentBar.tickCount++;
        g_currentBar.end_time_msc = tick.time_msc;
    }
    
    // 지정된 틱 수에 도달하면 봉 완성
    if(g_currentBar.tickCount >= InpTickCount) {
        // 글로벌 변수로 데이터 저장
        static int barIndex = 0;
        SaveBarData(g_currentBar, barIndex++);
                
        if(InpShowDebug) {
            string timeStr = TimeToString(g_currentBar.time, TIME_DATE|TIME_SECONDS) + 
                           "." + IntegerToString(g_currentBar.time_msc % 1000, 3);
            double timeDiff = (g_currentBar.end_time_msc - g_currentBar.time_msc) / 1000.0;
            
            // True Range 계산
            double highLow = g_currentBar.high - g_currentBar.low;
            double highPrevClose = (g_prevClose > 0) ? MathAbs(g_currentBar.high - g_prevClose) : 0;
            double lowPrevClose = (g_prevClose > 0) ? MathAbs(g_currentBar.low - g_prevClose) : 0;
            double trueRange = MathMax(highLow, MathMax(highPrevClose, lowPrevClose));
            
            // 속도 계산 (TR/초)
            double speed = (timeDiff > 0) ? trueRange / timeDiff : 0;
            
            // 체결 강도 계산 (매수 비율)
            double strength = 50.0;  // 기본값 (중립)
            if(g_currentBar.buyVolume + g_currentBar.sellVolume > 0) {
                strength = (double)g_currentBar.buyVolume / (g_currentBar.buyVolume + g_currentBar.sellVolume) * 100.0;
            }
            
            // 방향 표시 (체결 강도 기반)
            string direction;
            if(strength >= 65) direction = "⇈";        // 강한 매수세
            else if(strength >= 55) direction = "↑";   // 약한 매수세
            else if(strength >= 45) direction = "=";    // 중립
            else if(strength >= 35) direction = "↓";   // 약한 매도세
            else direction = "⇊";                      // 강한 매도세
            
            // 이동평균 업데이트
            g_volumeMA = (g_volumeMA * (STRENGTH_PERIOD-1) + g_currentBar.volume) / STRENGTH_PERIOD;
            g_trueRangeMA = (g_trueRangeMA * (STRENGTH_PERIOD-1) + trueRange) / STRENGTH_PERIOD;
            g_priceRangeMA = (g_priceRangeMA * (STRENGTH_PERIOD-1) + highLow) / STRENGTH_PERIOD;
            
            // 각종 강도 계산
            double volumeStrength = (g_volumeMA > 0) ? (double)g_currentBar.volume / g_volumeMA * 100 : 100;
            double trStrength = (g_trueRangeMA > 0) ? trueRange / g_trueRangeMA * 100 : 100;
            double rangeStrength = (g_priceRangeMA > 0) ? highLow / g_priceRangeMA * 100 : 100;
            
            // 종합 강도 계산 (세 가지 강도의 평균)
            double totalStrength = (volumeStrength + trStrength + rangeStrength) / 3.0;
            
            // 강도 표시
            string strengthSymbol;
            if(totalStrength >= 200) strengthSymbol = "⚡⚡⚡";      // 매우 강함
            else if(totalStrength >= 150) strengthSymbol = "⚡⚡";   // 강함
            else if(totalStrength >= 100) strengthSymbol = "⚡";     // 다소 강함
            else if(totalStrength >= 50) strengthSymbol = "•";      // 보통
            else strengthSymbol = "○";                              // 약함
            
            Print("봉>> [", timeStr, "] ",
                  g_currentBar.open, ", ", 
                  g_currentBar.high, ", ", 
                  g_currentBar.low, ", ", 
                  g_currentBar.close, ", ",
                  "거래량: ", g_currentBar.volume, ", ",
                  "틱수: ", g_currentBar.tickCount, ", ",
                  "시간차: ", DoubleToString(timeDiff, 3), "s, ",
                  "속도: ", DoubleToString(speed, 2), "TR/s, ",
                  "방향(체결강도): ", DoubleToString(strength, 1), "%(", direction, "), ",
                  "세기: ", DoubleToString(totalStrength, 0), "%(", strengthSymbol, ")");
        }
        
        // 다음 봉을 위해 현재 종가 저장
        g_prevClose = g_currentBar.close;
        
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