//+------------------------------------------------------------------+
//| EA 프로그램 시작 함수들                                             |
//+------------------------------------------------------------------+
input group    "분석 설정"
input int      TradesCount     = 20;          // 분석할 거래 수 (0=전체기간)
input datetime StartDate       = D'2024.01.01';// 시작 날짜
input datetime EndDate         = D'2024.12.31';// 종료 날짜

int OnInit()
{
    // 날짜 유효성 검사
    if(EndDate < StartDate) {
        Print("오류: 종료 날짜가 시작 날짜보다 앞설 수 없습니다.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 분석 실행
    TradeAnalysis analysis = AnalyzeRecentTrades(TradesCount, StartDate, EndDate);
    PrintTradeAnalysis(analysis);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // 정리할 내용 없음
}

void OnTick()
{
    // 틱마다의 처리는 필요없음
}

//+------------------------------------------------------------------+
//| 거래 분석 유틸리티 함수들
//+------------------------------------------------------------------+

// 최근 N개의 거래 분석 결과를 구조체로 반환
struct TradeAnalysis {
    int totalTrades;        // 전체 거래 수
    int winTrades;          // 승리 거래 수
    int lossTrades;         // 손실 거래 수
    double winRate;         // 승률
    double avgProfit;       // 평균 수익
    double avgLoss;         // 평균 손실
    double profitFactor;    // 수익 팩터
    double maxDrawdown;     // 최대 드로우다운
};

//+------------------------------------------------------------------+
//| 최근 N개의 거래 분석
//+------------------------------------------------------------------+
TradeAnalysis AnalyzeRecentTrades(int count = 0, datetime startDate = 0, datetime endDate = 0) {
    TradeAnalysis analysis = {0};
    
    double totalProfit = 0;
    double totalLoss = 0;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double maxBalance = balance;
    double currentDrawdown = 0;
    
    // 종료 날짜가 설정되지 않은 경우 현재 시간 사용
    if(endDate == 0) endDate = TimeCurrent();
    
    HistorySelect(startDate, endDate); // 지정된 기간의 거래 내역 선택
    
    // 최근 거래부터 역순으로 분석
    int total = HistoryDealsTotal();
    int analyzed = 0;
    
    for(int i = total - 1; i >= 0; i--) {
        // count가 0이면 전체 기간 분석, 아니면 지정된 수만큼만 분석
        if(count > 0 && analyzed >= count) break;
        
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        
        // 거래 시간 확인
        datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        if(dealTime < startDate || dealTime > endDate) continue;
        
        // 거래 정보 가져오기
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        
        if(profit > 0) {
            analysis.winTrades++;
            totalProfit += profit;
        }
        else if(profit < 0) {
            analysis.lossTrades++;
            totalLoss += MathAbs(profit);
        }
        
        // 드로우다운 계산
        balance += profit;
        if(balance > maxBalance) maxBalance = balance;
        currentDrawdown = (maxBalance - balance) / maxBalance * 100;
        if(currentDrawdown > analysis.maxDrawdown) 
            analysis.maxDrawdown = currentDrawdown;
            
        analyzed++;
    }
    
    // 분석 결과 계산
    analysis.totalTrades = analysis.winTrades + analysis.lossTrades;
    if(analysis.totalTrades > 0) {
        analysis.winRate = (double)analysis.winTrades / analysis.totalTrades * 100;
        analysis.avgProfit = analysis.winTrades > 0 ? totalProfit / analysis.winTrades : 0;
        analysis.avgLoss = analysis.lossTrades > 0 ? totalLoss / analysis.lossTrades : 0;
        analysis.profitFactor = analysis.avgLoss > 0 ? analysis.avgProfit / analysis.avgLoss : 0;
    }
    
    return analysis;
}

//+------------------------------------------------------------------+
//| 분석 결과 출력
//+------------------------------------------------------------------+
void PrintTradeAnalysis(const TradeAnalysis &analysis) {
    Print("=== 거래 분석 결과 ===");
    Print("분석 기간: ", TimeToString(StartDate), " ~ ", TimeToString(EndDate));
    Print("전체 거래 수: ", analysis.totalTrades);
    Print("승리 거래: ", analysis.winTrades);
    Print("손실 거래: ", analysis.lossTrades);
    Print(StringFormat("승률: %.2f%%", analysis.winRate));
    Print(StringFormat("평균 수익: %.2f", analysis.avgProfit));
    Print(StringFormat("평균 손실: %.2f", analysis.avgLoss));
    Print(StringFormat("수익 팩터: %.2f", analysis.profitFactor));
    Print(StringFormat("최대 드로우다운: %.2f%%", analysis.maxDrawdown));
    Print("=====================");
}
