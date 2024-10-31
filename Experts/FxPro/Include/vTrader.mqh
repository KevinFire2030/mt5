//+------------------------------------------------------------------+
//|                                                       vTrader.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// 필요한 include 파일들
#include <Trade\Trade.mqh>
#include <Arrays\ArrayObj.mqh>

// 매니저 클래스들 전방 선언
class CTurtleMoneyManager;
class CRiskManager;
class CPositionManager;
class CSignalManager;

//+------------------------------------------------------------------+
//| vTrader 메인 클래스                                                |
//+------------------------------------------------------------------+
class CvTrader
{
private:
    // 설정 관련 멤버 변수
    ENUM_TIMEFRAMES    m_timeframe;        // 타임프레임
    double            m_risk;             // 리스크
    int               m_maxPositions;      // 최대 포지션 수
    int               m_maxPyramiding;     // 최대 피라미딩 수
    
    // 매니저 클래스 인스턴스
    CTurtleMoneyManager*   m_moneyManager;    // 자금 관리
    CRiskManager*         m_riskManager;      // 리스크 관리
    CPositionManager*     m_positionManager;  // 포지션 관리
    CSignalManager*       m_signalManager;    // 시그널 관리
    
    // 유틸리티 객체
    CTrade*              m_trade;            // 거래 객체
    
    // 내부 상태 변수
    datetime             m_lastBarTime;       // 마지막 봉 시간
    bool                m_initialized;        // 초기화 상태

public:
    // 생성자/소멸자
                     CvTrader();
                    ~CvTrader();
    
    // 초기화/해제
    bool              Init(ENUM_TIMEFRAMES timeframe, 
                         double risk,
                         int maxPositions,
                         int maxPyramiding);
    void              Deinit();
    
    // 틱 처리
    void              OnTick();
    
private:
    // 내부 유틸리티 함수
    bool              IsNewBar();
    void              ProcessBar();
}; 