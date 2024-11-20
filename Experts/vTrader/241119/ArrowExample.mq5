#property indicator_chart_window      // 메인 차트에 표시
#property indicator_buffers 2         // 2개 버퍼 사용
#property indicator_plots   2         // 2개 플롯 사용

// 매수 신호 화살표 설정
#property indicator_label1  "매수 신호"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_width1  1
#property indicator_style1  STYLE_SOLID

// 매도 신호 화살표 설정
#property indicator_label2  "매도 신호"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  1
#property indicator_style2  STYLE_SOLID

double BuyArrowBuffer[];    // 매수 화살표 버퍼
double SellArrowBuffer[];   // 매도 화살표 버퍼

int OnInit()
{
    // 버퍼 설정
    SetIndexBuffer(0, BuyArrowBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SellArrowBuffer, INDICATOR_DATA);
    
    // 화살표 코드 설정 (윙딩스 폰트 코드)
    PlotIndexSetInteger(0, PLOT_ARROW, 233);    // 위쪽 화살표
    PlotIndexSetInteger(1, PLOT_ARROW, 234);    // 아래쪽 화살표
    
    // 화살표 크기 설정
    PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, 20);  // 위치 조정
    PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -20);
    
    return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int start = prev_calculated - 1;
    if(start < 0) start = 1;
    
    for(int i = start; i < rates_total; i++)
    {
        // 매수 신호 조건 (예: 거래량이 평균보다 높을 때)
        if(close[i] > close[i-1])
        {
            BuyArrowBuffer[i] = close[i];  // 봉 아래에 표시
            SellArrowBuffer[i] = 0;      // 빈 값
        }
        // 매도 신호 조건
        else if(close[i] < close[i-1])
        {
            SellArrowBuffer[i] = close[i]; // 봉 위에 표시
            BuyArrowBuffer[i] = 0;        // 빈 값
        }
        else
        {
            BuyArrowBuffer[i] = 0;
            SellArrowBuffer[i] = 0;
        }
    }
    
    return(rates_total);
} 