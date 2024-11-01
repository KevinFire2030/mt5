class CSignalManager {
private:
    const string m_symbol;
    CEMA* m_ema5;
    CEMA* m_ema20;
    CEMA* m_ema40;
    
public:
    CSignalManager(const string symbol)
        : m_symbol(symbol) {
        m_ema5 = new CEMA(symbol, PERIOD_CURRENT, 5);
        m_ema20 = new CEMA(symbol, PERIOD_CURRENT, 20);
        m_ema40 = new CEMA(symbol, PERIOD_CURRENT, 40);
    }
    
    ~CSignalManager() {
        if(m_ema5 != NULL) { delete m_ema5; m_ema5 = NULL; }
        if(m_ema20 != NULL) { delete m_ema20; m_ema20 = NULL; }
        if(m_ema40 != NULL) { delete m_ema40; m_ema40 = NULL; }
    }
    
    bool Init() {
        return m_ema5.Init() && m_ema20.Init() && m_ema40.Init();
    }
    
    int CheckSignal() {
        double ema5_curr = m_ema5.GetValue(0);
        double ema20_curr = m_ema20.GetValue(0);
        double ema40_curr = m_ema40.GetValue(0);
        
        Print("=== EMA 데이터 ===");
        Print("EMA5: ", ema5_curr);
        Print("EMA20: ", ema20_curr);
        Print("EMA40: ", ema40_curr);
        
        // 정배열 체크 (5 > 20 > 40)
        bool isAligned = (ema5_curr > ema20_curr && ema20_curr > ema40_curr);
        
        // 역배열 체크 (5 < 20 < 40)
        bool isReverseAligned = (ema5_curr < ema20_curr && ema20_curr < ema40_curr);
        
        if(isAligned) {
            Print("=== EMA 정배열 ===");
            return 1;  // 매수 시그널
        }
        
        if(isReverseAligned) {
            Print("=== EMA 역배열 ===");
            return -1;  // 매도 시그널
        }
        
        Print("=== EMA 중립 ===");
        return 0;  // 중립
    }
}; 