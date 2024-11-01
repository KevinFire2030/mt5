//+------------------------------------------------------------------+
//| vTrader 클래스 정의                                                |
//+------------------------------------------------------------------+
// 시그널 매니저 포함
#include <FxPro\SignalManager.mqh>

// 포지션 매니저 포함
#include <FxPro\PositionManager.mqh>

class CvTrader
{
private:
    // 기본 설정 변수
    ENUM_TIMEFRAMES    m_timeframe;        // 타임프레임
    double            m_risk;             // 리스크 비율
    int               m_maxPositions;      // 최대 포지션 수
    int               m_maxPyramiding;     // 최대 피라미딩 수
    
    // 가격 데이터 배열
    double            m_closes[];          // 종가 배열
    double            m_highs[];           // 고가 배열
    double            m_lows[];            // 저가 배열
    double            m_opens[];           // 시가 배열
    
    // 지표 관련 변수
    int               m_ema5Handle;        // EMA 5 핸들
    int               m_ema20Handle;       // EMA 20 핸들
    int               m_ema40Handle;       // EMA 40 핸들
    int               m_atrHandle;         // ATR 핸들
    
    double            m_ema5Buffer[];      // EMA 5 버퍼
    double            m_ema20Buffer[];     // EMA 20 버퍼
    double            m_ema40Buffer[];     // EMA 40 버퍼
    double            m_atrBuffer[];       // ATR 버퍼
    
    // 트레이딩 상태 변수
    bool              m_isNewBar;          // 새로운 봉 여부
    datetime          m_lastBarTime;       // 마지막 봉 시간
    
    // 데이터 관리 함수
    bool              UpdatePriceArrays();
    bool              UpdateIndicators();
    bool              IsNewBar();
    
    // 틱 볼륨 배열 추가
    long              m_tickVolumes[];     // 틱 볼륨 배열
    
    // 시그널 매니저 추가
    CSignalManager     m_signalManager;
    
    // 포지션 매니저 추가
    CPositionManager     m_positionManager;
    
public:
                     CvTrader(void);
                    ~CvTrader(void);
    
    // 초기화 및 해제
    bool              Init(ENUM_TIMEFRAMES timeframe, double risk, 
                         int maxPositions, int maxPyramiding);
    void              Deinit();
    
    // 틱 처리
    void              OnTick();
    
    // 지표 값 접근자
    double            EMA5(int index) const { return m_ema5Buffer[index]; }
    double            EMA20(int index) const { return m_ema20Buffer[index]; }
    double            EMA40(int index) const { return m_ema40Buffer[index]; }
    double            ATR(int index) const { return m_atrBuffer[index]; }
    
    // 테스트용 출력 함수
    void              PrintData();
    
    // 시그널 테스트용 함수 추가
    void              TestSignal();
    
    // 포지션 테스트용 함수 추가
    void              TestPosition();
    
    // 실제 트레이딩 테스트
    void              TestLiveTrading();
    
    // ATR 값 가져오기
    double            GetATR();
    
    // 리스크 관리 테스트
    void              TestRiskManagement();
    
    // 리스크 관리 실제 트레이딩 테스트
    void              TestRiskManagementLive();
};

//+------------------------------------------------------------------+
//| 생성자                                                             |
//+------------------------------------------------------------------+
CvTrader::CvTrader(void)
{
    // 배열을 시계열로 설정
    ArraySetAsSeries(m_opens, true);
    ArraySetAsSeries(m_closes, true);
    ArraySetAsSeries(m_highs, true);
    ArraySetAsSeries(m_lows, true);
    
    // 지표 버퍼 초기화
    ArraySetAsSeries(m_ema5Buffer, true);
    ArraySetAsSeries(m_ema20Buffer, true);
    ArraySetAsSeries(m_ema40Buffer, true);
    ArraySetAsSeries(m_atrBuffer, true);
    
    // 지표 핸들 초기화
    m_ema5Handle = INVALID_HANDLE;
    m_ema20Handle = INVALID_HANDLE;
    m_ema40Handle = INVALID_HANDLE;
    m_atrHandle = INVALID_HANDLE;
    
    // 기타 변수 초기화
    m_lastBarTime = 0;
    m_isNewBar = false;
    
    // 틱 볼륨 배열 추가
    ArraySetAsSeries(m_tickVolumes, true);
}

//+------------------------------------------------------------------+
//| 소멸자                                                             |
//+------------------------------------------------------------------+
CvTrader::~CvTrader(void)
{
    Deinit();
}

//+------------------------------------------------------------------+
//| 초기화                                                             |
//+------------------------------------------------------------------+
bool CvTrader::Init(ENUM_TIMEFRAMES timeframe, double risk, 
                    int maxPositions, int maxPyramiding)
{
    m_timeframe = timeframe;
    m_risk = risk;
    m_maxPositions = maxPositions;
    m_maxPyramiding = maxPyramiding;
    
    // 지표 초기화
    m_ema5Handle = iMA(Symbol(), m_timeframe, 5, 0, MODE_EMA, PRICE_CLOSE);
    m_ema20Handle = iMA(Symbol(), m_timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
    m_ema40Handle = iMA(Symbol(), m_timeframe, 40, 0, MODE_EMA, PRICE_CLOSE);
    m_atrHandle = iATR(Symbol(), m_timeframe, 14);
    
    if(m_ema5Handle == INVALID_HANDLE || 
       m_ema20Handle == INVALID_HANDLE ||
       m_ema40Handle == INVALID_HANDLE ||
       m_atrHandle == INVALID_HANDLE)
    {
        Print("지표 초기화 실패");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 해제                                                               |
//+------------------------------------------------------------------+
void CvTrader::Deinit()
{
    ArrayFree(m_closes);
    ArrayFree(m_highs);
    ArrayFree(m_lows);
    ArrayFree(m_opens);
    ArrayFree(m_tickVolumes);
    
    // 지표 핸들 해제
    if(m_ema5Handle != INVALID_HANDLE) IndicatorRelease(m_ema5Handle);
    if(m_ema20Handle != INVALID_HANDLE) IndicatorRelease(m_ema20Handle);
    if(m_ema40Handle != INVALID_HANDLE) IndicatorRelease(m_ema40Handle);
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    
    ArrayFree(m_ema5Buffer);
    ArrayFree(m_ema20Buffer);
    ArrayFree(m_ema40Buffer);
    ArrayFree(m_atrBuffer);
}

//+------------------------------------------------------------------+
//| 가격 데이터 업데이트                                               |
//+------------------------------------------------------------------+
bool CvTrader::UpdatePriceArrays()
{
    // 최근 100개의 캔들 데이터를 가져옴
    if(CopyOpen(Symbol(), m_timeframe, 0, 100, m_opens) <= 0) return false;
    if(CopyClose(Symbol(), m_timeframe, 0, 100, m_closes) <= 0) return false;
    if(CopyHigh(Symbol(), m_timeframe, 0, 100, m_highs) <= 0) return false;
    if(CopyLow(Symbol(), m_timeframe, 0, 100, m_lows) <= 0) return false;
    if(CopyTickVolume(Symbol(), m_timeframe, 0, 100, m_tickVolumes) <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| 지표 데이터 업데이트                                               |
//+------------------------------------------------------------------+
bool CvTrader::UpdateIndicators()
{
    // EMA 데이터 복사
    if(CopyBuffer(m_ema5Handle, 0, 0, 100, m_ema5Buffer) <= 0) return false;
    if(CopyBuffer(m_ema20Handle, 0, 0, 100, m_ema20Buffer) <= 0) return false;
    if(CopyBuffer(m_ema40Handle, 0, 0, 100, m_ema40Buffer) <= 0) return false;
    
    // ATR 데이터 복사
    if(CopyBuffer(m_atrHandle, 0, 0, 100, m_atrBuffer) <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| 새로운 봉 확인                                                     |
//+------------------------------------------------------------------+
bool CvTrader::IsNewBar()
{
    datetime currentBarTime = iTime(Symbol(), m_timeframe, 0);
    if(currentBarTime != m_lastBarTime)
    {
        m_lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| 테스트용 데이터 출력                                               |
//+------------------------------------------------------------------+
void CvTrader::PrintData()
{
    for(int i=2; i>=0; i--)
    {
        string priceInfo = StringFormat(
            "시간: %s, 시가: %.2f, 고가: %.2f, 저가: %.2f, 종가: %.2f, 틱볼륨: %d",
            TimeToString(iTime(Symbol(), m_timeframe, i)),
            m_opens[i],
            m_highs[i],
            m_lows[i],
            m_closes[i],
            m_tickVolumes[i]
        );
        
        string indicatorInfo = StringFormat(
            "EMA5: %.2f, EMA20: %.2f, EMA40: %.2f, ATR: %.2f",
            m_ema5Buffer[i],
            m_ema20Buffer[i],
            m_ema40Buffer[i],
            m_atrBuffer[i]
        );
        
        Print("=== 데이터 확인 (N-", i, ") ===");
        Print(priceInfo);
        Print(indicatorInfo);
        Print("==================\n");
    }
}

//+------------------------------------------------------------------+
//| 시그널 테스트용 함수                                               |
//+------------------------------------------------------------------+
void CvTrader::TestSignal()
{
    // 시그널 매니저 업데이트
    if(!m_signalManager.Update(m_ema5Buffer, m_ema20Buffer, m_ema40Buffer))
    {
        Print("시그널 매니저 업데이트 실패");
        return;
    }
    
    // 시그널 계산
    ENUM_SIGNAL_TYPE signal = m_signalManager.Calculate();
    
    // 시그널 정보 출력
    string signalInfo = "";
    switch(signal)
    {
        case SIGNAL_BUY:    signalInfo = "매수 시그널"; break;
        case SIGNAL_SELL:   signalInfo = "매도 시그널"; break;
        case SIGNAL_CLOSE:  signalInfo = "청산 시그널"; break;
        default:           signalInfo = "시그널 없음"; break;
    }
    
    Print("=== 시그널 테스트 ===");
    Print("시간: ", TimeToString(iTime(Symbol(), m_timeframe, 1)));
    Print("시그널: ", signalInfo);
    Print("EMA5: ", m_ema5Buffer[1]);
    Print("EMA20: ", m_ema20Buffer[1]);
    Print("EMA40: ", m_ema40Buffer[1]);
    Print("==================\n");
}

//+------------------------------------------------------------------+
//| 포지션 테스트용 함수                                               |
//+------------------------------------------------------------------+
void CvTrader::TestPosition()
{
    Print("\n=== 포지션 매니저 테스트 시작 ===");
    
    // 1. 초기화 테스트
    if(!m_positionManager.Init(10, 4))
    {
        Print("포지션 매니저 초기화 실패");
        return;
    }
    Print("포지션 매니저 초기화 성공");
    Print("최대 포지션 수: 10");
    Print("최대 피라미딩 수: 4");
    
    string symbol = Symbol();
    int magic = 12345;
    double atr = 10.0;  // 테스트용 임시 ATR 값
    
    // 2. 포지션 오픈 테스트
    Print("\n--- 포지션 오픈 테스트 ---");
    if(m_positionManager.OpenPosition(symbol, magic, POSITION_TYPE_BUY, 0.1, 0, 0, atr))
    {
        Print("포지션 오픈 성공");
        
        // 포지션 정보 확인
        SPositionInfo posInfo;
        if(m_positionManager.GetPositionInfo(symbol, posInfo))
        {
            Print("심볼: ", posInfo.symbol);
            Print("매직넘버: ", posInfo.magic);
            Print("타입: ", posInfo.type == POSITION_TYPE_BUY ? "매수" : "매도");
            Print("볼륨: ", posInfo.volume);
            Print("진입시간: ", TimeToString(posInfo.entryTime));
            Print("ATR: ", posInfo.entryATR);
        }
    }
    
    // 3. 피라미딩 테스트
    Print("\n--- 피라미딩 테스트 ---");
    if(m_positionManager.OpenPosition(symbol, magic, POSITION_TYPE_BUY, 0.1, 0, 0, atr))
    {
        Print("피라미딩 추가 성공");
        Print("현재 피라미딩 횟수: ", m_positionManager.GetSymbolPyramiding(symbol));
    }
    
    // 4. 포지션 상태 체크
    Print("\n--- 포지션 상태 체크 ---");
    Print("총 포지션 수: ", m_positionManager.GetTotalPositions());
    Print("심볼 포지션 여부: ", m_positionManager.HasPosition(symbol) ? "있음" : "없음");
    Print("추가 포지션 가능 여부: ", m_positionManager.CanAddPosition(symbol) ? "가능" : "가가능");
    
    // 5. 포지션 종료 테스트
    Print("\n--- 포지션 종료 테스트 ---");
    if(m_positionManager.ClosePosition(symbol))
    {
        Print("포지션 종료 성공");
        Print("남은 포지션 수: ", m_positionManager.GetTotalPositions());
        Print("심볼 포지션 여부: ", m_positionManager.HasPosition(symbol) ? "있음" : "없음");
    }
    
    Print("\n=== 포지션 매니저 테스트 종료 ===\n");
}

//+------------------------------------------------------------------+
//| 실제 트레이딩 테스트                                               |
//+------------------------------------------------------------------+
void CvTrader::TestLiveTrading()
{
    Print("\n=== 실제 트레이딩 테스트 시작 ===");
    
    string symbol = Symbol();
    int magic = 12345;
    
    // ATR 계산
    double atr = GetATR();
    if(atr == 0)
    {
        Print("ATR 계산 실패");
        return;
    }
    Print("현재 ATR: ", atr);
    
    // 1. 포지션 매니저 초기화
    if(!m_positionManager.Init(10, 4))
    {
        Print("포지션 매니저 초기화 실패");
        return;
    }
    
    // 터틀 설정
    STurtleUnitSettings turtleSettings;
    turtleSettings.riskPercent = 1.0;  // 1%
    turtleSettings.atrPeriod = 20;     // 20일
    turtleSettings.minLot = 0.01;      // 최소 0.01랏
    m_positionManager.SetTurtleSettings(turtleSettings);
    
    Print("포지션 매니저 초기화 성공");
    
    // 2. 정상 포지션 오픈
    Print("\n--- 정상 포지션 오픈 테스트 ---");
    
    // SL/TP 계산
    MqlTick lastTick;
    SymbolInfoTick(symbol, lastTick);
    double sl = lastTick.ask - (atr * 2);  // ATR의 2배를 SL로 설정
    double tp = lastTick.ask + (atr * 3);  // ATR의 3배를 TP로 설정
    
    // 더미 volume 값 (터틀 계산으로 대체됨)
    double volume = 0.01;
    
    if(m_positionManager.OpenPosition(symbol, magic, POSITION_TYPE_BUY, volume, sl, tp, atr))
    {
        Print("매수 포지션 오픈 성공");
        
        // 포지션 정보 확인
        SPositionInfo posInfo;
        if(m_positionManager.GetPositionInfo(symbol, posInfo))
        {
            Print("티켓: ", posInfo.ticket);
            Print("진입가격: ", posInfo.entryPrice);
            Print("거래량: ", posInfo.volume, " (1유닛)");
            Print("SL: ", posInfo.stopLoss);
            Print("TP: ", posInfo.takeProfit);
            Print("ATR: ", posInfo.entryATR);
            Print("계산된 리스크 금액: $", 100.0 * 0.01); // 테스트용 $100의 1%
        }
        
        // 3. 피라미딩 테스트
        Print("\n--- 피라미딩 테스트 ---");
        if(m_positionManager.OpenPosition(symbol, magic, POSITION_TYPE_BUY, volume, sl, tp, atr))
        {
            Print("피라미딩 추가 성공");
            Print("현재 피라미딩 횟수: ", m_positionManager.GetSymbolPyramiding(symbol));
        }
        else
        {
            Print("피라미딩 추가 실패: ", m_positionManager.GetLastErrorString());
        }
        
        // 4. 포지션 종료
        Print("\n--- 포지션 종료 테스트 ---");
        Sleep(1000);
        if(m_positionManager.ClosePosition(symbol))
        {
            Print("모든 포지션 종료 성공");
        }
        else
        {
            Print("포지션 종료 실패: ", m_positionManager.GetLastErrorString());
        }
    }
    else
    {
        Print("포지션 오픈 실패: ", m_positionManager.GetLastErrorString());
    }
    
    Print("\n=== 실제 트레이딩 테스트 종료 ===\n");
}

//+------------------------------------------------------------------+
//| ATR 값 가져오기                                                    |
//+------------------------------------------------------------------+
double CvTrader::GetATR()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    
    int handle = iATR(Symbol(), Period(), 14);
    if(handle == INVALID_HANDLE)
        return 0;
        
    if(CopyBuffer(handle, 0, 0, 1, atr) <= 0)
    {
        IndicatorRelease(handle);
        return 0;
    }
    
    IndicatorRelease(handle);
    return atr[0];
}

//+------------------------------------------------------------------+
//| 틱 처리                                                            |
//+------------------------------------------------------------------+
void CvTrader::OnTick()
{
    // 데이터 업데이트
    if(!UpdatePriceArrays() || !UpdateIndicators())
        return;
    
    // 새로운 봉에서만 처리
    m_isNewBar = IsNewBar();
    if(m_isNewBar)
    {
        //PrintData();        // 데이터 출력
        //TestSignal();       // 시그널 테스트
        //TestLiveTrading();  // 실제 트레이딩 테스트
        //TestRiskManagement(); // 리스크 관리 테스트
        TestRiskManagementLive(); // 리스크 관리 실제 테스트

    }
}

//+------------------------------------------------------------------+
//| 리스크 관리 테스트                                                 |
//+------------------------------------------------------------------+
void CvTrader::TestRiskManagement()
{
    string symbol = Symbol();
    
    // 1. ATR 계산
    double atr = GetATR();
    Print("\n=== ATR 계산 결과 ===");
    Print("ATR: ", atr);
    Print("2N (2*ATR): ", 2*atr);
    
    // 2. 첫 번째 포지션 진입 테스트 (매수)
    double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
    // double volume = CalculateTurtleUnits(symbol, atr);
    double volume = 0.01;  // 테스트용 기본 거래량
    
    Print("\n=== 첫 번째 포지션 진입 (매수) ===");
    Print("진입가: ", entryPrice);
    Print("거래량: ", volume);
    
    // 3. 스탑로스 계산
    double stopLoss = entryPrice - (2 * atr);  // 매수 포지션의 경우
    Print("스탑로스: ", stopLoss);
    Print("손실폭(핍): ", MathAbs(entryPrice - stopLoss) / Point());
    
    // 4. 매도 포지션 테스트
    entryPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
    stopLoss = entryPrice + (2 * atr);  // 매도 포지션의 경우
    
    Print("\n=== 매도 포지션 테스트 ===");
    Print("진입가: ", entryPrice);
    Print("스탑로스: ", stopLoss);
    Print("손실폭(핍): ", MathAbs(entryPrice - stopLoss) / Point());
}

//+------------------------------------------------------------------+
//| 리스크 관리 실제 트레이딩 테스트                                   |
//+------------------------------------------------------------------+
void CvTrader::TestRiskManagementLive()
{
    string symbol = Symbol();
    int m_magic = 12345;
    
    Print("\n=== 리스크 관리 실제 트레이딩 테스트 ===");
    
    // 1. ATR 계산
    double atr = GetATR();
    Print("현재 ATR: ", atr);
    
    // 1. 포지션 매니저 초기화
    if(!m_positionManager.Init(10, 4))
    {
        Print("포지션 매니저 초기화 실패");
        return;
    }
    Print("포지션 매니저 초기화 성공");
    
    Print("\n--- 정상 포지션 오픈 테스트 ---\n");
    
    // 3. 매수 포지션 오픈
    double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double stopLoss = entryPrice - (2 * atr);  // 2N 기반 스탑로스
    double volume = 0.1;  // 테스트용 기본 거래량
    
    if(!m_positionManager.OpenPosition(symbol, m_magic, POSITION_TYPE_BUY, volume, entryPrice, stopLoss, atr))
    {
        Print("매수 포지션 오픈 실패");
        return;
    }
    Print("매수 포지션 오픈 성공\n");
    
    Print("--- 피라미딩 테스트 ---\n");
    
    
    Sleep(1000);  // 1초 대기
    
    
    // 4. 피라미딩 진입
    entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
    stopLoss = entryPrice - (2 * atr);  // 새로운 진입가 기준 스탑로스
    
    if(!m_positionManager.OpenPosition(symbol, m_magic, POSITION_TYPE_BUY, volume, entryPrice, stopLoss, atr))
    {
        Print("피라미딩 추가 실패");
        return;
    }
    Print("피라미딩 추가 성공");
    
    
    Sleep(1000);  // 1초 대기
    
    // 스탑로스 동기화 부분 수정
   Print("\n--- 스탑로스 동기화 테스트 ---");
   Print("새로운 스탑로스: ", stopLoss);

   // 새로 생성된 피라미딩 포지션의 티켓 저장
   ulong newPositionTicket = m_positionManager.GetLastPositionTicket();
   Print("새로 생성된 피라미딩 포지션 티켓: ", newPositionTicket);
   
   bool foundAny = false;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
       // 포지션 선택
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket)) 
        {
            Print("포지션 선택 실패: ", GetLastError());
            continue;
        }
        
        // 새로 생성된 피라미딩 포지션은 건너뛰기
        if(ticket == newPositionTicket)
        {
            Print("새 피라미딩 포지션은 스킵: #", ticket);
            continue;
        }
       
       // 포지션 정보 가져오기
       string posSymbol = PositionGetString(POSITION_SYMBOL);
       long posMagic = PositionGetInteger(POSITION_MAGIC);
       ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
       
       Print("검사중: 심볼=", posSymbol, ", 매직=", posMagic, " (목표: ", symbol, ", ", m_magic, ")");
       
       if(posSymbol != symbol || posMagic != m_magic) continue;
       
       foundAny = true;
       //ulong ticket = PositionGetTicket(i);
       double currentStopLoss = PositionGetDouble(POSITION_SL);
       double positionPrice = PositionGetDouble(POSITION_PRICE_OPEN);
       
       Print("포지션 발견 #", ticket, 
             "\n  진입가: ", positionPrice,
             "\n  기존 스탑로스: ", currentStopLoss,
             "\n  새로운 스탑로스: ", stopLoss,
             "\n  포지션 타입: ", EnumToString(posType));
       
       if(!m_positionManager.ModifyPosition(ticket, 0, stopLoss))
       {
           Print("포지션 #", ticket, " 스탑로스 수정 실패: ", GetLastError());
           continue;
       }
       Print("포지션 #", ticket, " 스탑로스 수정 성공");
   }
   
   if(!foundAny)
   {
       Print("동기화할 포지션을 찾을 수 없습니다");
       Print("현재 총 포지션 수: ", PositionsTotal());
   }
   
   Print("스탑로스 동기화 완료\n");
    
    // 5. 모든 포지션 종료
    if(!m_positionManager.ClosePosition(symbol))
    {
        Print("포지션 종료 실패");
        return;
    }
    Print("모든 포지션 종료 성공\n");
    
    Print("=== 실제 트레이딩 테스트 종료 ===\n");
}

