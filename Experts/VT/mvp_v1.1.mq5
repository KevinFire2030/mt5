#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.10"
#property description "MVP v1.1 - 매분 시작 시 1분봉 60개와 EMA(5/20/40) 가져오기"

#property strict

// 전역 변수
datetime lastBarTime = 0;
int ema5Handle, ema20Handle, ema40Handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // EMA 지표 초기화
    ema5Handle = iMA(Symbol(), PERIOD_M1, 5, 0, MODE_EMA, PRICE_CLOSE);
    ema20Handle = iMA(Symbol(), PERIOD_M1, 20, 0, MODE_EMA, PRICE_CLOSE);
    ema40Handle = iMA(Symbol(), PERIOD_M1, 40, 0, MODE_EMA, PRICE_CLOSE);
    
    if(ema5Handle == INVALID_HANDLE || ema20Handle == INVALID_HANDLE || ema40Handle == INVALID_HANDLE)
    {
        Print("EMA 지표 초기화 실패");
        return(INIT_FAILED);
    }
    
    Print("MVP v1.1 초기화됨");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 지표 핸들 해제
    IndicatorRelease(ema5Handle);
    IndicatorRelease(ema20Handle);
    IndicatorRelease(ema40Handle);
    
    Print("MVP v1.1 종료됨");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(Period() != PERIOD_M1)
    {
        //Print("이 EA는 1분 차트에서만 작동합니다.");
        return;
    }
    
    datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);
    if(currentBarTime == lastBarTime)
        return;
    
    lastBarTime = currentBarTime;
    
    // 60개의 1분봉 데이터 가져오기
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), PERIOD_M1, 0, 60, rates);
    
    if(copied == 60)
    {
        Print("새로운 분봉 시작. 60개의 1분봉 데이터를 성공적으로 가져왔습니다.");
        
        // EMA 값 가져오기
        double ema5[], ema20[], ema40[];
        ArraySetAsSeries(ema5, true);
        ArraySetAsSeries(ema20, true);
        ArraySetAsSeries(ema40, true);
        
        if(CopyBuffer(ema5Handle, 0, 0, 1, ema5) == 1 &&
           CopyBuffer(ema20Handle, 0, 0, 1, ema20) == 1 &&
           CopyBuffer(ema40Handle, 0, 0, 1, ema40) == 1)
        {
            Print("현재 EMA 값 - EMA5: ", ema5[0], ", EMA20: ", ema20[0], ", EMA40: ", ema40[0]);
        }
        else
        {
            Print("EMA 데이터 가져오기 실패");
        }
    }
    else
    {
        Print("데이터 가져오기 실패. 복사된 봉의 수: ", copied);
    }
}
