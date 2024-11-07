//+------------------------------------------------------------------+
//|                                             volume_analysis.mq5     |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 뉴욕 시간 계산 함수                                                 |
//+------------------------------------------------------------------+
string GetNewYorkTime(int mtHour, bool isDST)
{
    int nyHour;
    if(isDST)
        nyHour = mtHour - 6;  // 서머타임: 6시간 차이
    else
        nyHour = mtHour - 7;  // 겨울시간: 7시간 차이
    
    // 24시간제로 조정
    if(nyHour < 0) nyHour += 24;
    
    return StringFormat("%02d:00-%02d:59", nyHour, nyHour);
}

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
    int firstSun = 1;  // 1일부터 시작
    while(firstSun <= 7) {  // 첫 주 내에서
        MqlDateTime tmp;
        TimeToStruct(StringToTime(string(year) + ".11." + string(firstSun)), tmp);
        if(tmp.day_of_week == 0) break;  // 일요일 찾기
        firstSun++;
    }
    
    if(dt.mon == 3)
        return dt.day > secondSun || (dt.day == secondSun && dt.hour >= 2);
    else if(dt.mon == 11)  // 11월인 경우
        return dt.day < firstSun || (dt.day == firstSun && dt.hour < 2);
        
    return false;  // 기본적으로 서머타임 아님
}

//+------------------------------------------------------------------+
//| 시간대별 거래량 분석                                                |
//+------------------------------------------------------------------+
void AnalyzeVolume()
{
    // 분석 기간 2년으로 확장
    datetime startDate = StringToTime("2022.11.05 00:00:00");
    datetime endDate = StringToTime("2024.11.05 23:59:59");
    
    // 24시간 배열 초기화
    double hourlyVolume[24] = {0};    // 각 시간대별 누적 거래량
    int hourlyCount[24] = {0};        // 각 시간대별 데이터 수
    double totalVolume = 0;           // 전체 거래량
    
    // 데이터 수집
    MqlDateTime dt;
    int bars = Bars(_Symbol, PERIOD_H1, startDate, endDate);
    
    if(bars <= 0) {
        Print("데이터를 가져올 수 없습니다!");
        return;
    }
    
    Print("분석할 총 봉 수: ", bars);
    
    // 데이터 수집 전 진행상황 표시
    Print("데이터 수집 시작...");
    
    for(int i = bars-1; i >= 0; i--) {
        datetime time = iTime(_Symbol, PERIOD_H1, i);
        TimeToStruct(time, dt);
        
        // 실제 거래량 가져오기
        double volume = (double)iRealVolume(_Symbol, PERIOD_H1, i);
        if(volume <= 0) {
            Print("거래량 데이터 오류: ", TimeToString(time));
            continue;
        }
        
        hourlyVolume[dt.hour] += volume;
        hourlyCount[dt.hour]++;
        totalVolume += volume;
        
        // 진행상황 표시 (10% 단위)
        if(i % (bars/10) == 0) {
            Print("진행률: ", (bars-i)*100/bars, "%");
        }
    }
    
    // 결과 출력
    Print("\n=== 시간대별 거래량 분석 ===");
    Print("기간: ", TimeToString(startDate), " - ", TimeToString(endDate));
    Print("심볼: ", _Symbol);
    Print("총 거래량: ", DoubleToString(totalVolume, 0));
    Print("");
    
    // 시간대별 거래량을 저장할 구조체 배열
    struct HourlyData {
        int hour;
        double avgVolume;
        double percentage;
    } hourlyStats[24];
    
    // 데이터 정리
    for(int i = 0; i < 24; i++) {
        hourlyStats[i].hour = i;
        hourlyStats[i].avgVolume = hourlyCount[i] > 0 ? hourlyVolume[i] / hourlyCount[i] : 0;
        hourlyStats[i].percentage = (hourlyVolume[i] / totalVolume) * 100;
    }
    
    // 거래량 기준으로 내림차순 정렬
    for(int i = 0; i < 23; i++) {
        for(int j = i + 1; j < 24; j++) {
            if(hourlyStats[j].avgVolume > hourlyStats[i].avgVolume) {
                HourlyData temp = hourlyStats[i];
                hourlyStats[i] = hourlyStats[j];
                hourlyStats[j] = temp;
            }
        }
    }
    
    // 결과 출력 (거래량 순으로)
    bool isDST = IsDaylightSavingTime();  // 현재 서머타임 상태 확인
    
    for(int i = 0; i < 24; i++) {
        int hour = hourlyStats[i].hour;
        string mtTime = StringFormat("%02d:00-%02d:59", hour, hour);
        string nyTime = GetNewYorkTime(hour, isDST);
        
        string timeRange = StringFormat(
            "%s (뉴욕 %s) 평균 거래량: %d (비중: %.2f%%) - 데이터 수: %d", 
            mtTime,
            nyTime,
            (int)hourlyStats[i].avgVolume, 
            hourlyStats[i].percentage,
            hourlyCount[hour]
        );
        Print(timeRange);
    }
}

//+------------------------------------------------------------------+
//| 30분 단위 거래량 분석                                               |
//+------------------------------------------------------------------+
void AnalyzeVolume30Min()
{
    datetime startDate = StringToTime("2022.11.05 00:00:00");
    datetime endDate = StringToTime("2024.11.05 23:59:59");
    
    // 48개의 30분 구간 초기화 (24시간 * 2)
    double halfHourVolume[48] = {0};    // 각 30분대별 누적 거래량
    int halfHourCount[48] = {0};        // 각 30분대별 데이터 수
    double totalVolume = 0;             // 전체 거래량
    
    // 데이터 수집
    MqlDateTime dt;
    int bars = Bars(_Symbol, PERIOD_M30, startDate, endDate);
    
    if(bars <= 0) {
        Print("데이터를 가져올 수 없습니다!");
        return;
    }
    
    Print("분석할 총 봉 수: ", bars);
    Print("데이터 수집 시작...");
    
    for(int i = bars-1; i >= 0; i--) {
        datetime time = iTime(_Symbol, PERIOD_M30, i);
        TimeToStruct(time, dt);
        
        // 30분 구간 인덱스 계산 (0-47)
        int halfHourIndex = (dt.hour * 2) + (dt.min >= 30 ? 1 : 0);
        
        // 거래량 데이터 가져오기
        double volume = (double)iRealVolume(_Symbol, PERIOD_M30, i);
        if(volume <= 0) {
            Print("거래량 데이터 오류: ", TimeToString(time));
            continue;
        }
        
        halfHourVolume[halfHourIndex] += volume;
        halfHourCount[halfHourIndex]++;
        totalVolume += volume;
        
        // 진행상황 표시 (10% 단위)
        if(i % (bars/10) == 0) {
            Print("진행률: ", (bars-i)*100/bars, "%");
        }
    }
    
    // 결과 출력
    Print("\n=== 30분 단위 거래량 분석 ===");
    Print("기간: ", TimeToString(startDate), " - ", TimeToString(endDate));
    Print("심볼: ", _Symbol);
    Print("총 거래량: ", DoubleToString(totalVolume, 0));
    Print("");
    
    // 30분 단위 데이터를 저장할 구조체 배열
    struct HalfHourData {
        int index;
        double avgVolume;
        double percentage;
    } halfHourStats[48];
    
    // 데이터 정리
    for(int i = 0; i < 48; i++) {
        halfHourStats[i].index = i;
        halfHourStats[i].avgVolume = halfHourCount[i] > 0 ? halfHourVolume[i] / halfHourCount[i] : 0;
        halfHourStats[i].percentage = (halfHourVolume[i] / totalVolume) * 100;
    }
    
    // 거래량 기준으로 내림차순 정렬
    for(int i = 0; i < 47; i++) {
        for(int j = i + 1; j < 48; j++) {
            if(halfHourStats[j].avgVolume > halfHourStats[i].avgVolume) {
                HalfHourData temp = halfHourStats[i];
                halfHourStats[i] = halfHourStats[j];
                halfHourStats[j] = temp;
            }
        }
    }
    
    // 결과 출력 (거래량 순으로)
    bool isDST = IsDaylightSavingTime();
    
    for(int i = 0; i < 48; i++) {
        int idx = halfHourStats[i].index;
        int hour = idx / 2;
        int minute = (idx % 2) * 30;
        
        string mtTime = StringFormat("%02d:%02d-%02d:%02d", 
            hour, minute,
            hour, minute + 29);
            
        // 뉴욕 시간 계산
        int nyHour = hour - (isDST ? 6 : 7);
        if(nyHour < 0) nyHour += 24;
        
        string nyTime = StringFormat("%02d:%02d-%02d:%02d",
            nyHour, minute,
            nyHour, minute + 29);
        
        string timeRange = StringFormat(
            "%s (뉴욕 %s) 평균 거래량: %d (비중: %.2f%%) - 데이터 수: %d", 
            mtTime, nyTime,
            (int)halfHourStats[i].avgVolume, 
            halfHourStats[i].percentage,
            halfHourCount[halfHourStats[i].index]
        );
        Print(timeRange);
    }
}

//+------------------------------------------------------------------+
//| 스크립트 프로그램 시작 함수                                         |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("\n=== 1시간 단위 분석 ===");
    AnalyzeVolume();
    
    Print("\n=== 30분 단위 분석 ===");
    AnalyzeVolume30Min();
} 