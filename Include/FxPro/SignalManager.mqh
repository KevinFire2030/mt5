//+------------------------------------------------------------------+
//| 시그널 타입 열거형                                                 |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
    SIGNAL_NONE,     // 시그널 없음
    SIGNAL_BUY,      // 매수 시그널
    SIGNAL_SELL,     // 매도 시그널
    SIGNAL_CLOSE     // 청산 시그널
};

//+------------------------------------------------------------------+
//| 시그널 매니저 클래스                                               |
//+------------------------------------------------------------------+
class CSignalManager
{
private:
    // 시그널 계산에 필요한 데이터
    double m_ema5[];
    double m_ema20[];
    double m_ema40[];
    
    // 시그널 상태
    ENUM_SIGNAL_TYPE m_currentSignal;    // 현재 시그널
    datetime m_lastSignalTime;           // 마지막 시그널 시간
    
    // EMA 정배열/역배열 체크
    bool IsEMAAligned(bool isLong);      // EMA 배열 체크
    
public:
    // 생성자/소멸자
    CSignalManager();
    ~CSignalManager();
    
    // 초기화/업데이트
    bool Init();
    bool Update(double &ema5[], double &ema20[], double &ema40[]);
    
    // 시그널 계산
    ENUM_SIGNAL_TYPE Calculate();
    
    // 시그널 조건 체크
    bool IsBuySignal();      // 매수 시그널 체크 (EMA 정배열)
    bool IsSellSignal();     // 매도 시그널 체크 (EMA 역배열)
    bool IsCloseSignal();    // 청산 시그널 체크 (배열 이탈)
};

//+------------------------------------------------------------------+
//| 생성자                                                             |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager(void)
{
    m_currentSignal = SIGNAL_NONE;
    m_lastSignalTime = 0;
}

//+------------------------------------------------------------------+
//| 소멸자                                                             |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager(void)
{
}

//+------------------------------------------------------------------+
//| 초기화                                                             |
//+------------------------------------------------------------------+
bool CSignalManager::Init()
{
    return true;
}

//+------------------------------------------------------------------+
//| 데이터 업데이트                                                    |
//+------------------------------------------------------------------+
bool CSignalManager::Update(double &ema5[], double &ema20[], double &ema40[])
{
    ArrayCopy(m_ema5, ema5);
    ArrayCopy(m_ema20, ema20);
    ArrayCopy(m_ema40, ema40);
    return true;
}

//+------------------------------------------------------------------+
//| EMA 정배열/역배열 체크                                             |
//+------------------------------------------------------------------+
bool CSignalManager::IsEMAAligned(bool isLong)
{
    if(isLong)
        return (m_ema5[1] > m_ema20[1] && m_ema20[1] > m_ema40[1]);  // 정배열
    else
        return (m_ema5[1] < m_ema20[1] && m_ema20[1] < m_ema40[1]);  // 역배열
}

//+------------------------------------------------------------------+
//| 매수 시그널 체크                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::IsBuySignal()
{
    return IsEMAAligned(true);  // EMA 정배열 체크
}

//+------------------------------------------------------------------+
//| 매도 시그널 체크                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::IsSellSignal()
{
    return IsEMAAligned(false);  // EMA 역배열 체크
}

//+------------------------------------------------------------------+
//| 청산 시그널 체크                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::IsCloseSignal()
{
    // 현재 시그널이 매수인 경우 정배열 이탈 체크
    if(m_currentSignal == SIGNAL_BUY)
        return !IsEMAAligned(true);
        
    // 현재 시그널이 매도인 경우 역배열 이탈 체크
    if(m_currentSignal == SIGNAL_SELL)
        return !IsEMAAligned(false);
        
    return false;
}

//+------------------------------------------------------------------+
//| 시그널 계산                                                        |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalManager::Calculate()
{
    // 청산 시그널 체크
    if(IsCloseSignal())
    {
        m_currentSignal = SIGNAL_CLOSE;
        return SIGNAL_CLOSE;
    }
    
    // 매수 시그널 체크
    if(IsBuySignal())
    {
        m_currentSignal = SIGNAL_BUY;
        return SIGNAL_BUY;
    }
    
    // 매도 시그널 체크
    if(IsSellSignal())
    {
        m_currentSignal = SIGNAL_SELL;
        return SIGNAL_SELL;
    }
    
    // 시그널 없음
    m_currentSignal = SIGNAL_NONE;
    return SIGNAL_NONE;
} 