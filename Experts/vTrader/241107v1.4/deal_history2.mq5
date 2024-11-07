//+------------------------------------------------------------------+
//|                                                 deal_history2.mq5   |
//|                                                                    |
//|                                             Copyright 2023         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023"
#property link      ""
#property version   "1.00"
#property script_show_inputs

//--- 입력 파라미터
input group "==== 기간 설정 ===="
input datetime    from = D'2024.11.06 00:00';    // 시작 날짜
input datetime    to   = 0;                      // 종료 날짜 (0: 현재)

input group "==== 매직넘버 설정 ===="
input int         magic = 0;                     // 매직 넘버 (0: 전체)

//+------------------------------------------------------------------+
//| 분석 기간 설정 함수                                                |
//+------------------------------------------------------------------+
struct AnalysisPeriod
{
    datetime start_date;
    datetime end_date;
};

//+------------------------------------------------------------------+
//| 분석 기간을 설정하고 반환                                          |
//+------------------------------------------------------------------+
AnalysisPeriod SetAnalysisPeriod(datetime from_date, datetime to_date)
{
    AnalysisPeriod period;
    
    // 시작 날짜 설정
    period.start_date = from_date;
    
    // 종료 날짜 설정 (0이면 현재 시간으로)
    period.end_date = (to_date == 0) ? TimeCurrent() : to_date;
    
    // 시작 날짜가 종료 날짜보다 늦을 경우 교체
    if(period.start_date > period.end_date)
    {
        datetime temp = period.start_date;
        period.start_date = period.end_date;
        period.end_date = temp;
        Print("경고: 시작 날짜가 종료 날짜보다 늦어 자동으로 교체되었습니다.");
    }
    
    Print("분석 기간: ", 
          TimeToString(period.start_date), " ~ ", 
          TimeToString(period.end_date));
    
    return period;
}

//+------------------------------------------------------------------+
//| 거래 내역 구조체                                                   |
//+------------------------------------------------------------------+
struct TradeRecord
{
    datetime time;           // 거래 시간
    ulong    ticket;        // 켓 번호
    ulong    order;         // 주문 번호
    ulong    position_id;   // 포지션 ID
    string   type;          // 거래 유형
    double   volume;        // 거래량
    string   symbol;        // 심볼
    double   price;         // 가격
    double   sl;            // 손절가
    double   tp;            // 익절가
    double   profit;        // 손익
    double   commission;    // 수수료
    double   swap;          // 스왑
    string   comment;       // 거래 코멘트
    int      magic;         // 매직 넘버
    string   deal_reason;   // 거래 사유
    string   entry_type;    // 진입 유형 (시장가/지정가)
    double   pips;          // pips 손익
    double   net_profit;    // 순손익 (profit + commission + swap)
};

//+------------------------------------------------------------------+
//| 거래 사유를 문자열로 변환                                          |
//+------------------------------------------------------------------+
string GetDealReasonString(ENUM_DEAL_REASON reason)
{
    switch(reason)
    {
        case DEAL_REASON_CLIENT: return "클라이언트";
        case DEAL_REASON_MOBILE: return "모바일";
        case DEAL_REASON_WEB: return "웹";
        case DEAL_REASON_EXPERT: return "EA";
        case DEAL_REASON_SL: return "손절";
        case DEAL_REASON_TP: return "익절";
        case DEAL_REASON_SO: return "스탑아웃";
        default: return "기타";
    }
}

//+------------------------------------------------------------------+
//| 진입 유형을 문자열로 변환                                          |
//+------------------------------------------------------------------+
string GetEntryTypeString(ENUM_DEAL_ENTRY entry)
{
    switch(entry)
    {
        case DEAL_ENTRY_IN: return "진입";
        case DEAL_ENTRY_OUT: return "청산";
        case DEAL_ENTRY_INOUT: return "반전";
        case DEAL_ENTRY_OUT_BY: return "반대청산";
        default: return "기타";
    }
}

//+------------------------------------------------------------------+
//| pips 계산                                                         |
//+------------------------------------------------------------------+
double CalculatePips(string symbol, double open_price, double close_price, ENUM_DEAL_TYPE deal_type)
{
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double pips = (close_price - open_price) / point;
    return (deal_type == DEAL_TYPE_BUY) ? pips : -pips;
}

//+------------------------------------------------------------------+
//| 거래 내역을 불러오는 함수                                          |
//+------------------------------------------------------------------+
void LoadTradeHistory(datetime start_date, datetime end_date, int magic_number)
{
    // 거래 내역 선택
    if(!HistorySelect(start_date, end_date))
    {
        Print("거래 내역을 불러올 수 없습니다!");
        return;
    }
    
    // 전체 거래 수
    int deals_total = HistoryDealsTotal();
    
    // 통계 변수 초기화
    double total_profit = 0;
    int winning_trades = 0;
    int losing_trades = 0;
    double total_wins = 0;    // 승리 거래의 총 수익
    double total_losses = 0;  // 패배 거래의 총 손실
    
    Print("총 ", deals_total, "개의 거래를 분석합니다...");
    
    // 각 거래 분석
    for(int i = 0; i < deals_total; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        
        // 매직 넘버 확인
        int deal_magic = (int)HistoryDealGetInteger(ticket, DEAL_MAGIC);
        if(magic_number != 0 && deal_magic != magic_number) continue;
        
        TradeRecord trade;
        trade.time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        trade.ticket = ticket;
        trade.order = HistoryDealGetInteger(ticket, DEAL_ORDER);
        trade.position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
        trade.volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
        trade.symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        trade.price = HistoryDealGetDouble(ticket, DEAL_PRICE);
        trade.sl = HistoryDealGetDouble(ticket, DEAL_SL);
        trade.tp = HistoryDealGetDouble(ticket, DEAL_TP);
        trade.profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        trade.commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        trade.swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        trade.comment = HistoryDealGetString(ticket, DEAL_COMMENT);
        trade.magic = (int)HistoryDealGetInteger(ticket, DEAL_MAGIC);
        
        // 거래 사유와 진입 유형 설정
        ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(ticket, DEAL_REASON);
        ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
        trade.deal_reason = GetDealReasonString(deal_reason);
        trade.entry_type = GetEntryTypeString(deal_entry);
        
        // 거래 유형 설정
        ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
        switch(deal_type)
        {
            case DEAL_TYPE_BUY: trade.type = "매수"; break;
            case DEAL_TYPE_SELL: trade.type = "매도"; break;
            default: continue;  // 다른 타입의 거래는 무시
        }
        
        // pips 계산 및 순손익 계산
        trade.pips = CalculatePips(trade.symbol, trade.price, trade.price, deal_type);  // 청산 가격은 나중에 계산
        trade.net_profit = trade.profit + trade.commission + trade.swap;
        
        // 거래 정보 출력
        PrintFormat("%s | 티켓: %d | %s | %.2f lot | %s | %s | %s | 손익: %.2f | pips: %.1f",
                   TimeToString(trade.time),
                   trade.ticket,
                   trade.type,
                   trade.volume,
                   trade.symbol,
                   trade.deal_reason,
                   trade.entry_type,
                   trade.net_profit,
                   trade.pips);
        
        // 통계 업데이트
        if(trade.net_profit > 0) 
        {
            winning_trades++;
            total_wins += trade.net_profit;
        }
        else if(trade.net_profit < 0) 
        {
            losing_trades++;
            total_losses += MathAbs(trade.net_profit);  // 절대값으로 저장
        }
        total_profit += trade.net_profit;
    }
    
    // 최종 통계 출력 부분 수정
    int total_trades = winning_trades + losing_trades;
    double win_rate = total_trades > 0 ? (100.0 * winning_trades / total_trades) : 0;
    double loss_rate = total_trades > 0 ? (100.0 * losing_trades / total_trades) : 0;
    
    // 평균 수익/손실 계산
    double avg_win = (winning_trades > 0) ? total_wins / winning_trades : 0;
    double avg_loss = (losing_trades > 0) ? total_losses / losing_trades : 0;
    
    // RR비율과 TE 계산
    double rr_ratio = (avg_loss > 0) ? avg_win / avg_loss : 0;
    double te = (win_rate/100.0 * avg_win) - (loss_rate/100.0 * avg_loss);
    
    // Win RR 계산 (이기는데 필요한 RR비율)
    double win_rr = (win_rate > 0 && win_rate < 100) ? ((100.0 - win_rate) / win_rate) : 0;
    
    Print("=== 거래 통계 ===");
    PrintFormat("총 거래 수: %d", total_trades);
    PrintFormat("승리: %d | 패배: %d", winning_trades, losing_trades);
    PrintFormat("승률: %.2f%%", win_rate);
    PrintFormat("총 손익: %.2f", total_profit);
    PrintFormat("평균 수익: %.2f", avg_win);
    PrintFormat("평균 손실: %.2f", avg_loss);
    PrintFormat("RR비율: %.2f (Win RR > %.2f)", rr_ratio, win_rr);
    PrintFormat("TE: %.2f", te);
}

//+------------------------------------------------------------------+
//| Script program start function                                      |
//+------------------------------------------------------------------+
void OnStart()
{
    // 분석 기간 설정
    AnalysisPeriod period = SetAnalysisPeriod(from, to);
    
    // 거래 내역 불러오기
    LoadTradeHistory(period.start_date, period.end_date, magic);
} 