#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Arrays\ArrayObj.mqh>
#include <Trade\Trade.mqh>
#include "TradeTypes.mqh"

class CPositionManager {
private:
    const int m_magic;
    CTrade m_trade;
    CArrayObj m_positions;  // SPositionInfo 객체들을 저장
    
    bool ValidatePosition(const STradeParams &params);
    void UpdatePositionInfo();
    
public:
    CPositionManager(int magic): m_magic(magic) {
        m_trade.SetExpertMagicNumber(magic);
    }
    
    ~CPositionManager() { 
        m_positions.Clear(); 
    }
    
    // === 포지션 관리 ===
    bool OpenPosition(const STradeParams &params);
    bool ModifyAllStopLoss(double newSL);
    bool CloseAllPositions();
    
    // === 포지션 정보 ===
    int TotalPositions() const { return m_positions.Total(); }
    double GetAverageEntry() const;
    double GetTotalVolume() const;
    double GetMinStopLoss() const;
    
    // === 로깅 ===
    void LogPositions(string title = "") const;
};

// === 구현부 ===
bool CPositionManager::OpenPosition(const STradeParams &params)
{
    if(!ValidatePosition(params)) return false;
    
    bool result = m_trade.PositionOpen(
        _Symbol,
        params.type,
        params.volume,
        params.entryPrice,
        params.stopLoss,
        params.takeProfit
    );
    
    if(result) {
        UpdatePositionInfo();
        PrintFormat("포지션 오픈 성공: 가격=%.2f, SL=%.2f, 수량=%.2f",
            params.entryPrice, params.stopLoss, params.volume);
    }
    
    return result;
}

bool CPositionManager::ModifyAllStopLoss(double newSL)
{
    bool allSuccess = true;
    
    for(int i = 0; i < m_positions.Total(); i++) {
        SPositionInfo* pos = m_positions.At(i);
        if(!m_trade.PositionModify(pos.ticket, newSL, pos.takeProfit)) {
            PrintFormat("스탑로스 수정 실패: 티켓=%d, 에러=%d", 
                pos.ticket, GetLastError());
            allSuccess = false;
        }
        else {
            PrintFormat("스탑로스 수정 성공: 티켓=%d, 새로운 SL=%.2f",
                pos.ticket, newSL);
        }
    }
    
    return allSuccess;
}

void CPositionManager::LogPositions(string title = "") const
{
    if(title != "") Print(title);
    
    for(int i = 0; i < m_positions.Total(); i++) {
        SPositionInfo* pos = m_positions.At(i);
        PrintFormat("포지션 #%d: 진입가=%.2f, SL=%.2f, 수량=%.2f",
            pos.ticket, pos.entryPrice, pos.stopLoss, pos.volume);
    }
}