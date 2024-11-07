//+------------------------------------------------------------------+
//|                                             tick_info_test2.mq5     |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      ""
#property version   "1.00"

// 입력 변수
input group "=== 모니터링 설정 ==="
input bool   InpShowBidAsk = true;         // Bid/Ask 표시
input bool   InpShowVolume = true;         // 거래량 표시
input bool   InpShowSpread = true;         // 스프레드 표시

// 전역 변수
MqlTick last_tick;                         // 마지막 틱 정보
ulong   last_tick_time = 0;                // 마지막 틱 시간
double  last_price = 0;                    // 마지막 가격
ulong   total_ticks = 0;                   // 총 틱 수
double  total_volume = 0;                  // 총 거래량

//+------------------------------------------------------------------+
//| 틱 정보 가져오기                                                    |
//+------------------------------------------------------------------+
bool GetTickInfo()
{
    return SymbolInfoTick(_Symbol, last_tick);
}

//+------------------------------------------------------------------+
//| 틱 간격 계산                                                        |
//+------------------------------------------------------------------+
ulong CalculateTickInterval()
{
    if(last_tick_time == 0) return 0;
    return last_tick.time_msc - last_tick_time;
}

//+------------------------------------------------------------------+
//| 가격 변화 계산                                                      |
//+------------------------------------------------------------------+
double CalculatePriceChange()
{
    if(last_price == 0) return 0;
    return last_tick.last - last_price;
}

//+------------------------------------------------------------------+
//| 시간 정보 문자열 생성                                               |
//+------------------------------------------------------------------+
void PrintTimeInfo()
{
    Print(StringFormat("시간: %s.%03d, 틱 간격: %d ms", 
        TimeToString(last_tick.time, TIME_DATE|TIME_SECONDS),
        last_tick.time_msc%1000,
        CalculateTickInterval()));
}

//+------------------------------------------------------------------+
//| 가 출력                                                      |
//+------------------------------------------------------------------+
void PrintPriceInfo()
{
    if(!InpShowBidAsk) return;
    
    Print(StringFormat("Bid: %.5f, Ask: %.5f, Last: %.5f (%+.5f)",
        last_tick.bid,
        last_tick.ask,
        last_tick.last,
        CalculatePriceChange()));
}

//+------------------------------------------------------------------+
//| 거래량 정보 출력                                                    |
//+------------------------------------------------------------------+
void PrintVolumeInfo()
{
    if(!InpShowVolume) return;
    
    Print(StringFormat("틱 거래량: %d, 실제 거래량: %.2f, 누적 거래량: %.2f",
        last_tick.volume,
        last_tick.volume_real,
        total_volume));
}

//+------------------------------------------------------------------+
//| 스프레드 정보 출력                                                  |
//+------------------------------------------------------------------+
void PrintSpreadInfo()
{
    if(!InpShowSpread) return;
    
    double spread = (last_tick.ask - last_tick.bid) / _Point;
    Print(StringFormat("스프레드: %.1f pts", spread));
}

//+------------------------------------------------------------------+
//| 틱 플래그 분석                                                      |
//+------------------------------------------------------------------+
string AnalyzeFlags(int flags)
{
    string result = "";
    if((flags & TICK_FLAG_BID) != 0) result += "BID(2) ";
    if((flags & TICK_FLAG_ASK) != 0) result += "ASK(4) ";
    if((flags & TICK_FLAG_LAST) != 0) result += "LAST(8) ";
    if((flags & TICK_FLAG_VOLUME) != 0) result += "VOLUME(16) ";
    if((flags & TICK_FLAG_BUY) != 0) result += "BUY(1000) ";
    if((flags & TICK_FLAG_SELL) != 0) result += "SELL(2000) ";
    return result;
}

//+------------------------------------------------------------------+
//| 틱 정보 업데이트                                                    |
//+------------------------------------------------------------------+
void UpdateTickData()
{
    total_volume += last_tick.volume_real;
    last_tick_time = last_tick.time_msc;
    last_price = last_tick.last;
}

//+------------------------------------------------------------------+
//| 틱 데이터 분석 및 출력 함수 추가                                    |
//+------------------------------------------------------------------+
void AnalyzeAndPrintTickData()
{
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    
    // 현재 시간부터 과거 10,000,000개의 틱 데이터 가져오기
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 100000000);
    
    if(copied <= 0)
    {
        Print("틱 데이터를 가져올 수 없습니다!");
        return;
    }
    
    int noRealVolumeCount = 0;
    
    // real_volume이 없는 틱의 정보 출력
    for(int i = 0; i < copied; i++)
    {
        if(ticks[i].volume_real == 0)
        {
            noRealVolumeCount++;
            Print(StringFormat("틱시간: %s.%03d, Bid: %.5f, Ask: %.5f, Last: %.5f, 틱볼륨: %d, 플래그: %d [%s]",
                TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS),
                ticks[i].time_msc%1000,
                ticks[i].bid,
                ticks[i].ask,
                ticks[i].last,
                ticks[i].volume,
                ticks[i].flags,
                AnalyzeFlags(ticks[i].flags)));
        }
    }
    
    double noRealVolumePercentage = (double)noRealVolumeCount / copied * 100.0;
    
    Print("=== 틱 데이터 분석 결과 ===");
    Print(StringFormat("총 틱 수: %d", copied));
    Print(StringFormat("real_volume이 없는 틱 수: %d", noRealVolumeCount));
    Print(StringFormat("비중: %.2f%%", noRealVolumePercentage));
    Print("------------------------");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== 틱 모니터링 시작 ===");
    Print("심볼: ", _Symbol);
    
    // 틱 데이터 분석 및 출력 함수 호출
    AnalyzeAndPrintTickData();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== 틱 모니터링 종료 ===");
    Print("총 틱 수: ", total_ticks);
    Print("총 거래량: ", total_volume);
}

//+------------------------------------------------------------------+
//| 틱 정보 처리 및 출력                                                |
//+------------------------------------------------------------------+
void PrintTickInfo()
{
    total_ticks++;
    
    if(!GetTickInfo())
        return;
    
    Print("=== 틱 정보 ===");
    PrintTimeInfo();
    PrintPriceInfo();
    PrintVolumeInfo();
    PrintSpreadInfo();
    Print("총 틱 수:", total_ticks);
    
    // 플래그 정보 출력
    Print(StringFormat("플래그: %d [%s]", 
        last_tick.flags,
        AnalyzeFlags(last_tick.flags)));
        
    Print("------------------------");
    
    UpdateTickData();
}

//+------------------------------------------------------------------+
//| 일봉 데이터 출력                                                    |
//+------------------------------------------------------------------+
void PrintDailyBarInfo()
{
    static ulong last_real_volume = 0;  // 마지막 실거래량
    static ulong last_tick_volume = 0;  // 마지막 틱거래량
    
    MqlRates daily_rates[];
    ArraySetAsSeries(daily_rates, true);
    
    // 현재 일봉 데이터 가져오기
    if(CopyRates(_Symbol, PERIOD_D1, 0, 1, daily_rates) != 1)
    {
        Print("일봉 데이터를 가져올 수 없습니다");
        return;
    }
    
    // 거래량이 변경된 경우에만 출력
    ulong current_real_volume = (ulong)daily_rates[0].real_volume;
    ulong current_tick_volume = (ulong)daily_rates[0].tick_volume;
    
    if(current_real_volume == last_real_volume && current_tick_volume == last_tick_volume)
        return;
    
    // 시가 대비 현재가 변동폭
    double current_price = last_tick.last;
    double open_price = daily_rates[0].open;
    double price_change = current_price - open_price;
    double change_percent = (price_change / open_price) * 100;
    
    // 고가/저가 대비 현재가 비율
    double high_price = daily_rates[0].high;
    double low_price = daily_rates[0].low;
    double total_range = high_price - low_price;
    double current_position = ((current_price - low_price) / total_range) * 100;
    
    // 일봉 거래량 정보
    long daily_tick_volume = daily_rates[0].tick_volume;
    long daily_real_volume = daily_rates[0].real_volume;
    
    Print("=== 일봉 정보 ===");
    Print(StringFormat("시간: %s", TimeToString(daily_rates[0].time)));
    Print(StringFormat("시가: %.5f", open_price));
    Print(StringFormat("고가: %.5f", high_price));
    Print(StringFormat("저: %.5f", low_price));
    Print(StringFormat("현재가: %.5f", current_price));
    Print(StringFormat("변동폭: %.5f (%.2f%%)", price_change, change_percent));
    Print(StringFormat("고저대비: %.1f%% (100%%=고가, 0%%=저가)", current_position));
    Print(StringFormat("일봉 틱거래량: %I64d", daily_tick_volume));
    Print(StringFormat("일봉 실거래량: %I64d", daily_real_volume));
    
    // 틱 분석
    MqlTick ticks[];
    int quote_ticks = 0;     // 호가 변경 틱 (Flag = 6)
    int trade_ticks = 0;     // 실제 거래 틱 (Flag = 24)
    int total_analyzed_ticks = 0;
    
    datetime start_time = daily_rates[0].time;
    datetime end_time = TimeCurrent();
    
    int copied = (int)CopyTicks(_Symbol, ticks, COPY_TICKS_ALL,  // 명시적 형변환 추가
        (long)(start_time * 1000), 
        (long)(end_time * 1000));
    
    if(copied > 0)
    {
        total_analyzed_ticks = copied;
        
        for(int i = 0; i < total_analyzed_ticks; i++)  // copied 대신 total_analyzed_ticks 사용
        {
            // 틱 플래그 분석
            int flags = ticks[i].flags;
            
            // 호가 변경 틱 (BID + ASK)
            if((flags & (TICK_FLAG_BID|TICK_FLAG_ASK)) == (TICK_FLAG_BID|TICK_FLAG_ASK))
                quote_ticks++;
                
            // 실제 거래 틱 (LAST + VOLUME)
            if((flags & (TICK_FLAG_LAST|TICK_FLAG_VOLUME)) == (TICK_FLAG_LAST|TICK_FLAG_VOLUME))
                trade_ticks++;
        }
    }
    
    // 거래량 데이터 출력
    PrintTickAnalysis(quote_ticks, trade_ticks, total_analyzed_ticks, start_time, end_time, current_real_volume);
    
    last_real_volume = current_real_volume;
    last_tick_volume = current_tick_volume;
}

//+------------------------------------------------------------------+
//| 틱 분석 결과 출력                                                   |
//+------------------------------------------------------------------+
void PrintTickAnalysis(int quote_ticks, int trade_ticks, int total_analyzed_ticks,
                      datetime start_time, datetime end_time, ulong current_real_volume)
{
    double elapsed_seconds = (double)(end_time - start_time);
    double quote_ticks_per_sec = elapsed_seconds > 0 ? quote_ticks / elapsed_seconds : 0;
    double trade_ticks_per_sec = elapsed_seconds > 0 ? trade_ticks / elapsed_seconds : 0;
    double avg_volume_per_trade = trade_ticks > 0 ? (double)current_real_volume / trade_ticks : 0;
    double volume_per_sec = trade_ticks_per_sec * avg_volume_per_trade;
    
    string time_str = StringFormat("%s ~ %s (%.1f분)", 
        TimeToString(start_time, TIME_MINUTES),
        TimeToString(end_time, TIME_MINUTES),
        elapsed_seconds/60);
    
    // MT5 거래량 정보 가져오기
    long mt5_tick_volume = iVolume(_Symbol, PERIOD_D1, 0);
    long mt5_real_volume = iRealVolume(_Symbol, PERIOD_D1, 0);
    
    Print("=== 틱 분석 결과 ===");
    Print(StringFormat("MT5 틱거래량: %I64d", mt5_tick_volume));
    Print(StringFormat("MT5 실거래량: %I64d", mt5_real_volume));
    Print("분석 기간: ", time_str);
    
    // 호가 변경 틱 정보
    Print(StringFormat("호가변경틱: %d (%.1f%%) - %.1f틱/초", 
        quote_ticks, 
        total_analyzed_ticks > 0 ? (quote_ticks * 100.0 / total_analyzed_ticks) : 0,
        quote_ticks_per_sec));
    
    // 실제 거래 틱 정보
    Print(StringFormat("실제거래틱: %d (%.1f%%) - %.1f틱/초", 
        trade_ticks,
        total_analyzed_ticks > 0 ? (trade_ticks * 100.0 / total_analyzed_ticks) : 0,
        trade_ticks_per_sec));
    
    // 거래량 분석
    Print("거래량 분석:");
    Print(StringFormat("- 총 실거래량: %I64u (%.1f/분)", 
        current_real_volume,
        volume_per_sec * 60));
    Print(StringFormat("- 평균 거래량/틱: %.1f", avg_volume_per_trade));
    Print(StringFormat("- 초당 거래량: %.1f (%.1f/분)", 
        volume_per_sec,
        volume_per_sec * 60));
    Print("------------------------");
}

//+------------------------------------------------------------------+
//| 틱 정보 처리 및 출력 2                                              |
//+------------------------------------------------------------------+
void PrintTickInfo2()
{
    total_ticks++;
    
    if(!GetTickInfo())
        return;
    
    // MT5 거래량 정보 가져오기
    long trade_tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 실거래 틱볼륨
    long total_real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
    
    // 실제 거래 발생 여부 확인
    bool isRealTrade = (last_tick.flags & (TICK_FLAG_LAST|TICK_FLAG_VOLUME)) == (TICK_FLAG_LAST|TICK_FLAG_VOLUME);
    
    Print("=== 틱 정보 ===");
    Print(StringFormat("실 : %I64d", trade_tick_volume));
    Print(StringFormat("실제 거래량: %I64d", total_real_volume));
    
    PrintTimeInfo();
    PrintPriceInfo();
    PrintVolumeInfo();
    PrintSpreadInfo();
    Print("총 틱 수:", total_ticks);
    
    if(isRealTrade)
    {
        string tradeType = "매도";
        if((last_tick.flags & TICK_FLAG_BUY) != 0) 
            tradeType = "매수";
            
        Print(StringFormat("실제 거래 발: %s, 가격: %.5f, 거래량: %.2f", 
            tradeType,
            last_tick.last,
            last_tick.volume_real));
    }
    
    Print("------------------------");
    
    UpdateTickData();
}

//+------------------------------------------------------------------+
//| 틱 정보 처리 및 출력 3                                              |
//+------------------------------------------------------------------+
void PrintTickInfo3()
{
    total_ticks++;
    
    if(!GetTickInfo())
        return;
    
    // 실제 거래 발생 여부 확인 (VOLUME 플래그만으로 판단)
    bool isRealTrade = (last_tick.flags & TICK_FLAG_VOLUME) != 0 && last_tick.volume_real > 0;
    
    if(!isRealTrade)
        return;  // 실제 거래가 아니면 출력하지 않음
    
    // MT5 거래량 정보 가져오기
    long trade_tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 실거래 틱볼륨
    long total_real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
    
    // 거래 방향 확인
    string tradeType = "매도";
    if((last_tick.flags & TICK_FLAG_BUY) != 0) 
        tradeType = "매수";
    
    Print("=== 실제 거래 발생 ===");
    Print(StringFormat("틱시간: %s.%03d", 
        TimeToString(last_tick.time, TIME_DATE|TIME_SECONDS),
        last_tick.time_msc%1000));
    Print(StringFormat("실거래 틱볼륨: %I64d", trade_tick_volume));
    Print(StringFormat("실제 거래량: %I64d", total_real_volume));
    Print(StringFormat("거래 방향: %s", tradeType));
    Print(StringFormat("거래 가격: %.5f (Bid: %.5f, Ask: %.5f)", 
        last_tick.last,
        last_tick.bid,
        last_tick.ask));
    Print(StringFormat("거래량: %.2f", last_tick.volume_real));
    Print(StringFormat("플래그: %d", last_tick.flags));
    Print("------------------------");
}

//+------------------------------------------------------------------+
//| 틱 정보 처리 및 출력 4                                              |
//+------------------------------------------------------------------+
void PrintTickInfo4()
{
    total_ticks++;
    
    if(!GetTickInfo())
        return;
    
    // 모든 틱 정보 출력
    Print("=== 틱 정보 ===");
    Print(StringFormat("틱시간: %s.%03d", 
        TimeToString(last_tick.time, TIME_DATE|TIME_SECONDS),
        last_tick.time_msc%1000));
    Print(StringFormat("Bid: %.5f, Ask: %.5f, Last: %.5f", 
        last_tick.bid,
        last_tick.ask,
        last_tick.last));
    Print(StringFormat("틱볼륨: %d, 실거래량: %.2f", 
        last_tick.volume,
        last_tick.volume_real));
    Print(StringFormat("플래그: %d [%s]", 
        last_tick.flags,
        AnalyzeFlags(last_tick.flags)));
        
    // 실제 거래 발생 여부 확인 (실거래량이 있는 경우)
    if(last_tick.volume_real > 0) {
        string tradeType = (last_tick.flags & TICK_FLAG_BUY) != 0 ? "매수" : "매도";
        Print("실제 거래 발생: ", tradeType);
        
        // MT5 거래량 정보 가져오기
        long trade_tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 실거래 틱볼륨
        long total_real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
        
        // MT5 거래량 정보 출력하기
        Print(StringFormat("실거래 틱볼륨: %I64d", trade_tick_volume));
        Print(StringFormat("실제 거래량: %I64d", total_real_volume));
    }
    
    Print(StringFormat("총 틱수: %d", total_ticks));
    Print("------------------------");
}

//+------------------------------------------------------------------+
//| Tick function                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
  //  PrintTickInfo4();     // 새로운 함수 사용
} 