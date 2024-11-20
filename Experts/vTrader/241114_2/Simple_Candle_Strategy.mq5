//+------------------------------------------------------------------+
//|                                         Simple_Candle_Strategy.mq5 |
//|                                          Larry Williams 외부바 전략 |
//|                                                                    |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      ""
#property version   "1.00"

// 입력 파라미터
input double   LotSize = 0.1;          // 거래 수량
input int      StopLoss = 200;         // 손절 (pips)
input bool     UseFixedTP = true;     // 고정 익절 사용
input int      TakeProfit = 300;       // 고정 익절 (pips)
input bool     CloseAtDayEnd = true;   // 일봉 종료시 수익 청산

// 전역 변수
int handle;                            // 차트 핸들
datetime lastBarTime;                  // 마지막 봉 시간
int magicNumber = 12345;              // 매직 넘버

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    lastBarTime = 0;
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // 마켓이 열려있는지 확인
    if(!IsMarketOpen()) return;
    
    // 새로운 봉이 생성되었는지 확인
    datetime currentBarTime = iTime(Symbol(), PERIOD_D1, 0);
    if(currentBarTime == lastBarTime) return;
    lastBarTime = currentBarTime;
    
    // 포지션 확인 및 수익 청산
    if(CloseAtDayEnd && PositionSelect(Symbol()))
    {
        if(!ClosePosition())
        {
            Print("Failed to close position");
        }
        return;
    }
    
    // 시그널 확인
    int signal = CheckSignal();
    
    // 포지션이 없을 때만 새로운 거래 진입
    if(!PositionSelect(Symbol()))
    {
        if(signal == 1)      // 매수 시그널
        {
            if(!OpenBuy())
            {
                Print("Failed to open buy position");
            }
        }
        else if(signal == -1) // 매도 시그널
        {
            if(!OpenSell())
            {
                Print("Failed to open sell position");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 시그널 체크 함수                                                    |
//+------------------------------------------------------------------+
int CheckSignal()
{
    double open1 = iOpen(Symbol(), PERIOD_D1, 1);
    double close1 = iClose(Symbol(), PERIOD_D1, 1);
    double high1 = iHigh(Symbol(), PERIOD_D1, 1);
    double low1 = iLow(Symbol(), PERIOD_D1, 1);
    
    double open2 = iOpen(Symbol(), PERIOD_D1, 2);
    double close2 = iClose(Symbol(), PERIOD_D1, 2);
    double high2 = iHigh(Symbol(), PERIOD_D1, 2);
    double low2 = iLow(Symbol(), PERIOD_D1, 2);
    
    // 매수 시그널 (외부 음봉)
    if(open1 > close1 &&                 // 음봉
       high1 > high2 &&                  // 고가 돌파
       low1 < low2 &&                    // 저가 돌파
       close1 < low2)                    // 종가가 이전 저가보다 낮음
    {
        return 1;
    }
    
    // 매도 시그널 (외부 양봉)
    if(open1 < close1 &&                 // 양봉
       low1 < low2 &&                    // 저가 돌파
       high1 > high2 &&                  // 고가 돌파
       close1 > high2)                   // 종가가 이전 고가보다 높음
    {
        return -1;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| 마켓이 열려있는지 확인하는 함수                                      |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
    datetime time_current = TimeCurrent();    // 현재 서버 시간
    MqlDateTime time_struct;
    TimeToStruct(time_current, time_struct);
    
    // 주말 체크
    if(time_struct.day_of_week == SATURDAY || time_struct.day_of_week == SUNDAY)
        return false;
        
    // 심볼의 거래 세션 정보 가져오기
    datetime from = 0;
    datetime to = 0;
    
    // ENUM_DAY_OF_WEEK로 명시적 타입 변환
    ENUM_DAY_OF_WEEK day = (ENUM_DAY_OF_WEEK)time_struct.day_of_week;
    
    if(!SymbolInfoSessionTrade(Symbol(), day, 0, from, to))
        return false;
        
    if(from == 0 || to == 0)  // 세션 정보를 가져오지 못한 경우
        return false;
        
    MqlDateTime session_from, session_to;
    TimeToStruct(from, session_from);
    TimeToStruct(to, session_to);
    
    // 현재 시간이 거래 세션 안에 있는지 확인
    if(time_struct.hour > session_from.hour && time_struct.hour < session_to.hour)
        return true;
        
    if(time_struct.hour == session_from.hour && time_struct.min >= session_from.min)
        return true;
        
    if(time_struct.hour == session_to.hour && time_struct.min < session_to.min)
        return true;
        
    return false;
}

//+------------------------------------------------------------------+
//| 매수 포지션 오픈                                                    |
//+------------------------------------------------------------------+
bool OpenBuy()
{
    if(!IsMarketOpen())
    {
        Print("Market is closed");
        return false;
    }
    
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double sl = ask - StopLoss * Point() * 10;
    double tp = UseFixedTP ? ask + TakeProfit * Point() * 10 : 0;
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = LotSize;
    request.type = ORDER_TYPE_BUY;
    request.price = ask;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 10;
    request.magic = magicNumber;
    request.comment = "Simple Candle Strategy Buy";
    request.type_filling = ORDER_FILLING_IOC;
    
    bool success = OrderSend(request, result);
    
    if(!success) 
    {
        Print("OrderSend failed with error #", GetLastError());
        return false;
    }
    
    if(result.retcode != TRADE_RETCODE_DONE)
    {
        Print("OrderSend failed with retcode #", result.retcode);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 매도 포지션 오픈                                                    |
//+------------------------------------------------------------------+
bool OpenSell()
{
    if(!IsMarketOpen())
    {
        Print("Market is closed");
        return false;
    }
    
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl = bid + StopLoss * Point() * 10;
    double tp = UseFixedTP ? bid - TakeProfit * Point() * 10 : 0;
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = LotSize;
    request.type = ORDER_TYPE_SELL;
    request.price = bid;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 10;
    request.magic = magicNumber;
    request.comment = "Simple Candle Strategy Sell";
    request.type_filling = ORDER_FILLING_IOC;
    
    bool success = OrderSend(request, result);
    
    if(!success) 
    {
        Print("OrderSend failed with error #", GetLastError());
        return false;
    }
    
    if(result.retcode != TRADE_RETCODE_DONE)
    {
        Print("OrderSend failed with retcode #", result.retcode);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 포지션 청산                                                         |
//+------------------------------------------------------------------+
bool ClosePosition()
{
    if(!IsMarketOpen())
    {
        Print("Market is closed");
        return false;
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = Symbol();
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                   SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    request.deviation = 10;
    request.magic = magicNumber;
    request.comment = "Close Position";
    request.type_filling = ORDER_FILLING_IOC;
    
    bool success = OrderSend(request, result);
    
    if(!success) 
    {
        Print("OrderSend failed with error #", GetLastError());
        return false;
    }
    
    if(result.retcode != TRADE_RETCODE_DONE)
    {
        Print("OrderSend failed with retcode #", result.retcode);
        return false;
    }
    
    return true;
} 