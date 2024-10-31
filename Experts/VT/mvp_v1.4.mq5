// ... (기존 코드 유지)

#include <Trade\Trade.mqh>

// 전역 변수
CTrade trade;
bool orderExecuted = false;
int ma_handle;
datetime lastOrderTime = 0;
int barsHeld = 0;

int OnInit()
{
    // 틱사이즈와 틱벨류 정보 출력
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    
    Print("심볼: ", Symbol());
    Print("틱사이즈: ", DoubleToString(tickSize, 8));
    Print("틱벨류: ", DoubleToString(tickValue, 2));
    
    // 거래 관련 정보 출력
    double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
    
    double volumeMin = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double volumeMax = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double volumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    Print("최소 거래량 (VolumeMin): ", DoubleToString(volumeMin, 2));
    Print("최대 거래량 (VolumeMax): ", DoubleToString(volumeMax, 2));
    Print("거래량 단계 (VolumeStep): ", DoubleToString(volumeStep, 2));
    Print("계약 크기 (ContractSize): ", DoubleToString(contractSize, 8));
    
    // 20일 이동평균선 핸들 생성
    ma_handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
    if(ma_handle == INVALID_HANDLE)
    {
        Print("이동평균선 지표 생성 실패");
        return(INIT_FAILED);
    }

    Print("MVP v1.4 초기화됨");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // 지표 핸들 해제
    IndicatorRelease(ma_handle);
    
    // 모든 포지션 종료
    trade.PositionClose(Symbol());
    Print("MVP v1.4 종료됨. 주문 실행 여부: ", (orderExecuted ? "예" : "아니오"));
}

void OnTick()
{
    if(orderExecuted)
        return;

    // 현재 포지션 확인
    if(PositionSelect(Symbol()))
    {
        // 포지션이 열려있으면 청산 조건 확인
        barsHeld++;
        if(barsHeld >= 10)
        {
            if(trade.PositionClose(Symbol()))
            {
                Print("포지션 청산: 10봉 경과");
                barsHeld = 0;
                orderExecuted = true;  // 청산 후 더 이상 주문 실행 안 함
            }
        }
        return;
    }

    // 새로운 봉이 생성되었는지 확인
    if(lastOrderTime == iTime(Symbol(), PERIOD_CURRENT, 0))
        return;

    double ma[], close[];
    ArraySetAsSeries(ma, true);
    ArraySetAsSeries(close, true);

    // 이동평균선과 종가 데이터 가져오기
    if(CopyBuffer(ma_handle, 0, 0, 3, ma) != 3 || CopyClose(Symbol(), PERIOD_CURRENT, 0, 3, close) != 3)
    {
        Print("데이터 복사 실패");
        return;
    }

    // 상향 돌파 확인
    if(close[1] > ma[1] && close[2] <= ma[2])
    {
        double volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
        if(trade.Buy(volume, Symbol(), 0, 0, 0, "MA Crossover Long"))
        {
            Print("롱 포지션 진입: 가격 = ", SymbolInfoDouble(Symbol(), SYMBOL_ASK), ", 수량 = ", volume);
            lastOrderTime = iTime(Symbol(), PERIOD_CURRENT, 0);
            barsHeld = 0;
            orderExecuted = true;  // 주문 실행 후 플래그 설정
        }
        else
        {
            Print("주문 실패. 에러 코드: ", GetLastError());
        }
    }
}
