//+------------------------------------------------------------------+
//| 포지션 정보 구조체                                                 |
//+------------------------------------------------------------------+
struct SPositionInfo
{
    // 포지션 식별
    string            symbol;              // 심볼
    ulong             ticket;             // 포지션 티켓
    int               magic;              // 매직 넘버
    ENUM_POSITION_TYPE type;              // 포지션 타입
    
    // 포지션 상세
    double            volume;             // 포지션 크기
    double            entryPrice;         // 진입 가격
    datetime          entryTime;          // 진입 시간
    double            stopLoss;           // 손절가
    double            takeProfit;         // 이익실현가
    double            entryATR;           // 진입 시점 ATR
};

//+------------------------------------------------------------------+
//| 심볼별 피라미딩 정보 구조체                                        |
//+------------------------------------------------------------------+
struct SPyramidingInfo
{
    string           symbol;              // 심볼
    int              count;              // 피라미딩 횟수
};

//+------------------------------------------------------------------+
//| 포지션 매니저 클래스                                               |
//+------------------------------------------------------------------+
class CPositionManager
{
private:
    // 포지션 설정
    int               m_maxPositions;      // 최대 포지션 수
    int               m_maxPyramiding;     // 최대 피라미딩 수
    
    // 포지션 관리
    SPositionInfo     m_positions[];       // 포지션 정보 배열
    SPyramidingInfo   m_pyramiding[];     // 심볼별 피라미딩 정보
    int               m_positionCount;     // 현재 포지션 수
    
    // 헬퍼 함수
    int               FindPosition(string symbol);  // 심볼로 포지션 찾기
    bool              CanAddPyramiding(string symbol);  // 피라미딩 가능 여부
    int               FindPyramiding(string symbol);  // 심볼의 피라미딩 정보 찾기
    
public:
    // 생성자/소멸자
                     CPositionManager();
                    ~CPositionManager();
    
    // 초기화
    bool             Init(int maxPositions, int maxPyramiding);
    
    // 포지션 관리
    bool             OpenPosition(string symbol, int magic, ENUM_POSITION_TYPE type, 
                                double volume, double sl, double tp, double atr);
    bool             ClosePosition(string symbol);
    bool             HasPosition(string symbol) const;
    
    // 포지션 정보
    bool             GetPositionInfo(string symbol, SPositionInfo &info) const;
    int              GetTotalPositions() const { return m_positionCount; }
    int              GetSymbolPyramiding(string symbol) const;
    
    // 상태 체크
    bool             CanOpenPosition() const { return m_positionCount < m_maxPositions; }
    bool             CanAddPosition(string symbol) const;
};

//+------------------------------------------------------------------+
//| 생성자                                                             |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager(void)
{
    m_maxPositions = 0;
    m_maxPyramiding = 0;
    m_positionCount = 0;
    
    ArrayResize(m_positions, 0);
    ArrayResize(m_pyramiding, 0);
}

//+------------------------------------------------------------------+
//| 소멸자                                                             |
//+------------------------------------------------------------------+
CPositionManager::~CPositionManager(void)
{
    ArrayFree(m_positions);
    ArrayFree(m_pyramiding);
}

//+------------------------------------------------------------------+
//| 초기화                                                             |
//+------------------------------------------------------------------+
bool CPositionManager::Init(int maxPositions, int maxPyramiding)
{
    if(maxPositions <= 0 || maxPyramiding <= 0)
        return false;
        
    m_maxPositions = maxPositions;
    m_maxPyramiding = maxPyramiding;
    m_positionCount = 0;
    
    ArrayResize(m_positions, 0);
    ArrayResize(m_pyramiding, 0);
    
    return true;
}

//+------------------------------------------------------------------+
//| 심볼로 포지션 찾기                                                 |
//+------------------------------------------------------------------+
int CPositionManager::FindPosition(string symbol)
{
    for(int i = 0; i < m_positionCount; i++)
    {
        if(m_positions[i].symbol == symbol)
            return i;
    }
    return -1;  // 찾지 못함
}

//+------------------------------------------------------------------+
//| 심볼의 피라미딩 정보 찾기                                          |
//+------------------------------------------------------------------+
int CPositionManager::FindPyramiding(string symbol)
{
    int count = ArraySize(m_pyramiding);
    for(int i = 0; i < count; i++)
    {
        if(m_pyramiding[i].symbol == symbol)
            return i;
    }
    return -1;  // 찾지 못함
}

//+------------------------------------------------------------------+
//| 피라미딩 가능 여부 체크                                            |
//+------------------------------------------------------------------+
bool CPositionManager::CanAddPyramiding(string symbol)
{
    int index = FindPyramiding(symbol);
    if(index == -1)
        return true;  // 첫 진입
        
    return m_pyramiding[index].count < m_maxPyramiding;
}

//+------------------------------------------------------------------+
//| 포지션 오픈                                                        |
//+------------------------------------------------------------------+
bool CPositionManager::OpenPosition(string symbol, int magic, ENUM_POSITION_TYPE type, 
                                  double volume, double sl, double tp, double atr)
{
    // 최대 포지션 수 체크
    if(!CanOpenPosition())
        return false;
        
    // 피라미딩 가능 여부 체크
    int posIndex = FindPosition(symbol);
    if(posIndex != -1)  // 이미 포지션 있음
    {
        if(!CanAddPyramiding(symbol))
            return false;
            
        // 피라미딩 카운트 증가
        int pyramidIndex = FindPyramiding(symbol);
        if(pyramidIndex == -1)
        {
            pyramidIndex = ArraySize(m_pyramiding);
            ArrayResize(m_pyramiding, pyramidIndex + 1);
            m_pyramiding[pyramidIndex].symbol = symbol;
            m_pyramiding[pyramidIndex].count = 1;
        }
        else
        {
            m_pyramiding[pyramidIndex].count++;
        }
    }
    
    // 새 포지션 추가
    int newIndex = m_positionCount;
    ArrayResize(m_positions, newIndex + 1);
    
    // 포지션 정보 설정
    m_positions[newIndex].symbol = symbol;
    m_positions[newIndex].magic = magic;
    m_positions[newIndex].type = type;
    m_positions[newIndex].volume = volume;
    m_positions[newIndex].stopLoss = sl;
    m_positions[newIndex].takeProfit = tp;
    m_positions[newIndex].entryATR = atr;
    m_positions[newIndex].entryTime = TimeCurrent();
    
    m_positionCount++;
    return true;
}

//+------------------------------------------------------------------+
//| 포지션 종료                                                        |
//+------------------------------------------------------------------+
bool CPositionManager::ClosePosition(string symbol)
{
    // 해당 심볼의 모든 포지션을 찾아서 제거
    int posCount = m_positionCount;  // 원래 카운트 저장
    
    // 뒤에서부터 검색 (배열 제거시 인덱스 변화 방지)
    for(int i = posCount - 1; i >= 0; i--)
    {
        if(m_positions[i].symbol == symbol)
        {
            // 포지션 제거
            ArrayRemove(m_positions, i, 1);
            m_positionCount--;
        }
    }
    
    // 피라미딩 정보 완전 제거
    int pyramidIndex = FindPyramiding(symbol);
    if(pyramidIndex != -1)
    {
        ArrayRemove(m_pyramiding, pyramidIndex, 1);
    }
    
    // 하나라도 제거되었다면 성공
    return posCount > m_positionCount;
}

//+------------------------------------------------------------------+
//| 포지션 존재 여부                                                   |
//+------------------------------------------------------------------+
bool CPositionManager::HasPosition(string symbol) const
{
    for(int i = 0; i < m_positionCount; i++)
    {
        if(m_positions[i].symbol == symbol)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| 포지션 정보 조회                                                   |
//+------------------------------------------------------------------+
bool CPositionManager::GetPositionInfo(string symbol, SPositionInfo &info) const
{
    for(int i = 0; i < m_positionCount; i++)
    {
        if(m_positions[i].symbol == symbol)
        {
            info = m_positions[i];
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| 심볼의 피라미딩 횟수 조회                                          |
//+------------------------------------------------------------------+
int CPositionManager::GetSymbolPyramiding(string symbol) const
{
    for(int i = 0; i < ArraySize(m_pyramiding); i++)
    {
        if(m_pyramiding[i].symbol == symbol)
            return m_pyramiding[i].count;
    }
    return 0;  // 피라미딩 없음
}

//+------------------------------------------------------------------+
//| 포지션 추가 가능 여부                                              |
//+------------------------------------------------------------------+
bool CPositionManager::CanAddPosition(string symbol) const
{
    // 최대 포지션 수 체크
    if(!CanOpenPosition())
        return false;
        
    // 기존 포지션이 있는 경우 피라미딩 가능 여부 체크
    for(int i = 0; i < m_positionCount; i++)
    {
        if(m_positions[i].symbol == symbol)
        {
            for(int j = 0; j < ArraySize(m_pyramiding); j++)
            {
                if(m_pyramiding[j].symbol == symbol)
                    return m_pyramiding[j].count < m_maxPyramiding;
            }
            return true;  // 피라미딩 정보 없음 (첫 피라미딩 가능)
        }
    }
    
    return true;  // 새 포지션 가능
} 