#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// === 공통 상수 및 구조체 정의 ===
struct STradeParams {
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double volume;
    double atr;
    ENUM_POSITION_TYPE type;
    
    void Clear() {
        entryPrice = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        volume = 0.0;
        atr = 0.0;
        type = POSITION_TYPE_BUY;
    }
};

struct SPositionInfo {
    ulong ticket;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double volume;
    ENUM_POSITION_TYPE type;
    datetime openTime;
    
    void Clear() {
        ticket = 0;
        entryPrice = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        volume = 0.0;
        type = POSITION_TYPE_BUY;
        openTime = 0;
    }
}; 