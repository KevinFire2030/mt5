#property copyright "vTrader"
#property link      "https://github.com/vTrader"
#property version   "1.00"
#property description "틱 차트 지표 - 실시간 업데이트 버전"
#property indicator_separate_window
#property indicator_buffers 7  // 5에서 7로 증가
#property indicator_plots   1  // 캔들스틱 플롯 유지

#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrLime,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1


// 입력 파라미터
input int    InpTickInterval = 100;     // 틱 간격
input int    InpMaxBars = 1000;         // 최대 봉 개수
input bool   InpAutoScale = true;       // 자동 스케일 조정
input bool InpDebugMode = false;  // 디버그 정보 출력

// 버퍼
double BufferOpen[];
double BufferHigh[];
double BufferLow[];
double BufferClose[];
double BufferColors[];
double BufferTime[];    // 시간(ms) 저장용
double BufferVolume[]; // 거래량 저장용

// 글로벌 변수
int tickCounter = 0;
bool historyLoaded = false;
double currentOpen, currentHigh, currentLow, currentClose;
long lastTickTime = 0;
int currentIndex = 0;  // 현재 봉의 인덱스

// 봉 데이터 구조체
struct TickBarData {
    datetime time;        // 시간 (초)
    datetime end_time;    // 종료 시간 (초)
    long time_msc;       // 시간 (밀리초)
    long end_time_msc;   // 마지막 틱 시간 (밀리초)
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
        end_time = 0;
        time_msc = 0;    
        end_time_msc = 0;
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

// 지표 핸들
int ema10Handle;
int ema34Handle;
int momentum10Handle;
int momentum34Handle;

// 지표 버퍼
double ema10Buffer[];
double ema34Buffer[];
double momentum10Buffer[];
double momentum34Buffer[];

// 포지션 관리 변수
bool inLongPosition = false;
bool inShortPosition = false;
double positionSize = 0.1;  // 기본 거래량
double partialClosePct = 50.0;  // 부분 청산 비율

//+------------------------------------------------------------------+
//| 초기화 함수                                                        |
//+------------------------------------------------------------------+
int OnInit()
{
    // 기존 버퍼 설정
    SetIndexBuffer(0, BufferOpen, INDICATOR_DATA);
    SetIndexBuffer(1, BufferHigh, INDICATOR_DATA);
    SetIndexBuffer(2, BufferLow, INDICATOR_DATA);
    SetIndexBuffer(3, BufferClose, INDICATOR_DATA);
    SetIndexBuffer(4, BufferColors, INDICATOR_COLOR_INDEX);
    
    // 추가 버퍼 설정
    SetIndexBuffer(5, BufferTime, INDICATOR_DATA);
    SetIndexBuffer(6, BufferVolume, INDICATOR_DATA);
    
    // Data Window 레이블 설정
    PlotIndexSetString(0, PLOT_LABEL, "Time(ms)");  // 시간
    PlotIndexSetString(1, PLOT_LABEL, "Open");      // 시가
    PlotIndexSetString(2, PLOT_LABEL, "High");      // 고가
    PlotIndexSetString(3, PLOT_LABEL, "Low");       // 저가
    PlotIndexSetString(4, PLOT_LABEL, "Close");     // 종가
    PlotIndexSetString(5, PLOT_LABEL, "Volume");    // 거래량
    
    // 시간 표시 형식 설정
    //PlotIndexSetInteger(5, PLOT_DIGITS, 0);     // 소수점 자리수
    //PlotIndexSetString(5, PLOT_LABEL_FORMAT, "Time: %s.%03d");  // 표시 형식
    
    // 버퍼를 시계열로 설정
    ArraySetAsSeries(BufferOpen, true);
    ArraySetAsSeries(BufferHigh, true);
    ArraySetAsSeries(BufferLow, true);
    ArraySetAsSeries(BufferClose, true);
    ArraySetAsSeries(BufferColors, true);
    ArraySetAsSeries(BufferTime, true);
    ArraySetAsSeries(BufferVolume, true);
    
    // 버퍼 초기화
    ArrayInitialize(BufferOpen, EMPTY_VALUE);
    ArrayInitialize(BufferHigh, EMPTY_VALUE);
    ArrayInitialize(BufferLow, EMPTY_VALUE);
    ArrayInitialize(BufferClose, EMPTY_VALUE);
    ArrayInitialize(BufferColors, 0);
    ArrayInitialize(BufferTime, 0);
    ArrayInitialize(BufferVolume, 0);

    // 지표 이름과 소수점 자리수 설정
    IndicatorSetString(INDICATOR_SHORTNAME, "Tick Chart");
    IndicatorSetInteger(INDICATOR_DIGITS, 0);  // 소수점 자리수 설정

    // Data Window에서 시간 표시 형식 설정
    PlotIndexSetString(0, PLOT_LABEL, "Time");  // 레이블 이름
    //PlotIndexSetInteger(0, PLOT_DIGITS, 0);     // 소수점 자리수
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 봉 데이터 저장 함수                                               |
//+------------------------------------------------------------------+
void SaveBarData(const TickBarData& bar, int index)
{
    // 기존 데이터 저장
    BufferOpen[index] = bar.open;
    BufferHigh[index] = bar.high;
    BufferLow[index] = bar.low;
    BufferClose[index] = bar.close;
    BufferColors[index] = (bar.close >= bar.open) ? 0 : 1;
    
    // 추가 데이터 저장
    BufferTime[index] = (double)bar.time_msc;  // 밀리초 시간 저장
    BufferVolume[index] = (double)bar.volume;  // 거래량 저장
}

//+------------------------------------------------------------------+
//| 틱 데이터 로드                                                     |
//+------------------------------------------------------------------+
void LoadHistory()
{

    MqlTick ticks[];
    ArraySetAsSeries(ticks, false);  // 과거 데이터부터 처리

    // 당일 시작 시간 계산
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));

    // 현재 틱 정보 가져오기
    MqlTick last_tick;
    SymbolInfoTick(_Symbol, last_tick);
    long current_time_msc = last_tick.time_msc;
    

    int received = CopyTicksRange(_Symbol, ticks, COPY_TICKS_TRADE, today_start * 1000, current_time_msc);
    // 틱 데이터 로드 실패시 더 자세한 에러 정보
     if(received <= 0)
    {
        PrintFormat("틱 데이터 로드 실패! 에러: %d", GetLastError());
        return;
    }
       

    if(received > 0)
    {
        // 1. 틱 카운트 계산
        int quotient = (int)(received / InpTickInterval);  // 완성봉 수
        int remainder = (int)(received % InpTickInterval); // 미완성봉 틱 수
        
        PrintFormat("받은 실거래 틱: %d (완성봉: %d, 남은틱: %d)", received, quotient, remainder);

        // 2. TickBarData 배열 준비
        TickBarData bars[];
        ArrayResize(bars, quotient + 1);  // +1은 미완성 봉용
        
        // 3. 과거부터 순차적으로 봉 생성
        for(int i = 0; i < quotient; i++)  // 완성봉 처리
        {
            bars[i].Reset();
            int startTick = i * InpTickInterval;
            
            // 한 봉에 해당하는 틱 처리
            for(int j = 0; j < InpTickInterval; j++)
            {
                int tickIndex = startTick + j;
                
                if(j == 0)  // 봉 시작
                {
                    bars[i].time = ticks[tickIndex].time;
                    bars[i].time_msc = ticks[tickIndex].time_msc;
                    bars[i].open = ticks[tickIndex].last;
                    bars[i].high = ticks[tickIndex].last;
                    bars[i].low = ticks[tickIndex].last;
                    bars[i].close = ticks[tickIndex].last;
                    bars[i].volume = ticks[tickIndex].volume;
                    bars[i].tickCount = 1;
                }
                else  // 봉 업데이트
                {
                    bars[i].high = MathMax(bars[i].high, ticks[tickIndex].last);
                    bars[i].low = MathMin(bars[i].low, ticks[tickIndex].last);
                    bars[i].close = ticks[tickIndex].last;
                    bars[i].volume += ticks[tickIndex].volume;
                    bars[i].tickCount++;

                    // 마지막 틱이면 종료 시간 저장
                    if(j == InpTickInterval-1)
                    {
                        bars[i].end_time = ticks[tickIndex].time;
                        bars[i].end_time_msc = ticks[tickIndex].time_msc;
                    }
                }
            }

            
            /*

            // 디버그 정보 출력
            PrintFormat("봉[%d]: 시작=%s.%03d, 종료=%s.%03d, O=%.5f, H=%.5f, L=%.5f, C=%.5f, V=%d", 
                i,
                TimeToString(bars[i].time, TIME_SECONDS),
                (int)(bars[i].time_msc % 1000),
                TimeToString(bars[i].end_time, TIME_SECONDS),
                (int)(bars[i].end_time_msc % 1000),
                bars[i].open,
                bars[i].high,
                bars[i].low,
                bars[i].close,
                bars[i].volume
            );
            
            */
            
        }
        
        // 4. 미완성 봉 처리
        if(remainder > 0)
        {
            int startTick = quotient * InpTickInterval;
            bars[quotient].Reset();
            
            for(int j = 0; j < remainder; j++)
            {
                int tickIndex = startTick + j;
                
                if(j == 0)  // 봉 시작
                {
                    bars[quotient].time = ticks[tickIndex].time;
                    bars[quotient].time_msc = ticks[tickIndex].time_msc;
                    bars[quotient].open = ticks[tickIndex].last;
                    bars[quotient].high = ticks[tickIndex].last;
                    bars[quotient].low = ticks[tickIndex].last;
                    bars[quotient].close = ticks[tickIndex].last;
                    bars[quotient].volume = ticks[tickIndex].volume;
                    bars[quotient].tickCount = 1;
                }
                else  // 봉 업데이트
                {
                    bars[quotient].high = MathMax(bars[quotient].high, ticks[tickIndex].last);
                    bars[quotient].low = MathMin(bars[quotient].low, ticks[tickIndex].last);
                    bars[quotient].close = ticks[tickIndex].last;
                    bars[quotient].volume += ticks[tickIndex].volume;
                    bars[quotient].tickCount++;
                }
            }

            // 글로벌 변수 업데이트
            currentOpen = bars[quotient].open;
            currentHigh = bars[quotient].high;
            currentLow = bars[quotient].low;
            currentClose = bars[quotient].close;
            tickCounter = remainder;  // 미완성 봉의 틱 카운터 설정
        }
        
        // 5. 배열 역순 정렬
        ArrayReverse(bars);
        
        // 6. 버퍼에 데이터 복사
        for(int i = 0; i < ArraySize(bars); i++)
        {
            SaveBarData(bars[i], i);
        }

        // 7. 마지막 처리된 틱의 시간 저장
        lastTickTime = ticks[received-1].time_msc;  // 마지막 틱의 시간 저장
        
        historyLoaded = true;
    }
}
//+------------------------------------------------------------------+
//| 계산 함수                                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{

    // 1. 과거 데이터 로드
    if(!historyLoaded)
    {
        LoadHistory();
        return(rates_total);
    }

    // 2. 현재 틱 데이터 가져오기
    MqlTick current_tick;
    if(!SymbolInfoTick(_Symbol, current_tick))
        return(rates_total);

    // 3. 거래 틱인지 확인 (LAST와 VOLUME 플래그 체크)
    if((current_tick.flags & (TICK_FLAG_LAST | TICK_FLAG_VOLUME)) == 0)
        return(rates_total);

    // 4. 누락틱 체크 및 처리
    if(lastTickTime > 0)  // 첫 틱이 아닌 경우에만 체크
    {
        // 현재 틱과 마지막 틱 사이의 틱 데이터 요청
        MqlTick missed_ticks[];
        ArraySetAsSeries(missed_ticks, true);
        
        int missed = CopyTicksRange(_Symbol, missed_ticks, COPY_TICKS_TRADE, 
                                lastTickTime, current_tick.time_msc);
                                
        // 누락된 틱이 있는지 확인 (현재 틱 제외하고 2개 이상이면 누락된 틱이 있음)
        if(missed > 1)  // 현재 틱을 포함하므로 1보다 큰 경우
        {
            PrintFormat("틱 누락 발견: %d개 (시간 간격: %d ms)", 
                missed-1,  // 현재 틱 제외
                current_tick.time_msc - lastTickTime);
                
            // 누락된 틱을 현재 봉에 포함
            for(int i = 1; i < missed; i++)  // i=0은 마지막 처리된 틱이므로 제외
            {
                // 현재 봉 업데이트
                currentHigh = MathMax(currentHigh, missed_ticks[i].last);
                currentLow = MathMin(currentLow, missed_ticks[i].last);
                currentClose = missed_ticks[i].last;
                tickCounter++;  // 틱 카운터 증가
                
                PrintFormat("누락틱 처리[%d]: 시간=%s.%03d, Last=%.5f, Volume=%d", 
                    i,
                    TimeToString(missed_ticks[i].time, TIME_SECONDS),
                    (int)(missed_ticks[i].time_msc % 1000),
                    missed_ticks[i].last,
                    missed_ticks[i].volume);
            }
            
            // 틱 카운터가 간격을 초과하면 새로운 봉 시작
            if(tickCounter >= InpTickInterval)
            {
                // ... 봉 완성 처리 ...
                tickCounter = 0;
            }
        }
    }
    

    // 5. 중복 틱 체크
    if(current_tick.time_msc <= lastTickTime)
        return(rates_total);
        
    lastTickTime = current_tick.time_msc;
    
    // 6. 실시간 봉 업데이트
    if(tickCounter == 0)  // 새로운 봉 시작
    {
        // 이전 봉들을 한 칸�� 오른쪽으로 이동
        for(int i = 0; i < rates_total-1; i++)
        {
            BufferOpen[i+1] = BufferOpen[i];
            BufferHigh[i+1] = BufferHigh[i];
            BufferLow[i+1] = BufferLow[i];
            BufferClose[i+1] = BufferClose[i];
            BufferColors[i+1] = BufferColors[i];
            BufferTime[i+1] = BufferTime[i];
            BufferVolume[i+1] = BufferVolume[i];
        }
        
        // 새로운 봉은 0번 인덱스에 초기화
        BufferOpen[0] = current_tick.last;
        BufferHigh[0] = current_tick.last;
        BufferLow[0] = current_tick.last;
        BufferClose[0] = current_tick.last;
        BufferColors[0] = 0;
        BufferTime[0] = (double)current_tick.time_msc;
        BufferVolume[0] = (double)current_tick.volume;
        
        tickCounter = 1;
    }
    else  // 현재 봉 업데이트
    {
        // 0번 인덱스(현재 봉) 업데이트
        BufferHigh[0] = MathMax(BufferHigh[0], current_tick.last);
        BufferLow[0] = MathMin(BufferLow[0], current_tick.last);
        BufferClose[0] = current_tick.last;
        BufferColors[0] = (BufferClose[0] >= BufferOpen[0]) ? 0 : 1;
        BufferVolume[0] += (double)current_tick.volume;
        
        tickCounter++;
    }
    
    // 8. 틱 간격 도달시 새로운 봉 시작
    if(tickCounter >= InpTickInterval)
    {
        tickCounter = 0;  // 카운터 리셋
    }
    
    // 9. 차트 자동 스케일링
    if(InpAutoScale)
    {
        // 현재 표시된 봉들의 최고/최저 가격 찾기
        double min = BufferLow[ArrayMinimum(BufferLow)];
        double max = BufferHigh[ArrayMaximum(BufferHigh)];
        
        // 여백 추가 (10%)
        double margin = (max - min) * 0.1;
        
        // 차트 스케일 설정
        ChartSetDouble(0, CHART_PRICE_MIN, min - margin);  // 최저가에서 여백만큼 아래
        ChartSetDouble(0, CHART_PRICE_MAX, max + margin);  // 최고가에서 여백만큼 위
    }
    
    // 10. 차트 갱신
    ChartRedraw();

    
    return(rates_total);
} 



//+------------------------------------------------------------------+
//| 실제 거래 틱 필터링 함수                                           |
//+------------------------------------------------------------------+
int GetRealTradeTicks(MqlTick &filtered_ticks[])
{
    MqlTick ticks[];
    ArraySetAsSeries(ticks, true);
    ArraySetAsSeries(filtered_ticks, true);
    
    // 당일 시작 시간 계산
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    datetime current_time = TimeCurrent();
    
    // 당일 모든 틱 복사
    int received = CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL, today_start, current_time);
    
    if(received > 0)
    {
        // 실제 거래가 있는 틱만 필터링하여 저장할 임시 배열
        MqlTick temp[];
        ArrayResize(temp, received);
        int filtered_count = 0;
        
        // 각 틱 검사
        for(int i = 0; i < received; i++)
        {
            // volume_real이 0보다 크면 실제 거래 발생
            if(ticks[i].volume_real > 0)
            {
                temp[filtered_count] = ticks[i];
                filtered_count++;
                
                // 디버그 정보 출력
                PrintFormat("실제거래 발생: 시간=%s, 가격=%.5f, 수량=%d", 
                    TimeToString(ticks[i].time, TIME_SECONDS),
                    ticks[i].last,
                    ticks[i].volume_real);
            }
        }
        
        // 필터링된 틱만 최�� 배열에 복사
        ArrayResize(filtered_ticks, filtered_count);
        ArrayCopy(filtered_ticks, temp, 0, 0, filtered_count);
        
        return filtered_count;
    }
    
    return 0;
}


//+------------------------------------------------------------------+
//| 틱 데이터 확인                                                    |
//+------------------------------------------------------------------+
void CheckTickData()
{
//  거래량 정보 가져오기
    long tick_volume = iVolume(_Symbol, PERIOD_D1, 0);    // 틱 카운트
    long real_volume = iRealVolume(_Symbol, PERIOD_D1, 0); // 실제 거래량
    
    PrintFormat("\n=== 거래량 정보 ===");
    PrintFormat("현재까지 틱카운트: %d", tick_volume);
    PrintFormat("현재까지 실제거래량: %d", real_volume);


    MqlTick all_ticks[];
    MqlTick real_trade_ticks[];
    MqlTick bid_ask_ticks[];
    ArraySetAsSeries(all_ticks, true);
    ArraySetAsSeries(real_trade_ticks, true);
    ArraySetAsSeries(bid_ask_ticks, true);
    
    // 당일 시작 시간 계산
    datetime today_start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    // 현재 틱 정보 가져오기
    MqlTick last_tick;
    SymbolInfoTick(_Symbol, last_tick);
    long current_time_msc = last_tick.time_msc;
    
    // 각 타입별 틱 데이터 로드
    int all_count = CopyTicksRange(_Symbol, all_ticks, COPY_TICKS_ALL, today_start * 1000, current_time_msc);
    int real_trade_count = CopyTicksRange(_Symbol, real_trade_ticks, COPY_TICKS_TRADE, today_start * 1000, current_time_msc);
    int bid_ask_count = CopyTicksRange(_Symbol, bid_ask_ticks, COPY_TICKS_INFO, today_start * 1000, current_time_msc);
    
    // 결과 출력
    PrintFormat("\n=== ENUM_COPY_TICKS ===");
    PrintFormat("Bid/Ask틱 (COPY_TICKS_INFO): %d", bid_ask_count);
    PrintFormat("실거래틱(COPY_TICKS_TRADE): %d", real_trade_count);
    PrintFormat("모든틱(COPY_TICKS_ALL): %d", all_count);

   // 틱 출력
    PrintFormat("\n=== COPY_TICKS_INFO (Bid/Ask 틱) ===");
    for(int i = 0; i < MathMin(10, bid_ask_count); i++)  // 처음 10개만 출력
    {
        string flags = "";
        if((bid_ask_ticks[i].flags & TICK_FLAG_BID) != 0) flags += "BID ";
        if((bid_ask_ticks[i].flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
        if((bid_ask_ticks[i].flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
        if((bid_ask_ticks[i].flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
        if((bid_ask_ticks[i].flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
        if((bid_ask_ticks[i].flags & TICK_FLAG_SELL) != 0) flags += "SELL ";

        PrintFormat("틱[%d]: 시간=%s.%03d, Bid=%.5f, Ask=%.5f, Last=%.5f, Volume=%d, Flags=%s",
            i,
            TimeToString(bid_ask_ticks[i].time, TIME_SECONDS),
            TimeToString(bid_ask_ticks[i].time_msc % 1000),
            bid_ask_ticks[i].bid,
            bid_ask_ticks[i].ask,
            bid_ask_ticks[i].last,
            bid_ask_ticks[i].volume,
            flags
        );
    }

    // 틱 출력
    PrintFormat("\n=== COPY_TICKS_TRADE (실거래 틱) ===");
    for(int i = 0; i < MathMin(10, real_trade_count); i++)
    {
        string flags = "";
        if((real_trade_ticks[i].flags & TICK_FLAG_BID) != 0) flags += "BID ";
        if((real_trade_ticks[i].flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
        if((real_trade_ticks[i].flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
        if((real_trade_ticks[i].flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
        if((real_trade_ticks[i].flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
        if((real_trade_ticks[i].flags & TICK_FLAG_SELL) != 0) flags += "SELL ";

        PrintFormat("틱[%d]: 시간=%s.%03d, Bid=%.5f, Ask=%.5f, Last=%.5f, Volume=%d, Flags=%s",
            i,
            TimeToString(real_trade_ticks[i].time, TIME_SECONDS),
            TimeToString(real_trade_ticks[i].time_msc % 1000),
            real_trade_ticks[i].bid,
            real_trade_ticks[i].ask,
            real_trade_ticks[i].last,
            real_trade_ticks[i].volume,        // 틱 볼륨
            flags
        );
    }
    // 틱 출력
    PrintFormat("\n=== COPY_TICKS_ALL (모든 틱) ===");
    for(int i = 0; i < MathMin(10, all_count); i++)  // 처음 10개만 출력
    {
        string flags = "";
        if((all_ticks[i].flags & TICK_FLAG_BID) != 0) flags += "BID ";
        if((all_ticks[i].flags & TICK_FLAG_ASK) != 0) flags += "ASK ";
        if((all_ticks[i].flags & TICK_FLAG_LAST) != 0) flags += "LAST ";
        if((all_ticks[i].flags & TICK_FLAG_VOLUME) != 0) flags += "VOLUME ";
        if((all_ticks[i].flags & TICK_FLAG_BUY) != 0) flags += "BUY ";
        if((all_ticks[i].flags & TICK_FLAG_SELL) != 0) flags += "SELL ";

        PrintFormat("틱[%d]: 시간=%s.%03d, Bid=%.5f, Ask=%.5f, Last=%.5f, Volume=%d, Flags=%s",
            i,
            TimeToString(all_ticks[i].time, TIME_SECONDS),
            TimeToString(all_ticks[i].time_msc % 1000),
            all_ticks[i].bid,
            all_ticks[i].ask,
            all_ticks[i].last,
            all_ticks[i].volume,
            flags
        );
    }
}

bool InitIndicators()
{
    // EMA 지표 초기화
    ema10Handle = iMA(_Symbol, PERIOD_CURRENT, 10, 0, MODE_EMA, PRICE_CLOSE);
    ema34Handle = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    
    // 모멘텀 지표 초기화
    momentum10Handle = iMomentum(_Symbol, PERIOD_CURRENT, 10, PRICE_CLOSE);
    momentum34Handle = iMomentum(_Symbol, PERIOD_CURRENT, 34, PRICE_CLOSE);
    
    // 버퍼 초기화
    ArraySetAsSeries(ema10Buffer, true);
    ArraySetAsSeries(ema34Buffer, true);
    ArraySetAsSeries(momentum10Buffer, true);
    ArraySetAsSeries(momentum34Buffer, true);
    
    return (ema10Handle != INVALID_HANDLE && 
            ema34Handle != INVALID_HANDLE && 
            momentum10Handle != INVALID_HANDLE && 
            momentum34Handle != INVALID_HANDLE);
}

