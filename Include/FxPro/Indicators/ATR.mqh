class CATR {
private:
    const string m_symbol;
    const ENUM_TIMEFRAMES m_timeframe;
    const int m_period;
    int m_handle;
    double m_buffer[];
    
public:
    CATR(const string symbol, const ENUM_TIMEFRAMES timeframe, const int period)
        : m_symbol(symbol), m_timeframe(timeframe), m_period(period) {
        m_handle = INVALID_HANDLE;
        ArraySetAsSeries(m_buffer, true);
    }
    
    ~CATR() { Release(); }
    
    bool Init() {
        Release();
        m_handle = iATR(m_symbol, m_timeframe, m_period);
        return m_handle != INVALID_HANDLE;
    }
    
    void Release() {
        if(m_handle != INVALID_HANDLE) {
            IndicatorRelease(m_handle);
            m_handle = INVALID_HANDLE;
        }
    }
    
    double GetValue(const int shift = 0) {
        if(m_handle == INVALID_HANDLE) return 0.0;
        if(CopyBuffer(m_handle, 0, shift, 1, m_buffer) <= 0) return 0.0;
        return m_buffer[0];
    }
}; 