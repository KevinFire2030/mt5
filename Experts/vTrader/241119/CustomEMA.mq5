#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "EMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

// 입력 파라미터
input int    EMA_Period = 20;        // EMA 기간
input double Alpha = 2.0/(20+1);     // 가중치 (기본값: 2/(기간+1))

// 버퍼
double EMABuffer[];

int OnInit()
{
    SetIndexBuffer(0, EMABuffer, INDICATOR_DATA);
    
    // 인디케이터 이름 설정
    string short_name = StringFormat("EMA(%d)", EMA_Period);
    IndicatorSetString(INDICATOR_SHORTNAME, short_name);
    
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
    // 데이터가 부족하면 종료
    if(rates_total < EMA_Period) return(0);
    
    int start;
    
    // 첫 실행시 초기화
    if(prev_calculated == 0)
    {
        // 첫 번째 EMA 값은 단순 평균으로 계산
        double sum = 0;
        for(int i = 0; i < EMA_Period; i++)
            sum += close[i];
            
        EMABuffer[EMA_Period-1] = sum / EMA_Period;
        start = EMA_Period;
    }
    else
        start = prev_calculated - 1;
    
    // EMA 계산
    // EMA = Alpha * CurrentPrice + (1 - Alpha) * PreviousEMA
    for(int i = start; i < rates_total; i++)
    {
        EMABuffer[i] = Alpha * close[i] + (1 - Alpha) * EMABuffer[i-1];
    }
    
    return(rates_total);
} 