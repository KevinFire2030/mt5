#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrRed
#property indicator_width1  2

double SectionBuffer[];

int OnInit()
{
    SetIndexBuffer(0, SectionBuffer, INDICATOR_DATA);
    // 빈 값 설정
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
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
    if(start < 0) start = 0;
    
    for(int i = start; i < rates_total; i++)
    {
        // 고가와 저가의 차이가 평균보다 클 때만 선을 그림
        if(high[i] - low[i] > 0.001)
        {
            SectionBuffer[i] = high[i];
        }
        else
        {
            // 빈 값 설정
            SectionBuffer[i] = 0;
        }
    }
    
    return(rates_total);
} 