#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <FxPro\Constants.mqh>
#include <FxPro\Types.mqh>
#include <FxPro\Indicators\ATR.mqh>
#include <FxPro\Indicators\EMA.mqh>
#include <FxPro\Trading\Position.mqh>
#include <FxPro\Trading\Risk.mqh>
#include <FxPro\Strategy\Signal.mqh>

//+------------------------------------------------------------------+
//| vTrader 클래스                                                     |
//+------------------------------------------------------------------+
class CvTrader {
private:
    const string m_symbol;
    CSignalManager* m_signal;
    CRiskManager* m_risk;
    CPositionManager* m_position;
    datetime m_lastBarTime;
    bool m_autoTrading;
    
public:
    CvTrader(const string symbol)
        : m_symbol(symbol), m_lastBarTime(0), m_autoTrading(true) {
        m_signal = new CSignalManager(symbol);
        m_risk = new CRiskManager(symbol, RISK_PERCENT);
        m_position = new CPositionManager();
    }
    
    ~CvTrader() {
        if(m_signal != NULL) { delete m_signal; m_signal = NULL; }
        if(m_risk != NULL) { delete m_risk; m_risk = NULL; }
        if(m_position != NULL) { delete m_position; m_position = NULL; }
    }
    
    bool Init() {
        Print("=== vTrader 초기화 ===");
        Print("매직넘버: ", EXPERT_MAGIC);
        Print("최대 포지션 수: ", MAX_POSITIONS);
        Print("최대 피라미딩 수: ", MAX_PYRAMID);
        Print("리스크 비율: ", RISK_PERCENT, "%");
        Print("자동매매 모드: ", (m_autoTrading ? "활성화" : "비활성화"));
        
        // ATR 초기화
        if(!m_risk.Init()) {
            Print("ATR 지표 초기화 실패");
            return false;
        }
        Print("ATR 지표 초기화 성공");
        
        // EMA 시그널 초기화
        Print("=== EMA 시그널 초기화 ===");
        if(!m_signal.Init()) {
            Print("EMA 지표 초기화 실패");
            return false;
        }
        Print("EMA 지표 초기화 성공");
        
        return true;
    }
    
    void OnTick() {
        if(!m_autoTrading) return;
        
        datetime currentBarTime = iTime(m_symbol, PERIOD_CURRENT, 0);
        if(currentBarTime == m_lastBarTime) return;
        
        m_lastBarTime = currentBarTime;
        Print("=== 새로운 봉 생성 ===");
        Print("시간: ", TimeToString(currentBarTime));
        
        // 포지션 상태 체크 (SL 히트 등 확인)
        m_position.CheckPositions();
        
        // 매매 신호 체크
        CheckNewPositions();
    }
    
private:
    bool IsPyramidingAllowed(ENUM_POSITION_TYPE type) {
        if(m_position.TotalPositions() >= MAX_PYRAMID) {
            Print("최대 피라미딩 수 초과: ", m_position.TotalPositions(), "/", MAX_PYRAMID);
            return false;
        }
        
        double lastPrice = m_position.GetLastEntryPrice();
        double atr = m_risk.GetATR();
        double halfN = atr / 2.0;
        
        // N-1의 종가
        double prevClose = iClose(m_symbol, PERIOD_CURRENT, 1);
        
        Print("=== 피라미딩 조건 체크 ===");
        Print("포지션 수: ", m_position.TotalPositions());
        Print("마지막 진입가: ", lastPrice);
        Print("이전 봉 종가: ", prevClose);
        Print("ATR(N): ", atr);
        Print("1/2 N: ", halfN);
        
        if(type == POSITION_TYPE_BUY) {
            // 이전 봉 종가가 마지막 진입가 + 1/2N 보다 높아야 함
            double requiredPrice = lastPrice + halfN;
            if(prevClose <= requiredPrice) {
                Print("매수 피라미딩 불가: 이전 봉 종가(", prevClose, 
                      ") <= 필요가격(", requiredPrice, 
                      ") = 이전진입가(", lastPrice, ") + 1/2N(", halfN, ")");
                return false;
            }
        } else {
            // 이전 봉 종가가 마지막 진입가 - 1/2N 보다 낮아야 함
            double requiredPrice = lastPrice - halfN;
            if(prevClose >= requiredPrice) {
                Print("매도 피라미딩 불가: 이전 봉 종가(", prevClose, 
                      ") >= 필요가격(", requiredPrice, 
                      ") = 이전진입가(", lastPrice, ") - 1/2N(", halfN, ")");
                return false;
            }
        }
        
        Print("피라미딩 조건 충족");
        return true;
    }
    
    void CheckNewPositions() {
        int signal = m_signal.CheckSignal();
        
        // 기존 포지션이 있는 경우
        if(m_position.TotalPositions() > 0) {
            ENUM_POSITION_TYPE existingType = m_position.GetPositionType();
            
            // 청산 조건 체크
            if((existingType == POSITION_TYPE_BUY && signal != 1) ||  // 정배열 이탈
               (existingType == POSITION_TYPE_SELL && signal != -1))  // 역배열 이탈
            {
                Print("=== 청산 시그널 발생 ===");
                m_position.CloseAllPositions();
                return;
            }
            
            // 피라미딩 체크
            ENUM_POSITION_TYPE signalType = (signal > 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
            if(IsPyramidingAllowed(signalType)) {
                Print("=== 피라미딩 진입 시도 ===");
                STradeParams params;
                params.type = signalType;
                
                if(m_risk.CalculateTradeParams(params)) {
                    if(m_position.OpenPosition(params)) {
                        Print("피라미딩 진입 성공");
                    }
                }
            }
            return;
        }
        
        // 신규 포지션 진입
        if(signal != 0) {
            Print("=== 신규 진입 시도 ===");
            STradeParams params;
            params.type = (signal > 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
            
            if(m_risk.CalculateTradeParams(params)) {
                if(m_position.OpenPosition(params)) {
                    Print("신규 진입 성공");
                }
            }
        }
    }
};