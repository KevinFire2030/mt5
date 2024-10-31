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
    POSITION_ERROR_NONE,              // 에 없음
    POSITION_ERROR_TRADE_NOT_ALLOWED, // 트레이딩 불가
    POSITION_ERROR_TRADE_DISABLED,    // 트레이딩 비활성화
    POSITION_ERROR_MARKET_CLOSED,     // 마켓 종료
    POSITION_ERROR_MAX_POSITIONS,     // 최대 포지션 수 초과
    POSITION_ERROR_MAX_PYRAMIDING,    // 최대 피라미딩 수 초과
    POSITION_ERROR_INVALID_VOLUME,    // 잘못된 거래량
    POSITION_ERROR_INVALID_PRICE,     // 잘못된 가격
    POSITION_ERROR_INVALID_STOPS,     // 잘못된 손절/이익실현
    POSITION_ERROR_TRADE_FAIL,        // 주문 실패
    POSITION_ERROR_WRONG_DIRECTION,   // 잘못된 방향
    POSITION_ERROR_UNIT_CALC_FAIL,    // 유닛 계산 실패
    POSITION_ERROR_SYNC_FAIL          // 동기화 실패
};

//+------------------------------------------------------------------+
//| 터틀 유닛 계산을 위한 구조체                                       |
//+------------------------------------------------------------------+
struct STurtleUnitSettings
{
    double riskPercent;        // 리스크 비율 (기본 1%)
    int    atrPeriod;         // ATR 기간 (기본 20일)
    double minLot;            // 최소 거래 단위 (기본 0.01)
    
    STurtleUnitSettings()
    {
        riskPercent = 1.0;    // 1%
        atrPeriod = 20;       // 20일
        minLot = 0.01;        // 0.01랏
    }
};

//+------------------------------------------------------------------+
//| 포지션 매니저 클래스                                               |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

// 트레이드 에러 코드
#define ERR_TRADE_TIMEOUT        4305    // 요청 시간 초과
#define ERR_TRADE_SERVER_BUSY    4107    // 서버 비지
#define ERR_TRADE_CONNECTION     4526    // 연결 없음

class CPositionManager : public CTrade
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
    CTrade            m_trade;            // 트레드 객체
    
    // 헬퍼 함��
    int               FindPosition(string symbol);  // 심볼로 포지션 찾기
    bool              CanAddPyramiding(string symbol);  // 피라미딩 가능 여부
    int               FindPyramiding(string symbol);  // 심볼의 피라미딩 정보 찾기
    bool              SyncPositions();    // 실제 포지션과 동기화
    
    ENUM_POSITION_ERROR  m_lastError;        // 마지막 에러 코드
    string              m_lastErrorMsg;      // 마지막 에러 메시지
    string           m_lastErrorString;    // 마지막 에러 메시지
    
    // 에러 설정
    void               SetError(ENUM_POSITION_ERROR error, string msg = "");
    
    STurtleUnitSettings m_turtleSettings;   // 터틀 설정
    
    // 유닛 계산 함수
    double            CalculateTurtleUnit(string symbol, double atr);
    double            GetSymbolPointValue(string symbol);
    double            NormalizeLot(string symbol, double lot);
    
    // ATR 기반 스탑로스 계산
    double            CalculateStopLoss(string symbol, ENUM_POSITION_TYPE type, 
                                     double entryPrice, double atr);
    
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
                                double volume, double price, double atr);
    bool             ExecuteClose(string symbol, ulong ticket);
    
    // 에러 정보
    ENUM_POSITION_ERROR GetLastError() const { return m_lastError; }
    string             GetLastErrorMsg() const { return m_lastErrorMsg; }
    string          GetLastErrorString() const { return m_lastErrorString; }
    
    // 상태 체크 함수 추가
    bool               IsTradeAllowed(string symbol);
    bool               ValidateVolume(string symbol, double volume);
    bool               ValidateStops(string symbol, double price, double sl, double tp);
    
    // 터틀 설정
    void             SetTurtleSettings(const STurtleUnitSettings &settings) { m_turtleSettings = settings; }
    void             GetTurtleSettings(STurtleUnitSettings &settings) const { settings = m_turtleSettings; }
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
    SetError(POSITION_ERROR_NONE, "");
    
    // 트레이딩 가능 여부 체크
    if(!IsTradeAllowed(symbol))
    {
        SetError(POSITION_ERROR_TRADE_NOT_ALLOWED, "트레이딩이 허용되지 않음");
        return false;
    }
    
    // 최대 포지션 수 체크
    if(!CanOpenPosition())
    {
        SetError(POSITION_ERROR_MAX_POSITIONS, "최대 포지션 수 과");
        return false;
    }
    
    // 터틀 유닛 계산 (volume 파라미터 무시)
    double turtleVolume = CalculateTurtleUnit(symbol, atr);  // 여기서 호출
    Print("\n=== 터틀 유닛 계산 결과 ===");
    Print("계산된 거래량: ", turtleVolume);
    Print("========================\n");
    
    if(turtleVolume <= 0)
    {
        SetError(POSITION_ERROR_INVALID_VOLUME, 
                StringFormat("유닛 계산 실패: %.2f", turtleVolume));
        return false;
    }
    
    // 실제 주문 실행
    MqlTick lastTick;
    SymbolInfoTick(symbol, lastTick);
    double price = (type == POSITION_TYPE_BUY) ? lastTick.ask : lastTick.bid;
    
    if(!ExecuteOrder(symbol, magic, type, turtleVolume, price, atr))
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
bool CPositionManager::ExecuteOrder(string symbol, int magic, 
                                  ENUM_POSITION_TYPE type,
                                  double volume, double price, double atr)
{
    // 스탑로스 계산
    double stopLoss = CalculateStopLoss(symbol, type, price, atr);
    
    // POSITION_TYPE을 ORDER_TYPE으로 변환
    ENUM_ORDER_TYPE orderType = (type == POSITION_TYPE_BUY) ? 
                               ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    // 주문 실행
    if(!m_trade.PositionOpen(symbol, orderType, volume, price, stopLoss, 0))
    {
        SetError(POSITION_ERROR_TRADE_FAIL, 
                StringFormat("포지션 오픈 실패 (에러코드: %d)", GetLastError()));
        return false;
    }
    
    // 피라미딩 정보 확인
    int pyramidIndex = FindPyramiding(symbol);
    if(pyramidIndex != -1 && m_pyramiding[pyramidIndex].count > 0)
    {
        // 기존 포지션들의 SL 업데이트
        for(int i = 0; i < m_positionCount; i++)
        {
            if(m_positions[i].type == type)
            {
                if(!m_trade.PositionModify(m_positions[i].ticket, stopLoss, 0))
                {
                    Print("기존 포지션 SL 수정 실패: 티켓 #", m_positions[i].ticket);
                }
            }
        }
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
    m_lastErrorString = msg;
    
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
        SetError(POSITION_ERROR_TRADE_DISABLED, "트레이딩 비활성화됨");
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

//+------------------------------------------------------------------+
//| 1유닛 계산                                                         |
//+------------------------------------------------------------------+
double CPositionManager::CalculateTurtleUnit(string symbol, double atr)
{
    // 테스트용 고정 계좌 잔고 ($100)
    double equity = 100.0;
    
    // 심볼 정보 가져오기
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    
    // N(ATR) 달러 변동폭 계산
    double dollarVolatility = (atr / tickSize) * tickValue;
    
    // 1유닛 계산
    double riskAmount = equity * m_turtleSettings.riskPercent / 100.0;  // $1
    double unitSize = riskAmount / dollarVolatility;
    
    // 상세 계산 과정 출력
    Print("\n=== 터틀 유닛 상세 계산 ===");
    Print("심볼: ", symbol);
    Print("계좌 잔고: $", equity);
    Print("리스크 비율: ", m_turtleSettings.riskPercent, "%");
    Print("리스크 금액: $", riskAmount);
    Print("ATR: ", atr);
    Print("틱 가치: $", tickValue);
    Print("틱 크기: ", tickSize);
    Print("최소 거래량: ", minLot);
    Print("N 달러 변동폭: $", dollarVolatility);
    Print("Raw 유닛 크기: ", unitSize);
    
    // 최소 거래 단위로 정규화
    double normalizedLot = NormalizeLot(symbol, unitSize);
    Print("정규화된 유닛 크기: ", normalizedLot);
    Print("========================\n");
    
    return normalizedLot;
}

//+------------------------------------------------------------------+
//| 거래량 정규화                                                      |
//+------------------------------------------------------------------+
double CPositionManager::NormalizeLot(string symbol, double lot)
{
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // 최소 거래량으로 반올림
    lot = MathMax(minLot, MathFloor(lot / minLot) * minLot);
    
    // 최대 거래량 제한
    lot = MathMin(lot, maxLot);
    
    // 스텝 단위로 반올림
    return MathFloor(lot / stepLot) * stepLot;
}

//+------------------------------------------------------------------+
//| ATR 기반 스탑로스 계산                                             |
//+------------------------------------------------------------------+
double CPositionManager::CalculateStopLoss(string symbol, ENUM_POSITION_TYPE type, 
                                         double entryPrice, double atr)
{
    double stopLoss = 0;
    double twoN = atr * 2;  // 2N
    
    if(type == POSITION_TYPE_BUY)
        stopLoss = entryPrice - twoN;
    else
        stopLoss = entryPrice + twoN;
        
    return NormalizeDouble(stopLoss, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
}