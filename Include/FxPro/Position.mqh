#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| 트레이드 파라미터 구조체                                           |
//+------------------------------------------------------------------+
struct STradeParams {
    ENUM_POSITION_TYPE type;    // 포지션 타입
    double volume;              // 거래량
    double sl;                  // 스탑로스
    double tp;                  // 테이크프로핏
};

//+------------------------------------------------------------------+
//| 포지션 클래스                                                      |
//+------------------------------------------------------------------+
class CVPosition {
private:
    ulong m_ticket;            // 티켓 번호
    ENUM_POSITION_TYPE m_type; // 포지션 타입
    double m_volume;           // 거래량
    double m_entryPrice;       // 진입가
    double m_sl;              // 스탑로스
    double m_tp;              // 테이크프로핏
    
public:
    CVPosition() : m_ticket(0), m_type(POSITION_TYPE_BUY), 
                  m_volume(0.0), m_entryPrice(0.0), 
                  m_sl(0.0), m_tp(0.0) {}
                  
    CVPosition(ulong ticket, ENUM_POSITION_TYPE type, double volume, 
               double entryPrice, double sl = 0.0, double tp = 0.0)
        : m_ticket(ticket), m_type(type), m_volume(volume),
          m_entryPrice(entryPrice), m_sl(sl), m_tp(tp) {}
          
    ulong Ticket() const { return m_ticket; }
    ENUM_POSITION_TYPE Type() const { return m_type; }
    double Volume() const { return m_volume; }
    double EntryPrice() const { return m_entryPrice; }
    double StopLoss() const { return m_sl; }
    double TakeProfit() const { return m_tp; }
    
    void SetStopLoss(double sl) { m_sl = sl; }
    void SetTakeProfit(double tp) { m_tp = tp; }
    
    void UpdateStopLoss(double newSL) {
        m_sl = newSL;
        Print("포지션 ", m_ticket, " SL 업데이트: ", newSL);
    }
    
    void UpdateTakeProfit(double newTP) {
        m_tp = newTP;
        Print("포지션 ", m_ticket, " TP 업데이트: ", newTP);
    }
};

//+------------------------------------------------------------------+
//| 포지션 관리자 클래스                                              |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    CTrade m_trade;           
    CVPosition m_positions[]; 
    MqlTick m_lastTick;      
    
public:
    CPositionManager(int magic) {
        m_trade.SetExpertMagicNumber(magic);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(Symbol());
        m_trade.SetDeviationInPoints(10);  // 슬리피지 허용
        ArrayResize(m_positions, 0);
    }
    
    int TotalPositions() const {
        return ArraySize(m_positions);
    }
    
    CVPosition* GetPosition(int index) {
        if(index < 0 || index >= ArraySize(m_positions)) return NULL;
        return GetPointer(m_positions[index]);
    }
    
    CVPosition* GetLastPosition() {
        int total = ArraySize(m_positions);
        if(total == 0) return NULL;
        return GetPointer(m_positions[total - 1]);
    }
    
    bool OpenPosition(STradeParams &params) {
        // 심볼 정보 확인
        if(!SymbolInfoTick(Symbol(), m_lastTick)) {
            Print("틱 데이터 가져오기 실패: ", GetLastError());
            return false;
        }
        
        // 진입가격 설정
        double price = (params.type == POSITION_TYPE_BUY) ? 
            m_lastTick.ask : m_lastTick.bid;
            
        // ORDER_TYPE으로 변환
        ENUM_ORDER_TYPE orderType = (params.type == POSITION_TYPE_BUY) ? 
            ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            
        Print("=== 포지션 진입 시도 ===");
        Print("심볼: ", Symbol());
        Print("타입: ", EnumToString(orderType));
        Print("가격: ", price);
        Print("거래량: ", params.volume);
        Print("SL: ", params.sl);
        
        // 거래량 정규화
        double minVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
        double maxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
        double stepVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
        
        params.volume = MathMin(maxVolume, 
                        MathMax(minVolume, 
                        NormalizeDouble(params.volume/stepVolume, 0) * stepVolume));
        
        Print("정규화된 거래량: ", params.volume);
        
        // 스탑로스 정규화
        int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
        params.sl = NormalizeDouble(params.sl, digits);
        
        // 실제 주문 실행
        if(!m_trade.PositionOpen(Symbol(), orderType, params.volume, price, params.sl, 0)) {
            Print("포지션 진입 실패");
            return false;
        }
        
        // 새 포지션 추가
        int total = ArraySize(m_positions);
        ArrayResize(m_positions, total + 1);
        m_positions[total] = CVPosition(m_trade.ResultOrder(), params.type, params.volume, 
                                      m_trade.ResultPrice(), params.sl, 0);
                                      
        // 모든 포지션의 스탑로스 동기화
        SynchronizeStopLoss(params.sl);
        
        Print("포지션 진입 성공");
        return true;
    }
    
    bool ClosePosition(ulong ticket) {
        return m_trade.PositionClose(ticket);
    }
    
    bool TryPyramiding(STradeParams &params, int maxPyramid) {
        if(TotalPositions() >= maxPyramid) return false;
        return OpenPosition(params);
    }
    
    void UpdatePositionInfo() {
        // 포지션 정보 업데이트 로직
    }
    
private:
    void SynchronizeStopLoss(double newSL) {
        for(int i = 0; i < ArraySize(m_positions); i++) {
            ulong ticket = m_positions[i].Ticket();
            if(!m_trade.PositionModify(ticket, newSL, 0)) {
                Print("스탑로스 수정 실패 - 티켓: ", ticket, ", 에러: ", GetLastError());
            } else {
                Print("스탑로스 수정 성공 - 티켓: ", ticket, ", 새 SL: ", newSL);
                m_positions[i].UpdateStopLoss(newSL);
            }
        }
    }
}; 