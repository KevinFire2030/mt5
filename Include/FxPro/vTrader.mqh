//+------------------------------------------------------------------+
//| vTrader 클래스 정의                                                |
//+------------------------------------------------------------------+
// 시그널 매니저 포함
#include <FxPro\SignalManager.mqh>

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
//| 틱 처리                                                            |
//+------------------------------------------------------------------+
void CvTrader::OnTick()
{
    // 데이터 업데이트
    if(!UpdatePriceArrays() || !UpdateIndicators())
    {
        Print("데이터 업데이트 실패");
        return;
    }
    
    // 새로운 봉에서만 처리
    m_isNewBar = IsNewBar();
    if(m_isNewBar)
    {
        PrintData();     // 데이터 출력
        TestSignal();    // 시그널 테스트
    }
} 