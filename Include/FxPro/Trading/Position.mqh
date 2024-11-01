#include <Trade/Trade.mqh>
#include <Arrays/ArrayObj.mqh>
#include "../Constants.mqh"
#include "../Types.mqh"

class CPositionManager {
private:
    CTrade* m_trade;
    CArrayObj* m_positions;
    
    // 포지션 배열 정리 (청산된 포지션 제거)
    void CleanPositions() {
        for(int i = m_positions.Total() - 1; i >= 0; i--) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL) {
                // 포지션이 실제로 존재하는지 확인
                if(!PositionSelectByTicket(pos.ticket)) {
                    Print("포지션 자동 청산 감지 - 티켓: ", pos.ticket);
                    m_positions.Delete(i);
                }
            }
        }
    }
    
public:
    CPositionManager() {
        m_trade = new CTrade();
        m_positions = new CArrayObj();
        
        m_trade.SetExpertMagicNumber(EXPERT_MAGIC);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(Symbol());
        m_trade.SetDeviationInPoints(10);
    }
    
    ~CPositionManager() {
        if(m_trade != NULL) {
            delete m_trade;
            m_trade = NULL;
        }
        if(m_positions != NULL) {
            m_positions.Clear();
            delete m_positions;
            m_positions = NULL;
        }
    }
    
    bool OpenPosition(const STradeParams &params) {
        if(TotalPositions() >= MAX_POSITIONS) {
            Print("최대 포지션 수 초과");
            return false;
        }
        
        double price = (params.type == POSITION_TYPE_BUY) ? 
            SymbolInfoDouble(Symbol(), SYMBOL_ASK) : 
            SymbolInfoDouble(Symbol(), SYMBOL_BID);
            
        ENUM_ORDER_TYPE orderType = (params.type == POSITION_TYPE_BUY) ? 
            ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            
        Print("=== 포지션 진입 시도 ===");
        Print("심볼: ", Symbol());
        Print("타입: ", EnumToString(orderType));
        Print("가격: ", price);
        Print("거래량: ", params.volume);
        Print("SL: ", params.sl);
        
        if(!m_trade.PositionOpen(Symbol(), orderType, params.volume, price, params.sl, params.tp)) {
            Print("포지션 진입 실패: ", GetLastError());
            return false;
        }
        
        CPosition* pos = new CPosition();
        if(pos != NULL) {
            pos.ticket = m_trade.ResultOrder();
            pos.type = params.type;
            pos.volume = params.volume;
            pos.price = m_trade.ResultPrice();
            pos.sl = params.sl;
            pos.tp = params.tp;
            pos.openTime = TimeCurrent();
            
            m_positions.Add(pos);
            
            Print("포지션 진입 성공");
            Print("주문번호: ", pos.ticket);
            Print("실행가격: ", pos.price);
            
            SynchronizeStopLoss(params.sl);
        }
        
        return true;
    }
    
    void SynchronizeStopLoss(const double newSL) {
        for(int i = 0; i < m_positions.Total(); i++) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL) {
                if(PositionSelectByTicket(pos.ticket)) {
                    double currentSL = PositionGetDouble(POSITION_SL);
                    if(MathAbs(currentSL - newSL) > SymbolInfoDouble(Symbol(), SYMBOL_POINT)) {
                        if(!m_trade.PositionModify(pos.ticket, newSL, 0)) {
                            Print("스탑로스 수정 실패 - 티켓: ", pos.ticket, 
                                  ", 에러: ", GetLastError(),
                                  ", 현재SL: ", currentSL,
                                  ", 새SL: ", newSL);
                        } else {
                            Print("스탑로스 수정 성공 - 티켓: ", pos.ticket, 
                                  ", 이전SL: ", currentSL,
                                  ", 새SL: ", newSL);
                            pos.sl = newSL;
                        }
                    }
                }
            }
        }
    }
    
    void CloseAllPositions() {
        Print("=== 전체 포지션 청산 시도 ===");
        
        for(int i = m_positions.Total() - 1; i >= 0; i--) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL) {
                if(m_trade.PositionClose(pos.ticket)) {
                    Print("포지션 청산 성공 - 티켓: ", pos.ticket);
                    m_positions.Delete(i);
                } else {
                    Print("포지션 청산 실패 - 티켓: ", pos.ticket, ", 에러: ", GetLastError());
                }
            }
        }
        
        // 배열 정리
        m_positions.Clear();
    }
    
    double GetLastEntryPrice() const {
        // 먼저 포지션 정리
        ((CPositionManager*)GetPointer(this)).CleanPositions();  // const 우회
        
        if(m_positions.Total() == 0) return 0.0;
        
        CPosition* pos = m_positions.At(m_positions.Total() - 1);
        if(pos == NULL) return 0.0;
        
        Print("마지막 포지션 정보 - 티켓: ", pos.ticket, ", 가격: ", pos.price);
        return pos.price;
    }
    
    int TotalPositions() const {
        // 먼저 포지션 정리
        ((CPositionManager*)GetPointer(this)).CleanPositions();  // const 우회
        
        return m_positions.Total();
    }
    
    ENUM_POSITION_TYPE GetPositionType() const {
        // 먼저 포지션 정리
        ((CPositionManager*)GetPointer(this)).CleanPositions();  // const 우회
        
        if(m_positions.Total() == 0) return POSITION_TYPE_BUY;  // 기본값
        
        CPosition* pos = m_positions.At(0);
        return (pos != NULL) ? pos.type : POSITION_TYPE_BUY;
    }
    
    // OnTick에서 호출될 메서드
    void CheckPositions() {
        if(m_positions.Total() == 0) return;
        
        Print("=== 포지션 상태 체크 ===");
        Print("현재 포지션 수: ", m_positions.Total());
        
        // 청산된 포지션 정리
        CleanPositions();
        
        Print("정리 후 포지션 수: ", m_positions.Total());
    }
}; 