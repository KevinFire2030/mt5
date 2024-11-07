//+------------------------------------------------------------------+
//|                                          volatility_analysis.mq5    |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 미국 서머타임 체크                                                  |
//+------------------------------------------------------------------+
bool IsDaylightSavingTime(datetime time = 0)
{
    if(time == 0) time = TimeCurrent();
    
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
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
//| 각 시간대의 ATR 계산                                               |
//+------------------------------------------------------------------+
double GetATR(int index, ENUM_TIMEFRAMES period)
{
    double high = iHigh(_Symbol, period, index);
    double low = iLow(_Symbol, period, index);
    double prev_close = iClose(_Symbol, period, index + 1);
    
    // ATR 계산
    double tr1 = high - low;                  // 현재 봉의 범위
    double tr2 = MathAbs(high - prev_close);  // 고가와 전봉 종가의 차이
    double tr3 = MathAbs(low - prev_close);   // 저가와 전봉 종가의 차이
    
    // TR(True Range) = MAX(tr1, tr2, tr3)
    return MathMax(tr1, MathMax(tr2, tr3));
}

//+------------------------------------------------------------------+
//| 시간대별 변동성 분석                                               |
//+------------------------------------------------------------------+
void AnalyzeVolatility()
{
    datetime startDate = StringToTime("2022.11.05 00:00:00");
    datetime endDate = StringToTime("2024.11.05 23:59:59");
    
    // 24시간 배열 초기화
    double hourlyATR[24] = {0};      // 각 시간대별 ATR 합계
    double hourlyRange[24] = {0};    // 각 시간대별 봉 크기 합계
    int hourlyCount[24] = {0};       // 각 시간대별 데이터 수
    
    // 데이터 수집
    int bars = Bars(_Symbol, PERIOD_H1, startDate, endDate);
    
    if(bars <= 0) {
        Print("데이터를 가져올 수 없습니다!");
        return;
    }
    
    Print("분석할 총 봉 수: ", bars);
    Print("데이터 수집 시작...");
    
    for(int i = bars-1; i >= 0; i--) {
        datetime time = iTime(_Symbol, PERIOD_H1, i);
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        // 해당 봉의 ATR 계산
        double atr = GetATR(i, PERIOD_H1);
        
        // 봉의 크기 계산
        double high = iHigh(_Symbol, PERIOD_H1, i);
        double low = iLow(_Symbol, PERIOD_H1, i);
        double range = high - low;
        
        hourlyATR[dt.hour] += atr;
        hourlyRange[dt.hour] += range;
        hourlyCount[dt.hour]++;
        
        // 진행상황 표시
        if(i % (bars/10) == 0) {
            Print("진행률: ", (bars-i)*100/bars, "%");
        }
    }
    
    // 시간대별 데이터를 저장할 구조체 배열
    struct HourlyData {
        int hour;
        double atr;
        double range;
        int count;
    } hourlyStats[24];
    
    // 데이터 정리
    for(int i = 0; i < 24; i++) {
        hourlyStats[i].hour = i;
        hourlyStats[i].atr = hourlyCount[i] > 0 ? hourlyATR[i] / hourlyCount[i] : 0;
        hourlyStats[i].range = hourlyCount[i] > 0 ? hourlyRange[i] / hourlyCount[i] : 0;
        hourlyStats[i].count = hourlyCount[i];
    }
    
    // ATR 기준으로 내림차순 정렬
    for(int i = 0; i < 23; i++) {
        for(int j = i + 1; j < 24; j++) {
            if(hourlyStats[j].atr > hourlyStats[i].atr) {
                HourlyData temp = hourlyStats[i];
                hourlyStats[i] = hourlyStats[j];
                hourlyStats[j] = temp;
            }
        }
    }
    
    // 결과 출력
    bool isDST = IsDaylightSavingTime();
    
    Print("\n=== 시간대별 변동성 분석 (ATR 내림차순) ===");
    Print("기간: ", TimeToString(startDate), " - ", TimeToString(endDate));
    Print("심볼: ", _Symbol);
    Print("");
    
    for(int i = 0; i < 24; i++) {
        int hour = hourlyStats[i].hour;
        
        // MT5 시간
        string mtTime = StringFormat("%02d:00-%02d:59", hour, hour);
        
        // 뉴욕 시간 계산
        int nyHour = hour - (isDST ? 6 : 7);
        if(nyHour < 0) nyHour += 24;
        string nyTime = StringFormat("%02d:00-%02d:59", nyHour, nyHour);
        
        Print(StringFormat(
            "%s (뉴욕 %s) 평균 ATR: %.5f, 평균 Range: %.5f - 데이터 수: %d",
            mtTime, nyTime,
            hourlyStats[i].atr,
            hourlyStats[i].range,
            hourlyStats[i].count
        ));
    }
}

//+------------------------------------------------------------------+
//| 30분 단위 변동성 분석                                               |
//+------------------------------------------------------------------+
void AnalyzeVolatility30Min()
{
    datetime startDate = StringToTime("2022.11.05 00:00:00");
    datetime endDate = StringToTime("2024.11.05 23:59:59");
    
    // 48개의 30분 구간 초기화 (24시간 * 2)
    double halfHourATR[48] = {0};      // 각 30분대별 ATR 합계
    double halfHourRange[48] = {0};    // 각 30분대별 봉 크기 합계
    int halfHourCount[48] = {0};       // 각 30분대별 데이터 수
    
    // 데이터 수집
    int bars = Bars(_Symbol, PERIOD_M30, startDate, endDate);
    
    if(bars <= 0) {
        Print("데이터를 가져올 수 없습니다!");
        return;
    }
    
    Print("분석할 총 봉 수: ", bars);
    Print("데이터 수집 시작...");
    
    for(int i = bars-1; i >= 0; i--) {
        datetime time = iTime(_Symbol, PERIOD_M30, i);
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        // 30분 구간 인덱스 계산 (0-47)
        int halfHourIndex = (dt.hour * 2) + (dt.min >= 30 ? 1 : 0);
        
        // 해당 봉의 ATR 계산
        double atr = GetATR(i, PERIOD_M30);
        
        // 봉의 크기 계산
        double high = iHigh(_Symbol, PERIOD_M30, i);
        double low = iLow(_Symbol, PERIOD_M30, i);
        double range = high - low;
        
        halfHourATR[halfHourIndex] += atr;
        halfHourRange[halfHourIndex] += range;
        halfHourCount[halfHourIndex]++;
        
        // 진행상황 표시
        if(i % (bars/10) == 0) {
            Print("진행률: ", (bars-i)*100/bars, "%");
        }
    }
    
    // 시간대별 데이터를 저장할 구조체 배열
    struct HalfHourData {
        int index;
        double atr;
        double range;
        int count;
    } halfHourStats[48];
    
    // 데이터 정리
    for(int i = 0; i < 48; i++) {
        halfHourStats[i].index = i;
        halfHourStats[i].atr = halfHourCount[i] > 0 ? halfHourATR[i] / halfHourCount[i] : 0;
        halfHourStats[i].range = halfHourCount[i] > 0 ? halfHourRange[i] / halfHourCount[i] : 0;
        halfHourStats[i].count = halfHourCount[i];
    }
    
    // ATR 기준으로 내림차순 정렬
    for(int i = 0; i < 47; i++) {
        for(int j = i + 1; j < 48; j++) {
            if(halfHourStats[j].atr > halfHourStats[i].atr) {
                HalfHourData temp = halfHourStats[i];
                halfHourStats[i] = halfHourStats[j];
                halfHourStats[j] = temp;
            }
        }
    }
    
    // 결과 출력
    bool isDST = IsDaylightSavingTime();
    
    Print("\n=== 30분 단위 변동성 분석 (ATR 내림차순) ===");
    Print("기간: ", TimeToString(startDate), " - ", TimeToString(endDate));
    Print("심볼: ", _Symbol);
    Print("");
    
    for(int i = 0; i < 48; i++) {
        int idx = halfHourStats[i].index;
        int hour = idx / 2;
        int minute = (idx % 2) * 30;
        
        // MT5 시간
        string mtTime = StringFormat("%02d:%02d-%02d:%02d", 
            hour, minute,
            hour, minute + 29);
            
        // 뉴욕 시간 계산
        int nyHour = hour - (isDST ? 6 : 7);
        if(nyHour < 0) nyHour += 24;
        
        string nyTime = StringFormat("%02d:%02d-%02d:%02d",
            nyHour, minute,
            nyHour, minute + 29);
        
        Print(StringFormat(
            "%s (뉴욕 %s) 평균 ATR: %.5f, 평균 Range: %.5f - 데이터 수: %d",
            mtTime, nyTime,
            halfHourStats[i].atr,
            halfHourStats[i].range,
            halfHourStats[i].count
        ));
    }
}

//+------------------------------------------------------------------+
//| 스크립트 프로그램 시작 함수                                         |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("\n=== 1시간 단위 분석 ===");
    AnalyzeVolatility();
    
    Print("\n=== 30분 단위 분석 ===");
    AnalyzeVolatility30Min();
} 