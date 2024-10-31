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
#include <Trade\Trade.mqh>

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
    
    // 트레이드 객체
    CTrade            m_trade;            // 트레이드 객체
    
    // 헬퍼 함수
    int               FindPosition(string symbol);  // 심볼로 포지션 찾기
    bool              CanAddPyramiding(string symbol);  // 피라미딩 가능 여부
    int               FindPyramiding(string symbol);  // 심볼의 피라미딩 정보 찾기
    bool              SyncPositions();    // 실제 포지션과 동기화
    
public:
    // 생성자/소멸자
                     CPositionManager();
                    ~CPositionManager();
    
    // 초화
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
    
    // 실제 트레이딩
    bool             ExecuteOrder(string symbol, int magic, ENUM_POSITION_TYPE type, 
                                double volume, double price, double sl, double tp);
    bool             ExecuteClose(string symbol, ulong ticket);
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
    {
        Print("최대 포지션 수 초과");
        return false;
    }
        
    // 피라미딩 가능 여부 체크
    int posIndex = FindPosition(symbol);
    if(posIndex != -1)  // 이미 포지션 있음
    {
        if(!CanAddPyramiding(symbol))
        {
            Print("최대 피라미딩 횟수 초과");
            return false;
        }
            
        // 기존 포지션과 같은 방향인지 확인
        if(m_positions[posIndex].type != type)
        {
            Print("기존 포지션과 반대 방향으로 피라미딩 불가");
            return false;
        }
    }
    
    // 현재가 확인
    MqlTick lastTick;
    if(!SymbolInfoTick(symbol, lastTick))
    {
        Print("가격 정보 조회 실패");
        return false;
    }
    
    // 주문 가격 설정
    double price = (type == POSITION_TYPE_BUY) ? lastTick.ask : lastTick.bid;
    
    // 실제 주문 실행
    if(!ExecuteOrder(symbol, magic, type, volume, price, sl, tp))
    {
        Print("주문 실행 실패");
        return false;
    }
    
    // ATR 정보 업데이트
    int lastIndex = m_positionCount - 1;
    if(lastIndex >= 0)
    {
        m_positions[lastIndex].entryATR = atr;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 포지션 종료                                                        |
//+------------------------------------------------------------------+
bool CPositionManager::ClosePosition(string symbol)
{
    // 해당 심볼의 모든 포지션을 찾아서 종료
    bool result = true;
    
    for(int i = m_positionCount - 1; i >= 0; i--)
    {
        if(m_positions[i].symbol == symbol)
        {
            if(!ExecuteClose(symbol, m_positions[i].ticket))
            {
                Print("포지션 종료 실패: 티켓 #", m_positions[i].ticket);
                result = false;
            }
        }
    }
    
    // 피라미딩 정보 제거
    int pyramidIndex = FindPyramiding(symbol);
    if(pyramidIndex != -1)
    {
        ArrayRemove(m_pyramiding, pyramidIndex, 1);
    }
    
    return result;
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

//+------------------------------------------------------------------+
//| 실제 주문 실행                                                     |
//+------------------------------------------------------------------+
bool CPositionManager::ExecuteOrder(string symbol, int magic, ENUM_POSITION_TYPE type,
                                  double volume, double price, double sl, double tp)
{
    // 매직넘버 설정
    m_trade.SetExpertMagicNumber(magic);
    
    // 주문 실행
    bool result = false;
    if(type == POSITION_TYPE_BUY)
        result = m_trade.Buy(volume, symbol, price, sl, tp);
    else
        result = m_trade.Sell(volume, symbol, price, sl, tp);
        
    if(!result)
    {
        Print("주문 실패: ", GetLastError());
        return false;
    }
    
    // 주문 성공 시 포지션 정보 업데이트
    if(!SyncPositions())
    {
        Print("포지션 동기화 실패");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 실제 포지션 종료                                                   |
//+------------------------------------------------------------------+
bool CPositionManager::ExecuteClose(string symbol, ulong ticket)
{
    // 포지션 종료
    if(!m_trade.PositionClose(ticket))
    {
        Print("포지션 종료 실패: ", GetLastError());
        return false;
    }
    
    // 포지션 정보 업데이트
    if(!SyncPositions())
    {
        Print("포지션 동기화 실패");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 실제 포지션과 동기화                                               |
//+------------------------------------------------------------------+
bool CPositionManager::SyncPositions()
{
    // 기존 포지션 정보 초기화
    ArrayFree(m_positions);
    ArrayFree(m_pyramiding);
    m_positionCount = 0;
    
    // 현재 열린 포지션 수 확인
    int total = PositionsTotal();
    if(total == 0)
        return true;  // 포지션 없음
        
    // 포지션 배열 크기 조정
    ArrayResize(m_positions, total);
    
    // 모든 포지션 정보 수집
    for(int i = 0; i < total; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0)
            continue;
            
        // 포지션 정보 가져오기
        if(!PositionSelectByTicket(ticket))
            continue;
            
        // 포지션 정보 저장
        m_positions[m_positionCount].ticket = ticket;
        m_positions[m_positionCount].symbol = PositionGetString(POSITION_SYMBOL);
        m_positions[m_positionCount].magic = (int)PositionGetInteger(POSITION_MAGIC);
        m_positions[m_positionCount].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        m_positions[m_positionCount].volume = PositionGetDouble(POSITION_VOLUME);
        m_positions[m_positionCount].entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        m_positions[m_positionCount].entryTime = (datetime)PositionGetInteger(POSITION_TIME);
        m_positions[m_positionCount].stopLoss = PositionGetDouble(POSITION_SL);
        m_positions[m_positionCount].takeProfit = PositionGetDouble(POSITION_TP);
        
        // 피라미딩 카운트 업데이트
        string symbol = m_positions[m_positionCount].symbol;
        int pyramidIndex = FindPyramiding(symbol);
        if(pyramidIndex == -1)
        {
            // 새로운 심볼의 피라미딩 정보 추가
            pyramidIndex = ArraySize(m_pyramiding);
            ArrayResize(m_pyramiding, pyramidIndex + 1);
            m_pyramiding[pyramidIndex].symbol = symbol;
            m_pyramiding[pyramidIndex].count = 1;
        }
        else
        {
            // 기존 심볼의 피라미딩 카운트 증가
            m_pyramiding[pyramidIndex].count++;
        }
        
        m_positionCount++;
    }
    
    return true;
}