#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.1"

#include <Arrays\ArrayObj.mqh>
#include <Trade\Trade.mqh>

// 상수 정의
#define RISK_PERCENT    1.0     // 리스크 비율 1%
#define MAX_POSITIONS   5       // 최대 포지션 수
#define MAX_PYRAMID     4       // 최대 피라미딩 수
#define TEST_BALANCE    100.0   // 테스트용 계좌 잔고

// 포지션 클래스 (구조체 대신 클래스 사용)
class CPosition : public CObject {
public:
    ulong ticket;              // 포지션 티켓
    ENUM_POSITION_TYPE type;   // 포지션 타입
    double price;             // 진입 가격
    double volume;            // 수량
    double sl;               // 스탑로스
    
    // 생성자
    CPosition(void) : ticket(0), type(POSITION_TYPE_BUY), 
                     price(0.0), volume(0.0), sl(0.0) {}
};

class CvTrader {
private:
    // 멤버 변수
    string m_symbol;          // 심볼
    ulong m_magic;           // 매직 넘버
    bool m_isAutoTrading;    // 자동매매 활성화 여부
    
    // 지표 핸들
    int m_hEma5;            // EMA5 핸들
    int m_hEma20;           // EMA20 핸들
    int m_hEma40;           // EMA40 핸들
    int m_hAtr;             // ATR 핸들
    
    // 포지션 관리
    CArrayObj m_positions;   // 포지션 배열
    CTrade m_trade;         // 거래 객체
    
    // 유틸리티 메서드
    bool IsNewBar() {
        static datetime lastBar = 0;
        datetime currentBar = iTime(m_symbol, PERIOD_CURRENT, 0);
        if(currentBar != lastBar) {
            lastBar = currentBar;
            return true;
        }
        return false;
    }
    
    double GetATR() {
        double atr[];
        ArraySetAsSeries(atr, true);
        CopyBuffer(m_hAtr, 0, 0, 1, atr);
        return atr[0];
    }
    
    // EMA 시그널 체크
    int CheckEmaSignal() {
        double ema5[], ema20[], ema40[];
        ArraySetAsSeries(ema5, true);
        ArraySetAsSeries(ema20, true);
        ArraySetAsSeries(ema40, true);
        
        CopyBuffer(m_hEma5, 0, 0, 1, ema5);
        CopyBuffer(m_hEma20, 0, 0, 1, ema20);
        CopyBuffer(m_hEma40, 0, 0, 1, ema40);
        
        //Print("=== EMA 데이터 ===");
        //Print("EMA5: ", ema5[0]);
        //Print("EMA20: ", ema20[0]);
        //Print("EMA40: ", ema40[0]);
        
        double minDiff = 0.0;  // 최소 차이 설정
        
        // 정배열 체크 (5 > 20 > 40)
        if(ema5[0] > ema20[0] + minDiff && ema20[0] > ema40[0] + minDiff) {
            //Print("=== EMA 정배열 ===");
            //Print("EMA5-20 차이: ", ema5[0] - ema20[0]);
            //Print("EMA20-40 차이: ", ema20[0] - ema40[0]);
            return 1;
        }
        
        // 역배열 체크 (5 < 20 < 40)
        if(ema5[0] + minDiff < ema20[0] && ema20[0] + minDiff < ema40[0]) {
            //Print("=== EMA 역배열 ===");
            //Print("EMA20-5 차이: ", ema20[0] - ema5[0]);
            //Print("EMA40-20 차이: ", ema40[0] - ema20[0]);
            return -1;
        }
        
        //Print("=== EMA 중립 ===");
        return 0;
    }
    
    // 거래량 계산
    double CalculateVolume() {
        double atr = GetATR();
        if(atr == 0.0) return 0.01;  // 안전장치
        
        // 테스트용 고정 계좌 잔고
        double balance = TEST_BALANCE;  // $100
        double riskAmount = balance * RISK_PERCENT / 100.0;  // $1
        
        // 심볼 정보
        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        
        // ATR을 틱 단위로 변환 (2ATR = SL)
        double slInTicks = (atr * 2) / tickSize;
        
        // 1 로트당 리스크 계산
        double riskPerLot = slInTicks * tickValue;
        
        // 거래량 계산
        double volume = NormalizeDouble(riskAmount / riskPerLot, 2);
        volume = MathMax(volume, minLot);
        
        Print("=== 거래량 계산 상세 ===");
        Print("계좌잔고: $", balance);
        Print("리스크금액: $", riskAmount);
        Print("ATR: ", atr);
        Print("Tick Size: ", tickSize);
        Print("Tick Value: ", tickValue);
        Print("SL in Ticks: ", slInTicks);
        Print("Risk per Lot: ", riskPerLot);
        Print("계산된 거래량: ", volume);
        
        return volume;
    }
    
    // 피라미딩 조건 체크
    bool CheckPyramiding(ENUM_POSITION_TYPE type) {
        if(m_positions.Total() >= MAX_POSITIONS) {
            Print("최대 포지션 수 초과");
            return false;
        }
        
        CPosition* lastPos = GetLastPosition();
        if(lastPos == NULL) return false;
        
        double atr = GetATR();
        double halfN = atr / 2.0;
        double lastClose = iClose(m_symbol, PERIOD_CURRENT, 1);
        
        if(type == POSITION_TYPE_BUY) {
            return lastClose > (lastPos.price + halfN);
        } else {
            return lastClose < (lastPos.price - halfN);
        }
    }
    
    // 마지막 포지션 가져오기
    CPosition* GetLastPosition() {
        int total = m_positions.Total();
        if(total == 0) return NULL;
        return m_positions.At(total - 1);
    }
    
    // SL 업데이트
    void UpdateAllStopLoss(double newSL) {
        for(int i = 0; i < m_positions.Total(); i++) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL) {
                m_trade.PositionModify(pos.ticket, newSL, 0);
                pos.sl = newSL;
            }
        }
    }
    
    // 거래 사유를 텍스트로 변환
    string GetDealReasonText(ENUM_DEAL_REASON reason) {
        switch(reason) {
            case DEAL_REASON_SL: return "스탑로스";
            case DEAL_REASON_TP: return "익절";
            case DEAL_REASON_CLIENT: return "수동 청산";
            case DEAL_REASON_EXPERT: return "EA 청산";
            default: return "기타 (" + IntegerToString(reason) + ")";
        }
    }

public:
    // 생성자
    CvTrader(void) : m_isAutoTrading(false) {
        m_positions.Clear();
    }
    
    // 소멸자
    ~CvTrader(void) {
        m_positions.Clear();
    }
    
    // 초기화
    bool Init(string symbol, ulong magic) {
        m_symbol = symbol;
        m_magic = magic;
        
        // 지표 초기화
        m_hEma5 = iMA(m_symbol, PERIOD_CURRENT, 5, 0, MODE_EMA, PRICE_CLOSE);
        m_hEma20 = iMA(m_symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_hEma40 = iMA(m_symbol, PERIOD_CURRENT, 40, 0, MODE_EMA, PRICE_CLOSE);
        m_hAtr = iATR(m_symbol, PERIOD_CURRENT, 20);
        
        if(m_hEma5 == INVALID_HANDLE || m_hEma20 == INVALID_HANDLE || 
           m_hEma40 == INVALID_HANDLE || m_hAtr == INVALID_HANDLE) {
            return false;
        }
        
        // 거래 객체 설정
        m_trade.SetExpertMagicNumber(m_magic);
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(m_symbol);
        
        m_isAutoTrading = true;
        return true;
    }
    
    // 해제
    void Deinit() {
        IndicatorRelease(m_hEma5);
        IndicatorRelease(m_hEma20);
        IndicatorRelease(m_hEma40);
        IndicatorRelease(m_hAtr);
        m_positions.Clear();
    }
    
    // 틱 처리
    void OnTick() {
        if(!m_isAutoTrading) return;
        if(!IsNewBar()) return;
        
        Print("=== 새로운 틱 생성 ===");
        Print("시간: ", TimeToString(TimeCurrent()));
        

        int signal = CheckEmaSignal();
        
        // 포지션이 있는 경우
        if(m_positions.Total() > 0) {
            CPosition* pos = m_positions.At(0);
            
            // 청산 조건 체크
            if((pos.type == POSITION_TYPE_BUY && signal != 1) ||
               (pos.type == POSITION_TYPE_SELL && signal != -1)) {
                Print("=== 청산 시그널 발생 ===");
                CloseAllPositions();
                return;
            }
            
            // 피라미딩 체크
            if(CheckPyramiding(pos.type)) {
                OpenPosition(pos.type);
            }
        }
        // 포지션이 없는 경우
        else if(signal != 0) {
            ENUM_POSITION_TYPE type = (signal > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
            OpenPosition(type);
        }
    }
    
    // 거래 트랜잭션 처리
    void OnTradeTransaction(const MqlTradeTransaction& trans,
                          const MqlTradeRequest& request,
                          const MqlTradeResult& result) 
    {
        if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
        
        ulong dealTicket = trans.deal;
        if(!HistoryDealSelect(dealTicket)) return;
        
        // 딜 정보
        long posTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
        ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
        ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
        double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
        
        // 신규 진입
        if(dealEntry == DEAL_ENTRY_IN) {
            OnPositionOpened(posTicket, dealType, dealPrice, dealVolume);
        }
        // 청산
        else if(dealEntry == DEAL_ENTRY_OUT) {
            OnPositionClosed(posTicket);
        }
    }
    
private:
    // 포지션 오픈
    void OpenPosition(ENUM_POSITION_TYPE posType) {
        double volume = CalculateVolume();
        double price = (posType == POSITION_TYPE_BUY) ? 
            SymbolInfoDouble(m_symbol, SYMBOL_ASK) : 
            SymbolInfoDouble(m_symbol, SYMBOL_BID);
            
        double atr = GetATR();
        double sl = (posType == POSITION_TYPE_BUY) ? 
            price - (atr * 2) : price + (atr * 2);
            
        // POSITION_TYPE을 ORDER_TYPE으로 변환
        ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? 
            ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            
        if(m_trade.PositionOpen(m_symbol, orderType, volume, price, sl, 0)) {
            Print("포지션 진입 시도 - 가격: ", price, ", SL: ", sl);
        }
    }
    
    // 전체 포지션 청산
    void CloseAllPositions() {
        for(int i = m_positions.Total() - 1; i >= 0; i--) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL) {
                m_trade.PositionClose(pos.ticket);
            }
        }
    }
    
    // 포지션 오픈 처리
    void OnPositionOpened(long ticket, ENUM_DEAL_TYPE type, double price, double volume) {
        CPosition* pos = new CPosition();
        pos.ticket = ticket;
        pos.type = (type == DEAL_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
        pos.price = price;
        pos.volume = volume;
        
        double atr = GetATR();
        pos.sl = (pos.type == POSITION_TYPE_BUY) ? 
            price - (atr * 2) : price + (atr * 2);
            
        m_positions.Add(pos);
        
        // 피라미딩인 경우 모든 포지션의 SL 업데이트
        if(m_positions.Total() > 1) {
            UpdateAllStopLoss(pos.sl);
        }
        
        Print("=== 포지션 추가 ===");
        Print("티켓: ", ticket);
        Print("타입: ", (type == DEAL_TYPE_BUY ? "매수" : "매도"));
        Print("가격: ", price);
        Print("수량: ", volume);
        Print("SL: ", pos.sl);
        Print("총 포지션: ", m_positions.Total());
    }
    
    // 포지션 청산 처리
    void OnPositionClosed(long ticket) {
        for(int i = m_positions.Total() - 1; i >= 0; i--) {
            CPosition* pos = m_positions.At(i);
            if(pos != NULL && pos.ticket == ticket) {
                // 청산 정보 가져오기
                ulong dealTicket = HistoryDealGetTicket(0);  // 가장 최근 거래
                if(dealTicket > 0 && HistoryDealSelect(dealTicket)) {
                    double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                    ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON);
                    
                    // 손익 계산
                    double pips = pos.type == POSITION_TYPE_BUY ? 
                        closePrice - pos.price : pos.price - closePrice;
                    double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
                    double profit = pips * pos.volume;
                    
                    Print("=== 포지션 청산 상세 ===");
                    Print("청산 사유: ", GetDealReasonText(reason));
                    Print("진입가: ", pos.price);
                    Print("청산가: ", closePrice);
                    Print("거래량: ", pos.volume);
                    Print("손익(pips): ", NormalizeDouble(pips, 1));
                    Print("손익($): $", NormalizeDouble(profit, 2));
                }
                
                m_positions.Delete(i);
                break;
            }
        }
        Print("남은 포지션: ", m_positions.Total());
    }
}; 

//+------------------------------------------------------------------+
//| 미국 서머타임 체크                                                  |
//+------------------------------------------------------------------+
bool IsDaylightSavingTime(datetime time = 0)
{
    if(time == 0) time = TimeCurrent();
    
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    if(dt.mon < 3 || dt.mon > 11) return false;  // 1-2월, 12월: 서머타임 아님
    if(dt.mon > 3 && dt.mon < 11) return true;   // 4-10월: 서머타임
    
    int year = dt.year;
    
    // 3월의 둘째 일요일 계산
    int secondSun = 14 - (5 * year / 4 + 1) % 7;
    
    // 11월의 첫째 일요일 계산
    int firstSun = 1;
    while(firstSun <= 7) {
        MqlDateTime tmp;
        TimeToStruct(StringToTime(string(year) + ".11." + string(firstSun)), tmp);
        if(tmp.day_of_week == 0) break;
        firstSun++;
    }
    
    if(dt.mon == 3)
        return dt.day > secondSun || (dt.day == secondSun && dt.hour >= 2);
    else if(dt.mon == 11)
        return dt.day < firstSun || (dt.day == firstSun && dt.hour < 2);
        
    return false;
}

//+------------------------------------------------------------------+
//| 거래 시간 체크                                                      |
//+------------------------------------------------------------------+
bool IsTradeTime()
{
    datetime current = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current, dt);
    
    int current_hour = dt.hour;
    int current_min = dt.min;
    bool isUSDST = IsDaylightSavingTime();
    
    // 1. 뉴욕 장시작 2시간 (09:30-11:30 ET)
    if(isUSDST) {
        // 서머타임: MT5 시간 15:30-17:30
        if((current_hour == 15 && current_min >= 30) || 
           current_hour == 16 || 
           (current_hour == 17 && current_min <= 30))
            return true;
    } else {
        // 겨울시간: MT5 시간 16:30-18:30
        if((current_hour == 16 && current_min >= 30) || 
           current_hour == 17 || 
           (current_hour == 18 && current_min <= 30))
            return true;
    }
    
    // 2. 뉴욕 장마감 1시간 (15:00-16:00 ET)
    if(isUSDST) {
        // 서머타임: MT5 시간 21:00-22:00
        if(current_hour == 21)
            return true;
    } else {
        // 겨울시간: MT5 시간 22:00-23:00
        if(current_hour == 22)
            return true;
    }
    
    return false;
}