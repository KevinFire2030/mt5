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
//| 에러 코드                                                          |
//+------------------------------------------------------------------+
enum ENUM_POSITION_ERROR
{
    POSITION_ERROR_NONE,              // 에러 없음
    POSITION_ERROR_MAX_POSITIONS,     // 최대 포지션 수 초과
    POSITION_ERROR_MAX_PYRAMIDING,    // 최대 피라미딩 수 초과
    POSITION_ERROR_WRONG_DIRECTION,   // 잘못된 피라미딩 방향
    POSITION_ERROR_INVALID_VOLUME,    // 잘못된 거래량
    POSITION_ERROR_INVALID_PRICE,     // 잘못된 가격
    POSITION_ERROR_INVALID_STOPS,     // 잘못된 SL/TP
    POSITION_ERROR_NO_POSITION,       // 포지션 없음
    POSITION_ERROR_TRADE_DISABLED,    // 트레이딩 비활성화
    POSITION_ERROR_MARKET_CLOSED,     // 마켓 종료
    POSITION_ERROR_TRADE_FAIL,        // 주문 실패
    POSITION_ERROR_SYNC_FAIL          // 동기화 실패
};

//+------------------------------------------------------------------+
//| 포지션 매니저 클래스                                               |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

// 트레이드 에러 코드
#define ERR_TRADE_TIMEOUT        4305    // 요청 시간 초과
#define ERR_TRADE_SERVER_BUSY    4107    // 서버 비지
#define ERR_TRADE_CONNECTION     4526    // 연결 없음

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
    
    ENUM_POSITION_ERROR  m_lastError;        // 마지막 에러 코드
    string              m_lastErrorMsg;      // 마지막 에러 메시지
    
    // 에러 설정
    void               SetError(ENUM_POSITION_ERROR error, string msg = "");
    
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
    
    // 에러 정보
    ENUM_POSITION_ERROR GetLastError() const { return m_lastError; }
    string             GetLastErrorMsg() const { return m_lastErrorMsg; }
    
    // 상태 체크 함수 추가
    bool               IsTradeAllowed(string symbol);
    bool               ValidateVolume(string symbol, double volume);
    bool               ValidateStops(string symbol, double price, double sl, double tp);
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
    // 초기화
    SetError(POSITION_ERROR_NONE);
    
    // 트레이딩 가능 여부 체크
    if(!IsTradeAllowed(symbol))
        return false;
    
    // 최대 포지션 수 체크
    if(!CanOpenPosition())
    {
        SetError(POSITION_ERROR_MAX_POSITIONS, "최대 포지션 수 초과");
        return false;
    }
    
    // 볼륨 유효성 체크
    if(!ValidateVolume(symbol, volume))
    {
        SetError(POSITION_ERROR_INVALID_VOLUME, 
                StringFormat("잘못된 거래량: %.2f", volume));
        return false;
    }
    
    // 피라미딩 체크
    int posIndex = FindPosition(symbol);
    if(posIndex != -1)
    {
        // 최대 피라미딩 체크
        if(!CanAddPyramiding(symbol))
        {
            SetError(POSITION_ERROR_MAX_PYRAMIDING, 
                    StringFormat("최대 피라미딩 횟수 초과: %d", m_maxPyramiding));
            return false;
        }
        
        // 방향 체크
        if(m_positions[posIndex].type != type)
        {
            SetError(POSITION_ERROR_WRONG_DIRECTION, 
                    "기존 포지션과 반대 방향으로 피라미딩 불가");
            return false;
        }
    }
    
    // 현재가 확인
    MqlTick lastTick;
    if(!SymbolInfoTick(symbol, lastTick))
    {
        SetError(POSITION_ERROR_INVALID_PRICE, "가격 정보 조회 실패");
        return false;
    }
    
    // 주문 가격 설정
    double price = (type == POSITION_TYPE_BUY) ? lastTick.ask : lastTick.bid;
    
    // SL/TP 유효성 체크
    if(!ValidateStops(symbol, price, sl, tp))
    {
        SetError(POSITION_ERROR_INVALID_STOPS, "잘못된 SL/TP 설정");
        return false;
    }
    
    // 실제 주문 실행
    if(!ExecuteOrder(symbol, magic, type, volume, price, sl, tp))
    {
        SetError(POSITION_ERROR_TRADE_FAIL, 
                StringFormat("주문 실패: %d", GetLastError()));
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
    
    // 주문 실행 전 재시도 횟수 설정
    int maxTries = 3;
    int tries = 0;
    bool result = false;
    
    while(tries < maxTries)
    {
        // 주문 실행
        if(type == POSITION_TYPE_BUY)
            result = m_trade.Buy(volume, symbol, price, sl, tp);
        else
            result = m_trade.Sell(volume, symbol, price, sl, tp);
            
        if(result)
            break;
            
        // 실패 시 에러 확인
        int error = GetLastError();
        
        // 재시도 가능한 에러인지 확인
        if(error == ERR_TRADE_TIMEOUT || 
           error == ERR_TRADE_SERVER_BUSY || 
           error == ERR_TRADE_CONNECTION)
        {
            tries++;
            Sleep(500);  // 0.5초 대기
            continue;
        }
        
        // 재시도 불가능한 에러
        SetError(POSITION_ERROR_TRADE_FAIL, 
                StringFormat("주문 실패 (에러코드: %d)", error));
        return false;
    }
    
    // 주문 성공 시 포지션 정보 동기화
    if(result)
    {
        if(!SyncPositions())
        {
            SetError(POSITION_ERROR_SYNC_FAIL, "포지션 동기화 실패");
            return false;
        }
    }
    else
    {
        SetError(POSITION_ERROR_TRADE_FAIL, 
                StringFormat("최대 재시도 횟수 초과 (%d회)", maxTries));
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

//+------------------------------------------------------------------+
//| 에러 설정                                                          |
//+------------------------------------------------------------------+
void CPositionManager::SetError(ENUM_POSITION_ERROR error, string msg = "")
{
    m_lastError = error;
    m_lastErrorMsg = msg;
    
    if(error != POSITION_ERROR_NONE)
        Print("포지션 매니저 에러: ", EnumToString(error), ", ", msg);
}

//+------------------------------------------------------------------+
//| 상태 체크 함수 추가                                                |
//+------------------------------------------------------------------+
bool CPositionManager::IsTradeAllowed(string symbol)
{
    // 전역 트레이딩 활성화 여부
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        SetError(POSITION_ERROR_TRADE_DISABLED, "트레이딩이 비활성화됨");
        return false;
    }
    
    // 마켓 상태 체크
    if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
    {
        SetError(POSITION_ERROR_MARKET_CLOSED, "마켓이 종료됨");
        return false;
    }
    
    return true;
}

bool CPositionManager::ValidateVolume(string symbol, double volume)
{
    double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double stepVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // 최소/최대 볼륨 체크
    if(volume < minVol || volume > maxVol)
        return false;
        
    // 볼륨 스텝 체크
    double remainder = MathMod(volume, stepVol);
    if(remainder > 0.0000001)  // 부동소수점 오차 고려
        return false;
        
    return true;
}

//+------------------------------------------------------------------+
//| SL/TP 유효성 체크                                                  |
//+------------------------------------------------------------------+
bool CPositionManager::ValidateStops(string symbol, double price, double sl, double tp)
{
    if(sl == 0 && tp == 0)  // 둘 다 0이면 유효함 (스탑 없음)
        return true;
        
    // 심볼 정보 가져오기
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int stops_level = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double min_distance = stops_level * point;
    
    // 현재가 확인
    MqlTick lastTick;
    if(!SymbolInfoTick(symbol, lastTick))
    {
        SetError(POSITION_ERROR_INVALID_PRICE, "가격 정보 조회 실패");
        return false;
    }
    
    // SL 체크
    if(sl != 0)
    {
        if(price > sl)  // 매수 포지션
        {
            if(price - sl < min_distance)
            {
                SetError(POSITION_ERROR_INVALID_STOPS, 
                        StringFormat("SL이 너무 가까움 (최소 거리: %d 포인트)", stops_level));
                return false;
            }
        }
        else  // 매도 포지션
        {
            if(sl - price < min_distance)
            {
                SetError(POSITION_ERROR_INVALID_STOPS, 
                        StringFormat("SL이 너무 가까움 (최소 거리: %d 포인트)", stops_level));
                return false;
            }
        }
    }
    
    // TP 체크
    if(tp != 0)
    {
        if(price < tp)  // 매수 포지션
        {
            if(tp - price < min_distance)
            {
                SetError(POSITION_ERROR_INVALID_STOPS, 
                        StringFormat("TP가 너무 가까움 (최소 거리: %d 포인트)", stops_level));
                return false;
            }
        }
        else  // 매도 포지션
        {
            if(price - tp < min_distance)
            {
                SetError(POSITION_ERROR_INVALID_STOPS, 
                        StringFormat("TP가 너무 가까움 (최소 거리: %d 포인트)", stops_level));
                return false;
            }
        }
    }
    
    return true;
}