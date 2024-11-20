#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

// 저항선 설정
#property indicator_label1  "저항선"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrRed
#property indicator_width1  2

// 지지선 설정
#property indicator_label2  "지지선"
#property indicator_type2   DRAW_SECTION
#property indicator_color2  clrGreen
#property indicator_width2  2

double ResistanceBuffer[];
double SupportBuffer[];

int OnInit()
{
    SetIndexBuffer(0, ResistanceBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SupportBuffer, INDICATOR_DATA);
    
    // 빈 값 설정
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
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
        // 저항선: 이전 고점보다 높은 고점이 나타날 때
        if(i > 0 && high[i] > high[i-1])
        {
            ResistanceBuffer[i] = high[i];
        }
        else
        {
            ResistanceBuffer[i] = 0; // 빈 값
        }
        
        // 지지선: 이전 저점보다 낮은 저점이 나타날 때
        if(i > 0 && low[i] < low[i-1])
        {
            SupportBuffer[i] = low[i];
        }
        else
        {
            SupportBuffer[i] = 0; // 빈 값
        }
    }
    
    return(rates_total);
} 