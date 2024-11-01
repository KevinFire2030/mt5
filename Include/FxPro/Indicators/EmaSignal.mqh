#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| EMA 시그널 클래스                                                  |
//+------------------------------------------------------------------+
class CEmaSignal {
private:
    const string m_symbol;                // 심볼
    const ENUM_TIMEFRAMES m_timeframe;    // 타임프레임
    int m_emaHandle5;                     // EMA(5) 핸들
    int m_emaHandle20;                    // EMA(20) 핸들
    int m_emaHandle40;                    // EMA(40) 핸들
    
    double m_ema5[];                      // EMA(5) 버퍼
    double m_ema20[];                     // EMA(20) 버퍼
    double m_ema40[];                     // EMA(40) 버퍼
    
public:
    //+------------------------------------------------------------------+
    //| 생성자                                                            |
    //+------------------------------------------------------------------+
    CEmaSignal(const string symbol, ENUM_TIMEFRAMES timeframe)
        : m_symbol(symbol), m_timeframe(timeframe) 
    {
        m_emaHandle5 = INVALID_HANDLE;
        m_emaHandle20 = INVALID_HANDLE;
        m_emaHandle40 = INVALID_HANDLE;
        
        ArraySetAsSeries(m_ema5, true);
        ArraySetAsSeries(m_ema20, true);
        ArraySetAsSeries(m_ema40, true);
    }
    
    //+------------------------------------------------------------------+
    //| 소멸자                                                            |
    //+------------------------------------------------------------------+
    ~CEmaSignal() {
        ReleaseHandles();
    }
    
    //+------------------------------------------------------------------+
    //| 초기화                                                            |
    //+------------------------------------------------------------------+
    bool Init() {
        Print("=== EMA 시그널 초기화 ===");
        
        // EMA 핸들 생성
        m_emaHandle5 = iMA(m_symbol, m_timeframe, 5, 0, MODE_EMA, PRICE_CLOSE);
        m_emaHandle20 = iMA(m_symbol, m_timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_emaHandle40 = iMA(m_symbol, m_timeframe, 40, 0, MODE_EMA, PRICE_CLOSE);
        
        if(m_emaHandle5 == INVALID_HANDLE || 
           m_emaHandle20 == INVALID_HANDLE || 
           m_emaHandle40 == INVALID_HANDLE) {
            Print("EMA 지표 초기화 실패");
            return false;
        }
        
        Print("EMA 지표 초기화 성공");
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| 핸들 해제                                                         |
    //+------------------------------------------------------------------+
    void ReleaseHandles() {
        if(m_emaHandle5 != INVALID_HANDLE) {
            IndicatorRelease(m_emaHandle5);
            m_emaHandle5 = INVALID_HANDLE;
        }
        if(m_emaHandle20 != INVALID_HANDLE) {
            IndicatorRelease(m_emaHandle20);
            m_emaHandle20 = INVALID_HANDLE;
        }
        if(m_emaHandle40 != INVALID_HANDLE) {
            IndicatorRelease(m_emaHandle40);
            m_emaHandle40 = INVALID_HANDLE;
        }
    }
    
    //+------------------------------------------------------------------+
    //| 데이터 업데이트                                                   |
    //+------------------------------------------------------------------+
    bool UpdateData() {
        if(CopyBuffer(m_emaHandle5, 0, 0, 2, m_ema5) <= 0 ||
           CopyBuffer(m_emaHandle20, 0, 0, 2, m_ema20) <= 0 ||
           CopyBuffer(m_emaHandle40, 0, 0, 2, m_ema40) <= 0) {
            Print("EMA 데이터 업데이트 실패: ", GetLastError());
            return false;
        }
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| 정배열 체크 (5 > 20 > 40)                                        |
    //+------------------------------------------------------------------+
    bool IsAligned(int shift = 1) {
        return m_ema5[shift] > m_ema20[shift] && m_ema20[shift] > m_ema40[shift];
    }
    
    //+------------------------------------------------------------------+
    //| 역배열 체크 (5 < 20 < 40)                                        |
    //+------------------------------------------------------------------+
    bool IsReverseAligned(int shift = 1) {
        return m_ema5[shift] < m_ema20[shift] && m_ema20[shift] < m_ema40[shift];
    }
    
    //+------------------------------------------------------------------+
    //| 매매 시그널 체크                                                  |
    //+------------------------------------------------------------------+
    int CheckSignal() {
        if(!UpdateData()) {
            Print("EMA 데이터 업데이트 실패");
            return 0;
        }
        
        Print("=== EMA 데이터 ===");
        Print("EMA5: ", m_ema5[1]);
        Print("EMA20: ", m_ema20[1]);
        Print("EMA40: ", m_ema40[1]);
        
        if(m_ema5[1] > m_ema20[1] && m_ema20[1] > m_ema40[1]) {
            Print("=== 매수 시그널 발생 ===");
            return 1;
        }
        
        if(m_ema5[1] < m_ema20[1] && m_ema20[1] < m_ema40[1]) {
            Print("=== 매도 시그널 발생 ===");
            return -1;
        }
        
        Print("=== 중립 시그널 ===");
        return 0;
    }
    
    //+------------------------------------------------------------------+
    //| 청산 시그널 체크                                                  |
    //+------------------------------------------------------------------+
    bool ShouldClose(ENUM_POSITION_TYPE posType) {
        if(!UpdateData()) return false;
        
        if(posType == POSITION_TYPE_BUY) {
            bool shouldClose = !IsAligned(1);  // 정배열 이탈
            if(shouldClose) {
                Print("=== 롱 포지션 청산 시그널 ===");
                Print("EMA5: ", m_ema5[1]);
                Print("EMA20: ", m_ema20[1]);
                Print("EMA40: ", m_ema40[1]);
            }
            return shouldClose;
        }
        else {
            bool shouldClose = !IsReverseAligned(1);  // 역배열 이탈
            if(shouldClose) {
                Print("=== 숏 포지션 청산 시그널 ===");
                Print("EMA5: ", m_ema5[1]);
                Print("EMA20: ", m_ema20[1]);
                Print("EMA40: ", m_ema40[1]);
            }
            return shouldClose;
        }
    }
}; 