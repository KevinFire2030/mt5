//+------------------------------------------------------------------+
//|                                                 tick_analysis.mq5   |
//|                                                   Copyright 2024    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

//--- 입력 파라미터
input int      MAGIC_NUMBER = 123456;    // 매직 넘버
input string   TRADE_COMMENT = "Tick Analysis"; // 거래 코멘트
input int      TICK_STEP = 100;          // 틱단위: 100

//+------------------------------------------------------------------+
//| 마지막 틱 정보 출력 함수                                           |
//+------------------------------------------------------------------+
void PrintLastTickInfo()
{
    MqlTick last_tick;
    if(!SymbolInfoTick(_Symbol, last_tick))
    {
        Print("틱 정보를 가져오는데 실패했습니다!");
        return;
    }
    
    PrintFormat("========== 마지막 틱 정보 상세 ==========");
    PrintFormat("심: %s", _Symbol);
    PrintFormat("시간: %s", TimeToString(last_tick.time, TIME_DATE|TIME_SECONDS));
    PrintFormat("밀리초: %I64d", last_tick.time_msc);           // 밀리초 단위 시간
    PrintFormat("Bid: %.5f", last_tick.bid);                    // 매수 호가
    PrintFormat("Ask: %.5f", last_tick.ask);                    // 매도 호가
    PrintFormat("Last: %.5f", last_tick.last);                  // 마지막 거래 가격
    PrintFormat("Volume: %d", last_tick.volume);                // 거래량
    PrintFormat("Volume_real: %.2f", last_tick.volume_real);    // 실제 거래량
    PrintFormat("시간(초): %d", (int)last_tick.time);           // 틱 시간(초)
    PrintFormat("Flags: %u", last_tick.flags);                  // 틱 플래그
    
    // 스프레드 계산
    double spread = last_tick.ask - last_tick.bid;
    PrintFormat("스프레드: %.5f (%d 포인트)", 
                spread, 
                (int)((spread) / _Point));
                
    // 틱 플래그 해석
    string flags = "";
    if((last_tick.flags & TICK_FLAG_BID) != 0) flags += "BID ";
    if((last_tick.flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
    if((last_tick.flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
    if((last_tick.flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
    if((last_tick.flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
    if((last_tick.flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
    
    PrintFormat("플래그 설명: %s", flags);
    PrintFormat("=======================================");
}

//+------------------------------------------------------------------+
//| 과거 틱 분석 함수                                                  |
//+------------------------------------------------------------------+
void AnalyzeHistoricalTicks()
{
    MqlTick ticks[];
    datetime from = D'2024.11.01 00:00';  // 11월 1일부터
    datetime to = D'2024.11.08 00:00';    // 11월 8일까지
    
    // 틱 데이터 복사
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 
                          (ulong)from * 1000, (ulong)to * 1000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    Print("분석할 틱 데이터 수: ", copied);
    
    // 부분 계약 거래 찾기
    for(int i = 0; i < copied; i++)
    {
        if(ticks[i].volume_real < 1.0 && ticks[i].volume_real > 0)
        {
            PrintFormat("=== 부분 계약 거래 발견 ===");
            PrintFormat("시: %s", TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS));
            PrintFormat("Volume: %d", ticks[i].volume);
            PrintFormat("Volume_real: %.2f", ticks[i].volume_real);
            PrintFormat("Bid: %.5f", ticks[i].bid);
            PrintFormat("Ask: %.5f", ticks[i].ask);
            PrintFormat("Last: %.5f", ticks[i].last);
            PrintFormat("==========================");
        }
    }
}

//+------------------------------------------------------------------+
//| 틱 데이터를 CSV로 저장하는 함수                                    |
//+------------------------------------------------------------------+
void SaveTicksToCSV()
{
    MqlTick ticks[];
    datetime from = D'2024.11.07 00:00';
    datetime to = D'2024.11.08 00:00';
    
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 
                          (ulong)from * 1000, (ulong)to * 1000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    // 파일명 생성
    string filename = "ticks_" + _Symbol + "_" + TimeToString(from, TIME_DATE) + ".csv";
    
    // 파일 생성 (MQL5/Files 폴더에 저장)
    int handle = FileOpen(filename, FILE_WRITE|FILE_ANSI);
    
    if(handle == INVALID_HANDLE)
    {
        Print("파일 생성 실패. Error = ", GetLastError());
        return;
    }
    
    // 헤더 작성
    FileWrite(handle, 
             "time,time_msc,bid,ask,last,volume,volume_real,flags");
             
    // 데이터 작성
    for(int i = 0; i < copied; i++)
    {
        string line = StringFormat("%s,%I64d,%s,%s,%s,%d,%s,%u",
                    TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS),
                    ticks[i].time_msc,
                    DoubleToString(ticks[i].bid, _Digits),
                    DoubleToString(ticks[i].ask, _Digits),
                    DoubleToString(ticks[i].last, _Digits),
                    ticks[i].volume,
                    DoubleToString(ticks[i].volume_real, 2),
                    ticks[i].flags);
        FileWriteString(handle, line + "\n");
    }
    
    FileClose(handle);
    Print("틱 데이터가 MQL5/Files/", filename, "에 저장되었습니다. 총 ", copied, "개의 틱");
}

//+------------------------------------------------------------------+
//| 소규모 거래 분석 함수                                              |
//+------------------------------------------------------------------+
void AnalyzeSmallTrades()
{
    MqlTick ticks[];
    datetime from = D'2024.11.01 00:00';  // 11월 1일부터
    datetime to = D'2024.11.08 00:00';    // 11월 8일까지
    
    //  데이터 복사
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 
                          (ulong)from * 1000, (ulong)to * 1000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    Print("분석 시작: 총 ", copied, "개의 틱 데이터");
    int small_trades = 0;  // 소규모 거래 카운터
    
    // 소규모 거래 찾기
    for(int i = 0; i < copied; i++)
    {
        if(ticks[i].volume_real < 1.0 && ticks[i].volume_real > 0)
        {
            small_trades++;
            PrintFormat("=== 소규모 거래 #%d ===", small_trades);
            PrintFormat("시간: %s", TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS));
            PrintFormat("Volume(정수): %d", ticks[i].volume);
            PrintFormat("Volume_real(실수): %.2f", ticks[i].volume_real);
            PrintFormat("Bid: %.5f", ticks[i].bid);
            PrintFormat("Ask: %.5f", ticks[i].ask);
            PrintFormat("Last: %.5f", ticks[i].last);
            PrintFormat("Flags: %u", ticks[i].flags);
            
            // 플래그 해석
            string flags = "";
            if((ticks[i].flags & TICK_FLAG_BID) != 0) flags += "BID ";
            if((ticks[i].flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
            if((ticks[i].flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
            if((ticks[i].flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
            if((ticks[i].flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
            if((ticks[i].flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
            
            PrintFormat("플래그 설명: %s", flags);
            PrintFormat("==========================");
        }
    }
    
    PrintFormat("분석 완료: %d개의 소규모 거래 발견", small_trades);
}

//+------------------------------------------------------------------+
//| 볼륨 범위 분석 함수                                                |
//+------------------------------------------------------------------+
void AnalyzeVolumeRange()
{
    MqlTick ticks[];
    
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 10000000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    Print("분석 시작: 총 ", copied, "개의 틱 데이터");
    
    // 초기값 설정 - 첫 번째 유효한 Volume 찾기
    int start_index = 0;
    for(; start_index < copied; start_index++)
    {
        if(ticks[start_index].volume > 0)
            break;
    }
    
    if(start_index >= copied)
    {
        Print("유효한 거래량이 없습니다.");
        return;
    }
    
    ulong min_volume = ticks[start_index].volume;
    ulong max_volume = ticks[start_index].volume;
    double min_volume_real = ticks[start_index].volume_real;
    double max_volume_real = ticks[start_index].volume_real;
    
    datetime min_volume_time = ticks[start_index].time;
    datetime max_volume_time = ticks[start_index].time;
    datetime min_volume_real_time = ticks[start_index].time;
    datetime max_volume_real_time = ticks[start_index].time;
    
    // 볼륨 범위 분석 (Volume > 0인 경우만)
    for(int i = start_index + 1; i < copied; i++)
    {
        if(ticks[i].volume == 0) continue;  // Volume이 0인 경우 제외
        
        // Volume 분석
        if(ticks[i].volume < min_volume)
        {
            min_volume = ticks[i].volume;
            min_volume_time = ticks[i].time;
        }
        if(ticks[i].volume > max_volume)
        {
            max_volume = ticks[i].volume;
            max_volume_time = ticks[i].time;
        }
        
        // Volume_real 분석
        if(ticks[i].volume_real < min_volume_real)
        {
            min_volume_real = ticks[i].volume_real;
            min_volume_real_time = ticks[i].time;
        }
        if(ticks[i].volume_real > max_volume_real)
        {
            max_volume_real = ticks[i].volume_real;
            max_volume_real_time = ticks[i].time;
        }
    }
    
    // 결과 출력
    PrintFormat("\n=== 볼륨 범위 분석 결과 (Volume > 0) ===");
    PrintFormat("Volume 범위:");
    PrintFormat("  최소: %d (시간: %s)", min_volume, TimeToString(min_volume_time, TIME_DATE|TIME_SECONDS));
    PrintFormat("  최대: %d (시간: %s)", max_volume, TimeToString(max_volume_time, TIME_DATE|TIME_SECONDS));
    PrintFormat("Volume_real 범위:");
    PrintFormat("  최소: %.2f (시간: %s)", min_volume_real, TimeToString(min_volume_real_time, TIME_DATE|TIME_SECONDS));
    PrintFormat("  최대: %.2f (시간: %s)", max_volume_real, TimeToString(max_volume_real_time, TIME_DATE|TIME_SECONDS));
    PrintFormat("=====================================");
}

//+------------------------------------------------------------------+
//| Volume이 0인 틱 분석 함수                                          |
//+------------------------------------------------------------------+
void AnalyzeZeroVolumeTicks()
{
    MqlTick ticks[];
    
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 100000000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    Print("분석 시작: 총 ", copied, "개의 틱 데이터");
    
    int zero_volume_count = 0;
    
    // Volume = 0인 틱 분석
    for(int i = 0; i < copied; i++)
    {
        if(ticks[i].volume == 0)
        {
            zero_volume_count++;
            
            // 처음 10개의 Volume = 0인 틱만 상세 정보 출력
            if(zero_volume_count <= 10)
            {
                PrintFormat("\n=== Volume = 0인 틱 #%d ===", zero_volume_count);
                PrintFormat("시간: %s", TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS));
                PrintFormat("Bid: %.5f", ticks[i].bid);
                PrintFormat("Ask: %.5f", ticks[i].ask);
                PrintFormat("Last: %.5f", ticks[i].last);
                PrintFormat("Flags: %u", ticks[i].flags);
                
                // 플래그 해석
                string flags = "";
                if((ticks[i].flags & TICK_FLAG_BID) != 0) flags += "BID ";
                if((ticks[i].flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
                if((ticks[i].flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
                if((ticks[i].flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
                if((ticks[i].flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
                if((ticks[i].flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
                
                PrintFormat("플래그 설명: %s", flags);
            }
        }
    }
    
    double zero_volume_percentage = (double)zero_volume_count / copied * 100;
    
    PrintFormat("\n=== Volume = 0 틱 분석 결과 ===");
    PrintFormat("전체 틱 수: %d", copied);
    PrintFormat("Volume = 0인 틱 수: %d", zero_volume_count);
    PrintFormat("비율: %.2f%%", zero_volume_percentage);
    PrintFormat("===============================");
}

//+------------------------------------------------------------------+
//| 일봉 거래량 분석 함수                                              |
//+------------------------------------------------------------------+
void AnalyzeDailyVolume()
{
    //  거래량 정보 가져오기
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 틱 카운트
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
    
    // 틱 카운트를 틱단위로 나누기
    int quotient = (int)(tick_volume / TICK_STEP);  // 몫
    int remainder = (int)(tick_volume % TICK_STEP); // 나머지
    
    PrintFormat("\n=== 일봉 거래량 분석 ===");
    PrintFormat("틱 카운트(iVolume): %d (%d-%d)", 
                tick_volume, 
                quotient,
                remainder);
    PrintFormat("실제 거래량(iRealVolume): %d", real_volume);
    
    // 현재 틱 정보 출력
    MqlTick current_tick;
    if(SymbolInfoTick(_Symbol, current_tick))
    {
        // 플래그 해석
        string flags = "";
        if((current_tick.flags & TICK_FLAG_BID) != 0) flags += "BID ";
        if((current_tick.flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
        if((current_tick.flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
        if((current_tick.flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
        if((current_tick.flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
        if((current_tick.flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
        
        PrintFormat("현재틱: 시간 %s.%03d 현재가: %.5f 거래량: %d Flags: %s",
                   TimeToString(current_tick.time, TIME_DATE|TIME_SECONDS),
                   (int)(current_tick.time_msc % 1000),
                   current_tick.last,
                   current_tick.volume,
                   flags);
    }
    
    // 틱 데이터 가져오기
    MqlTick ticks[];
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, TICK_STEP);
    
    if(copied > 0)
    {
        // 나머지가 TICK_STEP-1일 때의 인덱스 계산
        if(remainder == TICK_STEP-1)
        {
            // 현재 구간의 시작점 찾기
            int current_start = TICK_STEP - 1;  // 현재 구의 첫 번째 틱
            
            if(current_start >= 0 && current_start < copied)
            {
                datetime start_time = ticks[current_start].time;
                long start_time_msc = ticks[current_start].time_msc;
                double start_price = ticks[current_start].last;
                double end_price = ticks[copied-1].last;
                
                PrintFormat("시간: %s.%03d, 시가: %.5f, 종가: %.5f", 
                           TimeToString(start_time, TIME_DATE|TIME_SECONDS),
                           (int)(start_time_msc % 1000),
                           start_price,
                           end_price);
            }
        }
    }
    
    PrintFormat("===============================");
}

//+------------------------------------------------------------------+
//| LAST VOLUME 플래그 검사 함수                                       |
//+------------------------------------------------------------------+
bool IsLastVolumeTick(MqlTick &current_tick)
{
        
    // LAST와 VOLUME 플래그가 모두 있는지 확인
    bool has_last = (current_tick.flags & TICK_FLAG_LAST) != 0;
    bool has_volume = (current_tick.flags & TICK_FLAG_VOLUME) != 0;
    
    return (has_last && has_volume);
}

//+------------------------------------------------------------------+
//| LAST VOLUME 틱 정보 출력 함수                                      |
//+------------------------------------------------------------------+
void PrintLastVolumeTickInfo(const MqlTick &tick)
{
    // 일봉 거래량 정보 가져오기
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 틱 카운트
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
    
    // 틱 카트를 틱단위 나누기
    int quotient = (int)(tick_volume / TICK_STEP);  // 몫
    int remainder = (int)(tick_volume % TICK_STEP); // 나머지
    
    PrintFormat("\n=== 일봉 거래량 분 ===");
    PrintFormat("틱 카운트(iVolume): %d (%d-%d)", 
                tick_volume, 
                quotient,
                remainder);
    PrintFormat("실제 거래량(iRealVolume): %d", real_volume);

    // 플래그 해석
    string flags = "";
    if((tick.flags & TICK_FLAG_BID) != 0) flags += "BID ";
    if((tick.flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
    if((tick.flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
    if((tick.flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
    if((tick.flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
    if((tick.flags & TICK_FLAG_SELL) != 0) flags += "SELL ";
    
    PrintFormat("\n=== LAST VOLUME 틱 정보 ===");
    PrintFormat("시간: %s.%03d", 
                TimeToString(tick.time, TIME_DATE|TIME_SECONDS),
                (int)(tick.time_msc % 1000));
    PrintFormat("Last: %.5f", tick.last);
    PrintFormat("Volume: %d", tick.volume);
    PrintFormat("Flags: %s", flags);
    
    // 틱봉 완성 체크
    if(remainder == TICK_STEP-1)
    {
        PrintFormat("\n*** 틱봉 완성 ***");
    }
 
    PrintFormat("===============================");
}

//+------------------------------------------------------------------+
//| 틱 데이터를 CSV로 저장하는 함수 (최근 100만개)                     |
//+------------------------------------------------------------------+
void SaveTicksToCSV2()
{
    MqlTick ticks[];
    datetime from = D'2024.11.07 00:00';  // SaveTicksToCSV()와 동일한 방식 사용
    datetime to = D'2024.11.08 00:00';
    
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 
                          (ulong)from * 1000, (ulong)to * 1000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    // 파일명 생성 - SaveTicksToCSV()와 동일한 방식 사용
    string filename = "ticks_" + _Symbol + "_" + TimeToString(from, TIME_DATE) + ".csv";
    
    // 파일 생성 - SaveTicksToCSV()와 동일한 방식 사용
    int handle = FileOpen(filename, FILE_WRITE|FILE_ANSI);
    
    if(handle == INVALID_HANDLE)
    {
        Print("파일 생성 실패. Error = ", GetLastError());
        return;
    }
    
    // 헤더 작성 (새로운 형식)
    FileWrite(handle, "time_msc,bid,ask,last,volume,volume_real,flags");
             
    // 데이터 작성
    for(int i = 0; i < copied; i++)
    {
        // UTC 시간을 ms로 변환하여 출력
        string ms_time = TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS) + "." + 
                        IntegerToString(ticks[i].time_msc % 1000, 3, '0');
                        
        // 플래그 해석
        string flags = "";
        uint flag = ticks[i].flags;
        
        // LAST VOLUME 틱 체크
        if((flag & TICK_FLAG_LAST) != 0 && (flag & TICK_FLAG_VOLUME) != 0)
            flags = "LAST VOLUME";
        // BID ASK 틱 체크
        else if((flag & TICK_FLAG_BID) != 0 && (flag & TICK_FLAG_ASK) != 0)
            flags = "BID ASK";
        else
            flags = IntegerToString(flag);  // 그 외의 경우 숫자로 표시
                        
        // 문자열 직접 구성
        string line = StringFormat("%s,%s,%s,%s,%d,%.2f,\"%s\"",
                    ms_time,
                    DoubleToString(ticks[i].bid, _Digits),
                    DoubleToString(ticks[i].ask, _Digits),
                    DoubleToString(ticks[i].last, _Digits),
                    ticks[i].volume,
                    ticks[i].volume_real,
                    flags);
                    
        FileWriteString(handle, line + "\n");
    }
    
    FileClose(handle);
    Print("틱 데이터가 MQL5/Files/", filename, "에 저장되었습니다. 총 ", copied, "개의 틱");
}

//+------------------------------------------------------------------+
//| 과거 틱데이터 출력 함수                                            |
//+------------------------------------------------------------------+
void PrintHistoricalTicks()
{
    MqlTick ticks[];
    
    // 최근 1000개의 틱 데이터 복사
    int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 1000);
                          
    if(copied <= 0)
    {
        Print("틱 데이터를 가져오는데 실패했습니다. Error = ", GetLastError());
        return;
    }
    
    Print("\n=== 과거 틱데이터 분석 시작 ===");
    Print("총 ", copied, "개의 틱 데이터");
    
    // 데이터 출력
    for(int i = 0; i < copied; i++)
    {
        // 플래그 해석
        string flags = "";
        uint flag = ticks[i].flags;
        
        // 플래그 값에 따른 해석
        switch(flag)
        {
            case 1:  flags = "BID"; break;
            case 2:  flags = "ASK"; break;
            case 3:  flags = "BID ASK"; break;
            case 8:  flags = "LAST"; break;
            case 16: flags = "VOLUME"; break;
            case 24: flags = "LAST VOLUME"; break;
            case 32: flags = "BUY"; break;
            case 64: flags = "SELL"; break;
            default:
                if((flag &  ) != 0) flags += "BID ";
                if((flag & TICK_FLAG_ASK) != 0) flags += "ASK ";
                if((flag & TICK_FLAG_LAST) != 0) flags += "LAST ";
                if((flag & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
                if((flag & TICK_FLAG_BUY) != 0) flags += "BUY ";
                if((flag & TICK_FLAG_SELL) != 0) flags += "SELL ";
                flags = StringTrimRight(flags);
        }
        
        PrintFormat("[%s.%03d] bid: %.5f, ask: %.5f, last: %.5f, volume: %d, flags: %s",
                   TimeToString(ticks[i].time, TIME_DATE|TIME_SECONDS),
                   (int)(ticks[i].time_msc % 1000),
                   ticks[i].bid,
                   ticks[i].ask,
                   ticks[i].last,
                   ticks[i].volume,
                   flags);
    }
    
    Print("=== 과거 틱데이터 분석 완료 ===");
}

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Tick Analysis EA가 초기화되었습니다.");
    
    PrintLastTickInfo();
    
    // 소규모 거래 분석
    //AnalyzeSmallTrades();
    
    //SaveTicksToCSV2();

    // SaveTicksToCSV();
         
    // 볼륨 범위 분석
    //AnalyzeVolumeRange();
    
    // Volume = 0인 틱 분석
    //AnalyzeZeroVolumeTicks();

    PrintHistoricalTicks();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Tick Analysis EA가 종료되었습니다. 이유: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{

    PrintLastTickInfo();

    /*
    static datetime last_tick_time = 0;
    static long last_tick_msc = 0;
    
    MqlTick current_tick;
    if(!SymbolInfoTick(_Symbol, current_tick))
        return;

    
    // 같은 시의 틱인지 확인 (밀리초까지)
    if(current_tick.time_msc == last_tick_msc)
        return;

    // LAST VOLUME 틱인 경우에만 출력
    if(IsLastVolumeTick(current_tick))
    {
        PrintLastVolumeTickInfo(current_tick);
    }

    
    
  
  
  if(current_tick.time_msc == last_tick_msc)
        return;

   PrintLastVolumeTickInfo(current_tick);

    last_tick_time = current_tick.time;
    last_tick_msc = current_tick.time_msc;

    */

}
  