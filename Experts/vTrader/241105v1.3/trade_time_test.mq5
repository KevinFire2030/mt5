//+------------------------------------------------------------------+
//|                                               trade_time_test.mq5   |
//|                                      Copyright 2024, MetaQuotes Ltd.|
//|                                             https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 미국 서머타임 체크                                                  |
//+------------------------------------------------------------------+
bool IsUSDaylightSavingTime(datetime time = 0)
{
    if(time == 0) time = TimeCurrent();
    
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    if(dt.mon < 3 || dt.mon > 11) return false;  // 1-2월, 12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 11) return true;   // 4-10월: 서머타임
    
    int year = dt.year;
    
    // 3월의 둘째 일요일 계산
    int secondSun = 14 - (5 * year / 4 + 1) % 7;
    
    // 11월의 첫째 일요일 계산 (정된 부분)
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
//| 영국 서머타임 체크                                                  |
//+------------------------------------------------------------------+
bool IsUKDaylightSavingTime(datetime time = 0)
{
    if(time == 0) time = TimeCurrent();
    
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    if(dt.mon < 3 || dt.mon > 10) return false;  // 1-2월, 11-12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 10) return true;   // 4-9월: 서머타임
    
    int lastSunday = 31;
    while(lastSunday > 0) {
        MqlDateTime tmp;
        TimeToStruct(StringToTime(string(dt.year) + "." + string(dt.mon) + "." + string(lastSunday)), tmp);
        if(tmp.day_of_week == 0) break;
        lastSunday--;
    }
    
    if(dt.mon == 3)
        return dt.day > lastSunday || (dt.day == lastSunday && dt.hour >= 2);
    else  // dt.mon == 10
        return dt.day < lastSunday || (dt.day == lastSunday && dt.hour < 2);
}

//+------------------------------------------------------------------+
//| 트레이딩 시간 체크                                                  |
//+------------------------------------------------------------------+
bool IsTradeTime(datetime time = 0)
{
    if(time == 0) time = TimeCurrent();
    
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    int current_hour = dt.hour;    // MT5 서버 시간 (UTC+2)
    int current_min = dt.min;
    bool isUSDST = IsUSDaylightSavingTime(time);
    bool isUKDST = IsUKDaylightSavingTime(time);
    
    // 1. 뉴욕 장시작 2시간 (09:30-11:30 ET)
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
    
    // 2. 뉴욕 장마감 1시간 (15:00-16:00 ET)
    if(isUSDST) {
        // 서머타임: MT5 시간 21:00-22:00
        if(current_hour == 21)
            return true;
    } else {
        // 겨울시간: MT5 시간 22:00-23:00
        if(current_hour == 22)
            return true;
    }
    
    // 3. 런던 장시작 1간 (08:00-09:00 런던)
    if(isUKDST) {
        // 서머타임: MT5 시간 09:00-10:00
        if(current_hour == 9)
            return true;
    } else {
        // 겨울시간: MT5 시간 10:00-11:00
        if(current_hour == 10)
            return true;
    }
    
    return false;
}

void TestDate(string dateStr)
{
    // 테스트할 시간을 전역변수로 설정
    datetime testTime;
    
    // 테스트할 시간들
    datetime times[4] = {
        StringToTime(dateStr + " 01:30"),
        StringToTime(dateStr + " 09:30"),
        StringToTime(dateStr + " 15:30"),
        StringToTime(dateStr + " 21:30")
    };
    
    for(int i=0; i<4; i++) {
        testTime = times[i];  // 테스트 시간 설정
        
        MqlDateTime dt;
        TimeToStruct(testTime, dt);
        
        // 현재 시간을 테스트 시간으로 설정
        Print("=== 테스트 날짜/시간: ", TimeToString(testTime), " ===");
        Print("미국 서머타임: ", (IsUSDaylightSavingTime(testTime) ? "적용" : "미적용"));
        Print("영국 서머타임: ", (IsUKDaylightSavingTime(testTime) ? "적용" : "미적용"));
        Print("트레이딩 시간: ", (IsTradeTime(testTime) ? "YES" : "NO"));
        Print("");
    }
}

//+------------------------------------------------------------------+
//| 스크립트 프로그램 시작 함수                                         |
//+------------------------------------------------------------------+
void OnStart()
{
    // 2024년 주요 날짜 테스트
    Print("\n=== 2024년 서머타임 전환일 테스트 ===");
    
    // 미국 서머타임
    TestDate("2024.03.09");  // 서머타임 시작 전날
    TestDate("2024.03.10");  // 서머타임 시작일
    TestDate("2024.03.11");  // 서머타임 시작 다음날
    
    TestDate("2024.11.02");  // 서머타임 종료 전날
    TestDate("2024.11.03");  // 서머타임 종료일
    TestDate("2024.11.04");  // 서머타임 종료 다음날
    
    // 영국 서머타임
    TestDate("2024.03.30");  // 영국 서머타임 시작 전날
    TestDate("2024.03.31");  // 영국 서머타임 시작일
    TestDate("2024.04.01");  // 영국 서머타임 시작 다음날
    
    TestDate("2024.10.26");  // 영국 서머타임 종료 전날
    TestDate("2024.10.27");  // 영국 서머타임 종료일
    TestDate("2024.10.28");  // 영국 서머타임 종료 다음날
    
    // 일반적인 날짜들
    TestDate("2024.01.15");  // 겨울 (둘 다 서머타임 아님)
    TestDate("2024.06.15");  // 여름 (둘 다 서머타임)
    TestDate("2024.09.15");  // 가을 (둘 다 서머타임)
    TestDate("2024.12.15");  // 겨울 (둘 다 서머타임 아님)
} 