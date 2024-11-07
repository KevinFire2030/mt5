//+------------------------------------------------------------------+
//|                                                  deal_history.mq5   |
//|                                                                    |
//|                                             Copyright 2023         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023"
#property link      ""
#property version   "1.00"
#property script_show_inputs

//--- 입력 파라미터
input datetime    StartDate = D'2024.11.06 00:00';    // 시작 날짜
input datetime    EndDate   = D'2024.11.07 23:59';    // 종료 날짜

//+------------------------------------------------------------------+
//| 청산가격과 pips 계산을 위한 함수                                    |
//+------------------------------------------------------------------+
double CalculatePips(double entry_price, double exit_price, string symbol, ENUM_DEAL_TYPE deal_type)
{
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double pips = (exit_price - entry_price) / point;
    return (deal_type == DEAL_TYPE_BUY) ? pips : -pips;
}

//+------------------------------------------------------------------+
//| Script program start function                                      |
//+------------------------------------------------------------------+
void OnStart()
{
    // 간단한 파일명 생성
    string filename = "trade_history_" + TimeToString(StartDate, TIME_DATE) + ".csv";
    
    // 파일 생성 (FILE_COMMON 플래그를 제거하고 상대 경로 사용)
    int filehandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI);
    
    if(filehandle != INVALID_HANDLE)
    {
        // CSV 헤더 작성
        FileWrite(filehandle, "시간", "티켓", "종류", "로트", "심볼", "진입가격", "청산가격", "손익(pips)", "손익($)", "수수료", "스왑", "순손익");
        
        // 거래 내역 가져오기
        HistorySelect(StartDate, EndDate);  // StructToTime 제거
        int deals_total = HistoryDealsTotal();
        
        double total_profit = 0;
        double total_pips = 0;
        int winning_trades = 0;
        int losing_trades = 0;
        
        // 거래 매칭을 위한 구조체 정의
        struct DealInfo
        {
            datetime time;
            double volume;
            double entry_price;
            double exit_price;
            double profit;
            double commission;
            double swap;
            ENUM_DEAL_TYPE deal_type;
        };
        
        for(int i = 0; i < deals_total; i++)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket > 0)
            {
                string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
                if(symbol != _Symbol) continue;  // 현재 심볼의 거래만 분석
                
                datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
                double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                double price = HistoryDealGetDouble(ticket, DEAL_PRICE);
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
                ENUM_DEAL_TYPE deal_type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
                
                string type_str = "";
                switch(deal_type)
                {
                    case DEAL_TYPE_BUY: type_str = "매수"; break;
                    case DEAL_TYPE_SELL: type_str = "매도"; break;
                    default: continue;  // 다른 타입의 거래는 무시
                }
                
                // 거래 정보 기록
                FileWrite(filehandle, 
                    TimeToString(time),
                    IntegerToString(ticket),
                    type_str,
                    DoubleToString(volume, 2),
                    symbol,
                    DoubleToString(price, _Digits),
                    "",  // 청산가격은 나중에 계산
                    "",  // pips도 나중에 계산
                    DoubleToString(profit, 2),
                    DoubleToString(commission, 2),
                    DoubleToString(swap, 2),
                    DoubleToString(profit + commission + swap, 2)
                );
                
                // 통계 업데이트
                if(profit > 0) winning_trades++;
                else if(profit < 0) losing_trades++;
                
                total_profit += profit + commission + swap;
            }
        }
        
        // 통계 정보 기록
        FileWrite(filehandle, "");
        FileWrite(filehandle, "=== 거래 통계 ===");
        FileWrite(filehandle, "총 거래 수", IntegerToString(winning_trades + losing_trades));
        FileWrite(filehandle, "승리 거래", IntegerToString(winning_trades));
        FileWrite(filehandle, "패배 거래", IntegerToString(losing_trades));
        
        // 승률 계산 시 0으로 나누기 방지
        double win_rate = (winning_trades + losing_trades > 0) 
            ? 100.0 * winning_trades / (winning_trades + losing_trades) 
            : 0.0;
        FileWrite(filehandle, "승률", DoubleToString(win_rate, 2) + "%");
        FileWrite(filehandle, "총 손익", DoubleToString(total_profit, 2) + " USD");
        
        FileClose(filehandle);
        Print("거래 내역이 ", filename, " 파일에 저장되었습니다.");
    }
    else
    {
        Print("파일을 생성할 수 없습니다! 에러 코드: ", GetLastError());
        Print("시도한 파일 경로: ", filename);
    }
} 