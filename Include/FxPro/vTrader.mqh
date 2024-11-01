#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Arrays\ArrayObj.mqh>
#include <Trade\Trade.mqh>

// === 공통 구조체 정의 ===
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

// === 포지션 정보 클래스 ===
class CVPosition {
private:
    ulong m_ticket;
    double m_entryPrice;
    double m_stopLoss;
    double m_takeProfit;
    double m_volume;
    ENUM_POSITION_TYPE m_type;
    datetime m_openTime;
    
public:
    CVPosition() { Clear(); }
    
    void Clear() {
        m_ticket = 0;
        m_entryPrice = 0.0;
        m_stopLoss = 0.0;
        m_takeProfit = 0.0;
        m_volume = 0.0;
        m_type = POSITION_TYPE_BUY;
        m_openTime = 0;
    }
    
    // Getters
    ulong Ticket() const { return m_ticket; }
    double EntryPrice() const { return m_entryPrice; }
    double StopLoss() const { return m_stopLoss; }
    double TakeProfit() const { return m_takeProfit; }
    double Volume() const { return m_volume; }
    ENUM_POSITION_TYPE Type() const { return m_type; }
    datetime OpenTime() const { return m_openTime; }
    
    // Setters
    void Ticket(ulong value) { m_ticket = value; }
    void EntryPrice(double value) { m_entryPrice = value; }
    void StopLoss(double value) { m_stopLoss = value; }
    void TakeProfit(double value) { m_takeProfit = value; }
    void Volume(double value) { m_volume = value; }
    void Type(ENUM_POSITION_TYPE value) { m_type = value; }
    void OpenTime(datetime value) { m_openTime = value; }
};

// === 포지션 관리자 클래스 ===
class CPositionManager {
private:
    const int m_magic;
    CTrade m_trade;
    CVPosition m_positions[];
    
    bool ValidatePosition(const STradeParams &params) {
        if(params.volume <= 0) return false;
        if(params.entryPrice <= 0) return false;
        if(params.stopLoss <= 0) return false;
        return true;
    }
    
    void UpdatePositionInfo() {
        ArrayFree(m_positions);
        
        for(int i = 0; i < PositionsTotal(); i++) {
            if(PositionGetTicket(i) <= 0) continue;
            if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
            
            CVPosition pos;
            pos.Ticket(PositionGetInteger(POSITION_TICKET));
            pos.EntryPrice(PositionGetDouble(POSITION_PRICE_OPEN));
            pos.StopLoss(PositionGetDouble(POSITION_SL));
            pos.TakeProfit(PositionGetDouble(POSITION_TP));
            pos.Volume(PositionGetDouble(POSITION_VOLUME));
            pos.Type((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
            pos.OpenTime((datetime)PositionGetInteger(POSITION_TIME));
            
            int size = ArraySize(m_positions);
            ArrayResize(m_positions, size + 1);
            m_positions[size] = pos;
        }
    }
    
public:
    CPositionManager(int magic): m_magic(magic) {
        m_trade.SetExpertMagicNumber(magic);
        ArrayFree(m_positions);
    }
    
    bool OpenPosition(const STradeParams &params) {
        if(!ValidatePosition(params)) return false;
        
        bool result = false;
        if(params.type == POSITION_TYPE_BUY) {
            result = m_trade.Buy(params.volume, _Symbol, params.entryPrice, 
                params.stopLoss, params.takeProfit);
        }
        else {
            result = m_trade.Sell(params.volume, _Symbol, params.entryPrice, 
                params.stopLoss, params.takeProfit);
        }
        
        if(result) {
            UpdatePositionInfo();
            PrintFormat("포지션 오픈 성공: 가격=%.2f, SL=%.2f, 수량=%.2f",
                params.entryPrice, params.stopLoss, params.volume);
        }
        
        return result;
    }
    
    bool UpdateAllStopLoss() {
        int total = ArraySize(m_positions);
        if(total == 0) return true;
        
        // 가장 높은 스탑로스 찾기
        double highestSL = 0;
        for(int i = 0; i < total; i++) {
            if(m_positions[i].StopLoss() > highestSL) {
                highestSL = m_positions[i].StopLoss();
            }
        }
        
        // 모든 포지션의 스탑로스 수정
        bool allSuccess = true;
        for(int i = 0; i < total; i++) {
            if(m_positions[i].StopLoss() < highestSL) {
                if(!m_trade.PositionModify(m_positions[i].Ticket(), highestSL, m_positions[i].TakeProfit())) {
                    PrintFormat("스탑로스 수정 실패: 티켓=%d, 에러=%d", 
                        m_positions[i].Ticket(), GetLastError());
                    allSuccess = false;
                }
                else {
                    PrintFormat("스탑로스 수정 성공: 티켓=%d, 새로운 SL=%.2f",
                        m_positions[i].Ticket(), highestSL);
                }
            }
        }
        
        return allSuccess;
    }
    
    bool TryPyramiding(const STradeParams &params, int maxPyramid) {
        if(ArraySize(m_positions) >= maxPyramid) {
            Print("피라미딩 한도(", maxPyramid, ")를 초과했습니다");
            return false;
        }
        
        Print("=== 피라미딩 시도 #", ArraySize(m_positions) + 1, " / ", maxPyramid, " ===");
        LogPositions("--- 피라미딩 전 포지션 상태 ---");
        
        Print("--- 피라미딩 파라미터 ---");
        Print("진입가격: ", params.entryPrice);
        Print("스탑로스: ", params.stopLoss);
        Print("거래량: ", params.volume);
        Print("ATR: ", params.atr);
        
        if(!OpenPosition(params)) return false;
        
        // 스탑로스 업데이트
        UpdateAllStopLoss();
        
        LogPositions("--- 피라미딩 후 포지션 상태 ---");
        return true;
    }
    
    int TotalPositions() const { return ArraySize(m_positions); }
    
    void LogPositions(string title = "") {
        if(title != "") Print(title);
        
        // 포지션 정보 업데이트
        UpdatePositionInfo();
        
        for(int i = 0; i < ArraySize(m_positions); i++) {
            PrintFormat("포지션 #%d: 진입가=%.2f, SL=%.2f, 수량=%.2f",
                m_positions[i].Ticket(), 
                m_positions[i].EntryPrice(), 
                m_positions[i].StopLoss(), 
                m_positions[i].Volume());
        }
    }
};

// === 터틀 계산기 클래스 ===
class CTurtleCalculator {
private:
    const string m_symbol;
    const int m_atrPeriod;
    const double m_riskPercent;
    
    double NormalizeVolume(double volume) {
        double minVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double maxVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
        double stepVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
        
        volume = MathRound(volume / stepVolume) * stepVolume;
        volume = MathMax(minVolume, MathMin(maxVolume, volume));
        
        return volume;
    }
    
public:
    CTurtleCalculator(const string symbol, int atrPeriod, double riskPercent)
        : m_symbol(symbol), m_atrPeriod(atrPeriod), m_riskPercent(riskPercent) {}
    
    double GetATR() {
        double atr[];
        ArraySetAsSeries(atr, true);
        
        int handle = iATR(m_symbol, PERIOD_CURRENT, m_atrPeriod);
        if(handle == INVALID_HANDLE) return 0.0;
        
        if(CopyBuffer(handle, 0, 0, 1, atr) <= 0) return 0.0;
        IndicatorRelease(handle);
        
        return atr[0];
    }
        
    double CalculatePosition(double accountBalance) {
        // 테스트를 위해 계좌 잔고 100달러로 고정
        accountBalance = 100.0;
        
        double riskAmount = accountBalance * m_riskPercent / 100.0;
        double atr = GetATR();
        if(atr == 0) return 0.0;
        
        // 계약 단위 가치 계산
        double contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        
        // ATR의 틱 수 계산
        double atrTicks = atr / tickSize;
        
        // 리스크 금액으로부터 거래량 계산
        double rawVolume = riskAmount / (atrTicks * tickValue);
        
        // 마진 요구사항 확인
        double margin = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_INITIAL);
        if(margin > 0) {
            double maxVolumeByMargin = accountBalance / margin;
            rawVolume = MathMin(rawVolume, maxVolumeByMargin);
        }
        
        // 계산 과정 로깅
        Print("=== 거래량 계산 상세 ===");
        Print("계좌 잔고: $", accountBalance);
        Print("리스크 금액: $", riskAmount);
        Print("ATR: ", atr);
        Print("계약 단위: ", contractSize);
        Print("틱 크기: ", tickSize);
        Print("틱 가치: ", tickValue);
        Print("계산된 거래량: ", rawVolume);
        
        // 거래량 정규화
        double finalVolume = NormalizeVolume(rawVolume);
        Print("최종 거래량: ", finalVolume);
        
        return finalVolume;
    }
    
    double GetStopLoss(ENUM_POSITION_TYPE type) {
        double atr = GetATR();
        if(atr == 0) return 0.0;
        
        double price = (type == POSITION_TYPE_BUY) ? 
            SymbolInfoDouble(m_symbol, SYMBOL_ASK) : 
            SymbolInfoDouble(m_symbol, SYMBOL_BID);
            
        return (type == POSITION_TYPE_BUY) ? 
            price - atr * 2.0 : 
            price + atr * 2.0;
    }
};

// === 메인 트레이더 클래스 ===
class CvTrader {
private:
    const string m_symbol;
    const int m_magic;
    const int m_maxPositions;
    const int m_maxPyramid;
    const double m_riskPercent;
    
    CTurtleCalculator* m_calculator;
    CPositionManager* m_positionManager;
    
    bool CalculateTradeParams(STradeParams &params) {
        params.Clear();
        
        params.volume = m_calculator.CalculatePosition(AccountInfoDouble(ACCOUNT_BALANCE));
        if(params.volume <= 0) return false;
        
        params.type = POSITION_TYPE_BUY;  // 현재는 매수만 지원
        params.entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        params.stopLoss = m_calculator.GetStopLoss(params.type);
        params.atr = m_calculator.GetATR();
        
        return true;
    }
    
public:
    CvTrader(const string symbol, int magic, int maxPositions, int maxPyramid, double riskPercent)
        : m_symbol(symbol), m_magic(magic), m_maxPositions(maxPositions),
          m_maxPyramid(maxPyramid), m_riskPercent(riskPercent)
    {
        m_calculator = new CTurtleCalculator(symbol, 20, riskPercent);
        m_positionManager = new CPositionManager(magic);
    }
    
    ~CvTrader() {
        if(m_calculator != NULL) {
            delete m_calculator;
            m_calculator = NULL;
        }
        if(m_positionManager != NULL) {
            delete m_positionManager;
            m_positionManager = NULL;
        }
    }
    
    bool Init() {
        Print("=== vTrader 초기화 ===");
        Print("매직넘버: ", m_magic);
        Print("최대 포지션 수: ", m_maxPositions);
        Print("최대 피라미딩 수: ", m_maxPyramid);
        Print("리스크 비율: ", m_riskPercent, "%");
        return true;
    }
    
    void OnTick() {
        // 현재는 수동 트레이딩만 지원
    }
    
    bool OpenFirstPosition(ENUM_POSITION_TYPE type) {
        STradeParams params;
        if(!CalculateTradeParams(params)) return false;
        
        params.type = type;
        params.entryPrice = (type == POSITION_TYPE_BUY) ? 
            SymbolInfoDouble(m_symbol, SYMBOL_ASK) : 
            SymbolInfoDouble(m_symbol, SYMBOL_BID);
        params.stopLoss = m_calculator.GetStopLoss(type);
        
        Print("=== 첫 번째 포지션 파라미터 ===");
        Print("진입가격: ", params.entryPrice);
        Print("스탑로스: ", params.stopLoss);
        Print("거래량: ", params.volume);
        Print("ATR: ", params.atr);
        
        return m_positionManager.OpenPosition(params);
    }
    
    bool TryPyramiding() {
        STradeParams params;
        if(!CalculateTradeParams(params)) return false;
        
        return m_positionManager.TryPyramiding(params, m_maxPyramid);
    }
};

//+------------------------------------------------------------------+
//| Expert key press function                                          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    // CHARTEVENT_KEYDOWN 이벤트 처리
    if(id == CHARTEVENT_KEYDOWN) {
        // B키: 매수 포지션 열기
        if(lparam == 66) { // 'B' key
            if(g_trader != NULL) g_trader.OpenFirstPosition(POSITION_TYPE_BUY);
        }
        // S키: 매도 포지션 열기
        else if(lparam == 83) { // 'S' key
            if(g_trader != NULL) g_trader.OpenFirstPosition(POSITION_TYPE_SELL);
        }
        // P키: 피라미딩 시도
        else if(lparam == 80) { // 'P' key
            if(g_trader != NULL) g_trader.TryPyramiding();
        }
    }
}