#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| ATR 기반 계산기 클래스                                            |
//+------------------------------------------------------------------+
class CTurtleCalculator {
private:
    const string m_symbol;
    const int m_period;
    const double m_riskPercent;
    int m_atrHandle;
    double m_atr[];
    
public:
    CTurtleCalculator(const string symbol, int period, double riskPercent)
        : m_symbol(symbol), m_period(period), m_riskPercent(riskPercent) {
        m_atrHandle = INVALID_HANDLE;
        ArraySetAsSeries(m_atr, true);
    }
    
    ~CTurtleCalculator() {
        ReleaseHandle();
    }
    
    void ReleaseHandle() {
        if(m_atrHandle != INVALID_HANDLE) {
            IndicatorRelease(m_atrHandle);
            m_atrHandle = INVALID_HANDLE;
        }
    }
    
    bool Init() {
        ReleaseHandle();
        m_atrHandle = iATR(m_symbol, PERIOD_CURRENT, m_period);
        
        if(m_atrHandle == INVALID_HANDLE) {
            Print("ATR 지표 생성 실패: ", GetLastError());
            return false;
        }
        
        Print("ATR 지표 초기화 성공");
        return true;
    }
    
    double GetATR() {
        if(m_atrHandle == INVALID_HANDLE) {
            Print("ATR 핸들이 유효하지 않음");
            return 0.0;
        }
        
        if(CopyBuffer(m_atrHandle, 0, 1, 1, m_atr) <= 0) {
            Print("ATR 데이터 복사 실패: ", GetLastError());
            return 0.0;
        }
        
        return m_atr[0];
    }
    
    bool CalculateTradeParams(STradeParams &params) {
        double atr = GetATR();
        if(atr == 0.0) return false;
        
        // 테스트용 고정 계좌 잔고
        double accountBalance = 100.0;  // 테스트용 $100 고정
        double riskAmount = accountBalance * m_riskPercent / 100.0;  // 1% = $1
        
        // 포인트 가치와 틱 사이즈 가져오기
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        
        // ATR을 틱 단위로 변환
        double atrInTicks = atr / tickSize;
        
        // 1 로트당 리스크 계산
        double riskPerLot = atrInTicks * tickValue;
        
        // 거래량 계산
        params.volume = NormalizeDouble(riskAmount / riskPerLot, 2);
        params.volume = MathMax(params.volume, minLot);
        
        Print("=== 거래량 계산 상세 ===");
        Print("Tick Size: ", tickSize);
        Print("Tick Value: ", tickValue);
        Print("ATR in Ticks: ", atrInTicks);
        Print("Risk per Lot: ", riskPerLot);
        
        return true;
    }
}; 
