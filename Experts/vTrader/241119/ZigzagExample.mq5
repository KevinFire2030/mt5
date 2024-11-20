#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_label1  "ZigZag"
#property indicator_type1   DRAW_ZIGZAG
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

double ZigzagBuffer[];
double ColorBuffer[];

// 지그재그 설정값
input int InpDepth = 12;      // 깊이 (몇 개의 봉을 비교할지)
input int InpDeviation = 5;   // 편차 (가격 변동의 민감도, 포인트 단위)
input int InpBackstep = 3;    // 백스텝 (재탐색 깊이)

int OnInit()
{
    SetIndexBuffer(0, ZigzagBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ColorBuffer, INDICATOR_COLOR_INDEX);
    
    // 빈 값 설정
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    
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
    if(rates_total < InpDepth) return(0);
    
    int start = prev_calculated - 1;
    if(start < InpDepth) start = InpDepth;
    
    // 버퍼 초기화
    if(prev_calculated == 0)
    {
        for(int i = 0; i < rates_total; i++)
            ZigzagBuffer[i] = 0.0;
    }
    
    // 지그재그 계산
    int pos = 0, direction = 0;
    double lastHigh = 0.0, lastLow = 0.0;
    
    for(int i = start; i < rates_total-1; i++)
    {
        // 고점 찾기
        bool isHigh = true;
        for(int j = 1; j <= InpDepth; j++)
        {
            if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
            if(i+j < rates_total && high[i] <= high[i+j]) isHigh = false;
        }
        
        // 저점 찾기
        bool isLow = true;
        for(int j = 1; j <= InpDepth; j++)
        {
            if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
            if(i+j < rates_total && low[i] >= low[i+j]) isLow = false;
        }
        
        // 지그재그 포인트 설정
        if(isHigh && direction <= 0)
        {
            if(direction == 0 || high[i] > lastHigh)
            {
                ZigzagBuffer[i] = high[i];
                if(pos > 0) ZigzagBuffer[pos] = 0.0;
                pos = i;
                lastHigh = high[i];
                direction = 1;
            }
        }
        
        if(isLow && direction >= 0)
        {
            if(direction == 0 || low[i] < lastLow)
            {
                ZigzagBuffer[i] = low[i];
                if(pos > 0) ZigzagBuffer[pos] = 0.0;
                pos = i;
                lastLow = low[i];
                direction = -1;
            }
        }
    }
    
    return(rates_total);
} 