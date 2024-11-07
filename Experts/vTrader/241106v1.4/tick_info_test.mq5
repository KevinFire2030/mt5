//+------------------------------------------------------------------+
//|                                              tick_info_test.mq5     |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// 디버깅 설정
input group "=== 디버깅 설정 ==="
input bool   InpDebugMode = true;          // 디버깅 모드 사용
input bool   InpShowBidAsk = true;         // Bid/Ask 표시
input bool   InpShowVolume = true;         // 거래량 표시
input bool   InpShowSpread = true;         // 스프레드 표시
input bool   InpShowTime = true;           // 시간 표시

//+------------------------------------------------------------------+
//| 누적 거래량 정보 구조체                                             |
//+------------------------------------------------------------------+
struct VolumeInfo {
    ulong totalTicks;         // 총 틱 수
    ulong totalTickVolume;    // 누적 틱 볼륨
    double totalRealVolume;   // 누적 실제 거래량
    double avgTickVolume;     // 평균 틱 볼륨
    double avgRealVolume;     // 평균 실제 거래량
};

//+------------------------------------------------------------------+
//| 누적 거래량 분석                                                    |
//+------------------------------------------------------------------+
void ShowVolumeStats()
{
    static VolumeInfo dailyVolume;   // 일간 거래량
    static VolumeInfo totalVolume;   // 전체 거래량
    static datetime lastResetTime = 0;      // 마지막 리셋 시간
    static ulong lastTickTime = 0;       // 마지막 틱 시간을 ulong으로 변경
    
    // 새로운 날이 시작되면 일간 거래량 초기화
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    datetime currentDate = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
    
    if(currentDate > lastResetTime) {
        Print("=== 새로운 날 시작 ===");
        Print("이전 일간 통계:");
        Print(StringFormat(
            "틱 수: %d\n" +
            "틱 볼륨 - 총: %d, 평균: %.2f\n" +
            "실제 거래량 - 총: %.2f, 평균: %.2f", 
            dailyVolume.totalTicks,
            dailyVolume.totalTickVolume, dailyVolume.avgTickVolume,
            dailyVolume.totalRealVolume, dailyVolume.avgRealVolume
        ));
            
        // 구조체 멤버 개별 초기화
        dailyVolume.totalTicks = 0;
        dailyVolume.totalTickVolume = 0;
        dailyVolume.totalRealVolume = 0;
        dailyVolume.avgTickVolume = 0;
        dailyVolume.avgRealVolume = 0;
        
        lastResetTime = currentDate;
    }
    
    // 현재 틱 정보 가져오기
    MqlTick last_tick;
    if(!SymbolInfoTick(_Symbol, last_tick)) return;
    
    // 틱 간격 계산 (ulong 사용)
    ulong tickInterval = last_tick.time_msc - lastTickTime;
    
    // 거래량 업데이트
    if(last_tick.volume > 0) {  // 실제 거래가 있는 경우만
        dailyVolume.totalTicks++;
        dailyVolume.totalTickVolume += last_tick.volume;
        dailyVolume.totalRealVolume += last_tick.volume_real;
        dailyVolume.avgTickVolume = (double)dailyVolume.totalTickVolume / dailyVolume.totalTicks;
        dailyVolume.avgRealVolume = dailyVolume.totalRealVolume / dailyVolume.totalTicks;
        
        totalVolume.totalTicks++;
        totalVolume.totalTickVolume += last_tick.volume;
        totalVolume.totalRealVolume += last_tick.volume_real;
        totalVolume.avgTickVolume = (double)totalVolume.totalTickVolume / totalVolume.totalTicks;
        totalVolume.avgRealVolume = totalVolume.totalRealVolume / totalVolume.totalTicks;
        
        // 매 10틱마다 통계 출력
        if(totalVolume.totalTicks % 10 == 0) {
            Print("\n=== 거래량 통계 ===");
            Print("시간: ", TimeToString(TimeCurrent()));
            Print(StringFormat("틱 간격: %d ms", tickInterval));
            
            Print("\n--- 일간 거래량 ---");
            Print(StringFormat(
                "틱 수: %d\n" +
                "틱 볼륨 - 총: %d, 평균: %.2f\n" +
                "실제 거래량 - 총: %.2f, 평균: %.2f", 
                dailyVolume.totalTicks,
                dailyVolume.totalTickVolume, dailyVolume.avgTickVolume,
                dailyVolume.totalRealVolume, dailyVolume.avgRealVolume
            ));
            
            Print("\n--- 전체 거래량 ---");
            Print(StringFormat(
                "틱 수: %d\n" +
                "틱 볼륨 - 총: %d, 평균: %.2f\n" +
                "실제 거래량 - 총: %.2f, 평균: %.2f", 
                totalVolume.totalTicks,
                totalVolume.totalTickVolume, totalVolume.avgTickVolume,
                totalVolume.totalRealVolume, totalVolume.avgRealVolume
            ));
            Print("------------------------");
        }
    }
    
    lastTickTime = last_tick.time_msc;  // ulong 타입으로 저장
}

//+------------------------------------------------------------------+
//| 틱 정보 출력                                                        |
//+------------------------------------------------------------------+
void ShowTickInfo()
{
    static int tickCount = 0;
    static double lastPrice = 0;
    static ulong lastTime = 0;
    
    MqlTick last_tick;
    if(!SymbolInfoTick(_Symbol, last_tick)) {
        Print("틱 정보를 가져올 수 없습니다!");
        return;
    }
    
    tickCount++;
    
    // 시간 정보
    if(InpShowTime) {
        MqlDateTime dt;
        datetime tickTime = (datetime)(last_tick.time_msc/1000);
        TimeToStruct(tickTime, dt);
        
        // 이전 틱과의 시간 간격 계산
        ulong timeDiff = last_tick.time_msc - lastTime;
        
        Print(StringFormat(
            "시간: %02d:%02d:%02d.%03d (간격: %dms)", 
            dt.hour, dt.min, dt.sec, (int)(last_tick.time_msc%1000),
            (int)timeDiff
        ));
    }
    
    // Bid/Ask 정보
    if(InpShowBidAsk) {
        // 이전 가격과의 변화량 계산
        double priceChange = last_tick.last - lastPrice;
        
        Print(StringFormat(
            "가격: Bid=%.2f, Ask=%.2f, Last=%.2f (변화: %.2f)", 
            last_tick.bid, last_tick.ask, last_tick.last,
            priceChange
        ));
    }
    
    // 거래량 정보
    if(InpShowVolume) {
        Print(StringFormat(
            "거래량: Tick Volume=%d, Real Volume=%.2f", 
            last_tick.volume,      // 틱 볼륨
            last_tick.volume_real  // 실제 거래량
        ));
    }
    
    // 스프레드 정보
    if(InpShowSpread) {
        double spread = (last_tick.ask - last_tick.bid) / _Point;
        Print(StringFormat("스프레드: %.1f pts", spread));
    }
    
    // 틱 플래그 분석
    string flags = "플래그: ";
    if((last_tick.flags & TICK_FLAG_BID) != 0) flags += "BID ";
    if((last_tick.flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
    if((last_tick.flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
    if((last_tick.flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
    if((last_tick.flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
    if((last_tick.flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
    
    Print(flags);
    
    // 틱 카운트와 거래량 누적 정보
    static ulong totalTickVolume = 0;
    static double totalRealVolume = 0;
    totalTickVolume += last_tick.volume;
    totalRealVolume += last_tick.volume_real;
    
    Print(StringFormat(
        "누적정: 틱=%d, Tick Volume=%llu, Real Volume=%.2f", 
        tickCount, totalTickVolume, totalRealVolume
    ));
    
    Print("------------------------");  // 구분선
    
    // 현재 값을 이전 값으로 저장
    lastPrice = last_tick.last;
    lastTime = last_tick.time_msc;
}

//+------------------------------------------------------------------+
//| 당일 일봉 정보 출력                                                 |
//+------------------------------------------------------------------+
void ShowDailyBar()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    datetime today_start = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", 
        dt.year, dt.mon, dt.day));
    
    // 당일 OHLC 가격
    double open = iOpen(_Symbol, PERIOD_D1, 0);
    double high = iHigh(_Symbol, PERIOD_D1, 0);
    double low = iLow(_Symbol, PERIOD_D1, 0);
    double close = iClose(_Symbol, PERIOD_D1, 0);
    
    // 당일 거래량
    long volume = iVolume(_Symbol, PERIOD_D1, 0);
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0);
    
    // 가격 변동폭
    double range = high - low;
    double change = close - open;
    double change_percent = (change / open) * 100;
    
    Print("\n=== 당일 봉 정보 ===");
    Print("날짜: ", TimeToString(today_start, TIME_DATE));
    Print(StringFormat(
        "시가: %.2f\n" +
        "고가: %.2f\n" +
        "저가: %.2f\n" +
        "현재가: %.2f",
        open, high, low, close
    ));
    Print(StringFormat(
        "변동폭: %.2f (%.2f%%)\n" +
        "변화량: %.2f (%.2f%%)",
        range, (range/open)*100,
        change, change_percent
    ));
    Print(StringFormat(
        "거래량 - Tick: %d, Real: %d",
        volume, real_volume
    ));
}

//+------------------------------------------------------------------+
//| 당일 거래량 정보 출력                                               |
//+------------------------------------------------------------------+
void ShowDailyVolume()
{
    static long prev_tick_volume = 0;    // 이전 틱 볼륨
    static long prev_real_volume = 0;    // 이전 실제 거래량
    
    // 당일 거래량
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0);
    
    // 이전 봉과의 비교를 위해 어제 거래량도 가져오기
    long yesterday_tick_volume = iVolume(_Symbol, PERIOD_D1, 1);
    long yesterday_real_volume = iRealVolume(_Symbol, PERIOD_D1, 1);
    
    // 거래량 증가율 계산 (long을 double로 명시적 변환)
    double tick_volume_change = yesterday_tick_volume > 0 ? 
        ((double)(tick_volume - yesterday_tick_volume)) / yesterday_tick_volume * 100 : 0;
    double real_volume_change = yesterday_real_volume > 0 ? 
        ((double)(real_volume - yesterday_real_volume)) / yesterday_real_volume * 100 : 0;
    
    // 전틱대비 변화량 계산
    long tick_volume_delta = prev_tick_volume > 0 ? tick_volume - prev_tick_volume : 0;
    long real_volume_delta = prev_real_volume > 0 ? real_volume - prev_real_volume : 0;
    
    Print(StringFormat(
        "=== 당일 거래량 정보 ===\n" +
        "Tick Volume: %I64d (전일대비: %.1f%%, 전틱대비: %+I64d)\n" +
        "Real Volume: %I64d (전일대비: %.1f%%, 전틱대비: %+I64d)",
        tick_volume, tick_volume_change, tick_volume_delta,
        real_volume, real_volume_change, real_volume_delta
    ));
    
    // 현재 값을 이전 값으로 저장
    prev_tick_volume = tick_volume;
    prev_real_volume = real_volume;
}

//+------------------------------------------------------------------+
//| 대규모 거래량 감지                                                  |
//+------------------------------------------------------------------+
void DetectLargeVolume()
{
    static long prev_real_volume = 0;    // 이전 제 거래량
    
    // 당일 거래량
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0);
    
    // 전틱대비 실제거래량 변화
    long real_volume_delta = real_volume - prev_real_volume;
    
    // 대규모 거래 감지 (실제거래량이 10 이상 증가한 경우)
    if(real_volume_delta >= 10) {
        MqlTick last_tick;
        if(SymbolInfoTick(_Symbol, last_tick)) {
            Print("\n=== 대규모 거래 감지! ===");
            Print(StringFormat(
                "시간: %s\n" +
                "가격: Bid=%.2f, Ask=%.2f, Last=%.2f\n" +
                "틱볼륨: %d (총 %d)\n" +
                "실제거래량: +%d",
                TimeToString(last_tick.time_msc/1000, TIME_DATE|TIME_SECONDS|TIME_MINUTES),
                last_tick.bid, last_tick.ask, last_tick.last,
                last_tick.volume, tick_volume,
                real_volume_delta
            ));
            
            // 거래 플래그 확인
            string flags = "거래 타입: ";
            if((last_tick.flags & TICK_FLAG_BUY) != 0) flags += "매수 ";
            if((last_tick.flags & TICK_FLAG_SELL) != 0) flags += "매도 ";
            Print(flags);
            Print("------------------------");
        }
    }
    
    // 현재 값을 이전 값으로 저장
    prev_real_volume = real_volume;
}

//+------------------------------------------------------------------+
//| 대규모 거래 검색                                                    |
//+------------------------------------------------------------------+
void FindLargeVolumes()
{
    // 현재까지 당일 누적 거래량
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0);
    
    if(tick_volume <= 0) {
        Print("거래량 데이터를 가져올 수 없습니다!");
        return;
    }
    
    // 틱 데이터 수집
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    
    // 현재까지 당일 누적 거래량만큼의 틱 데이터 가져오기
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, tick_volume);
    
    if(copied <= 0) {
        Print("틱 데이터를 가져올 수 없습니다!");
        return;
    }
    
    Print("\n=== 대규모 거래 검색 시작 ===");
    Print("검색 기간: ", TimeToString(ticks[copied-1].time), " - ", TimeToString(ticks[0].time));
    Print("분석할 틱 수: ", copied);
    Print("당일 누적 틱거래량: ", tick_volume);
    Print("당일 누적 실거래량: ", real_volume);
    Print("\n=== 대규모 거래 목록 (실거래량 10 초과) ===");
    
    // 대규모 거래 검색 (실거래량 10 초과)
    for(int i=0; i<copied-1; i++) {
        if(ticks[i].volume_real > 10) {
            Print(StringFormat(
                "시간: %s, 가격: %.2f, 거래량: %.2f, 방향: %s",
                TimeToString(ticks[i].time),
                ticks[i].last,
                ticks[i].volume_real,
                (ticks[i].flags & TICK_FLAG_BUY) ? "매수" : 
                (ticks[i].flags & TICK_FLAG_SELL) ? "매도" : "알수없음"
            ));
            
            // 해당 거래 전후의 가격 변동 확인
            if(i > 0 && i < copied-1) {
                double priceChange = ticks[i-1].last - ticks[i+1].last;
                Print(StringFormat(
                    "가격 변동: %.2f (이전: %.2f, 이후: %.2f)",
                    priceChange,
                    ticks[i+1].last,
                    ticks[i-1].last
                ));
            }
            Print("------------------------");
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!InpDebugMode) return;
    
    static bool analyzed = false;
    if(!analyzed) {
        FindLargeVolumes();  // 한 번만 실행
        analyzed = true;
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== 틱 정보 모니터링 시작 ===");
    Print("심볼: ", _Symbol);
    Print("틱 사이즈: ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
    Print("틱 값어치: ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
    Print("포인트: ", SymbolInfoDouble(_Symbol, SYMBOL_POINT));
    Print("최소 거래량: ", SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
    Print("최대 거래량: ", SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
    Print("거래량 단위: ", SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP));
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");  // 화면에서 코멘트 제거
} 