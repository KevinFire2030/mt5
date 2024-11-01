class CRiskManager {
private:
    const string m_symbol;
    const double m_riskPercent;
    CATR* m_atr;
    
public:
    CRiskManager(const string symbol, const double riskPercent)
        : m_symbol(symbol), m_riskPercent(riskPercent) {
        m_atr = new CATR(symbol, PERIOD_CURRENT, 20);
    }
    
    ~CRiskManager() {
        if(m_atr != NULL) {
            delete m_atr;
            m_atr = NULL;
        }
    }
    
    bool Init() {
        return m_atr.Init();
    }
    
    bool CalculateTradeParams(STradeParams &params) {
        double atr = m_atr.GetValue();
        if(atr == 0.0) return false;
        
        Print("=== 거래 파라미터 계산 ===");
        Print("ATR: ", atr);
        
        // 계좌 설정
        double accountBalance = TEST_BALANCE;  // $100 테스트용
        double riskAmount = accountBalance * m_riskPercent / 100.0;  // 1% = $1
        
        // 포인트당 가치 계산
        double pointValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE) * 
                           (SymbolInfoDouble(m_symbol, SYMBOL_POINT) / 
                            SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE));
                            
        // 스탑로스 포인트 계산
        double stopLossPoints = atr / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        
        // 거래량 계산
        double volumeRaw = (riskAmount / (stopLossPoints * pointValue));
        params.volume = NormalizeDouble(volumeRaw, 2);
        
        // 최소/최대 거래량 제한
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
        params.volume = MathMax(minLot, MathMin(maxLot, params.volume));
        
        // 스탑로스 계산
        if(params.type == POSITION_TYPE_BUY) {
            params.sl = SymbolInfoDouble(m_symbol, SYMBOL_BID) - atr;
        } else {
            params.sl = SymbolInfoDouble(m_symbol, SYMBOL_ASK) + atr;
        }
        
        Print("=== 거래 파라미터 ===");
        Print("계좌잔고(테스트용): $", accountBalance);
        Print("리스크금액: $", riskAmount);
        Print("ATR: ", atr);
        Print("Point Value: ", pointValue);
        Print("Stop Loss Points: ", stopLossPoints);
        Print("Raw Volume: ", volumeRaw);
        Print("Final Volume: ", params.volume);
        Print("SL: ", params.sl);
        
        return true;
    }
    
    double GetATR() const {
        return m_atr.GetValue();
    }
}; 