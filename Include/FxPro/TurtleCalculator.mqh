#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

class CTurtleCalculator {
private:
    const double m_riskPercent;
    const int m_atrPeriod;
    const string m_symbol;
    
    double CalculateATR();
    double NormalizeVolume(double volume);
    
public:
    CTurtleCalculator(string symbol, double riskPercent, int atrPeriod = 20):
        m_symbol(symbol),
        m_riskPercent(riskPercent),
        m_atrPeriod(atrPeriod) {}
    
    double GetATR() { return CalculateATR(); }
    double CalculatePosition(double accountBalance);
    double CalculateStopLoss(double entryPrice, double atr, ENUM_POSITION_TYPE type);
};

double CTurtleCalculator::CalculateATR()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    
    int handle = iATR(m_symbol, PERIOD_CURRENT, m_atrPeriod);
    if(handle == INVALID_HANDLE) return 0.0;
    
    if(CopyBuffer(handle, 0, 0, 1, atr) <= 0) return 0.0;
    
    return atr[0];
}

double CTurtleCalculator::CalculatePosition(double accountBalance)
{
    double riskAmount = accountBalance * m_riskPercent / 100.0;
    double atr = GetATR();
    if(atr == 0) return 0.0;
    
    double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double rawVolume = riskAmount / (atr * tickValue);
    
    return NormalizeVolume(rawVolume);
} 