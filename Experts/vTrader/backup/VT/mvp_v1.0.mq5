#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property description "MVP v1.0 - 매분 시작 시 1분봉 60개 가져오기"

#property strict

// 전역 변수
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // 초기화 코드
    Print("MVP v1.0 초기화됨");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 정리 코드
    Print("MVP v1.0 종료됨");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 현재 차트의 시간프레임이 1분인지 확인
    if(Period() != PERIOD_M1)
    {
        Print("이 EA는 1분 차트에서만 작동합니다.");
        return;
    }
    
    // 새로운 봉이 시작되었는지 확인
    datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);
    if(currentBarTime == lastBarTime)
        return;  // 새 봉이 아니면 함수 종료
    
    lastBarTime = currentBarTime;
    
    // 60개의 1분봉 데이터 가져오기
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), PERIOD_M1, 0, 60, rates);
    
    if(copied == 60)
    {
        Print("새로운 분봉 시작. 60개의 1분봉 데이터를 성공적으로 가져왔습니다.");
        // 여기에 가져온 데이터를 처리하는 코드를 추가할 수 있습니다.
    }
    else
    {
        Print("데이터 가져오기 실패. 복사된 봉의 수: ", copied);
    }
}

