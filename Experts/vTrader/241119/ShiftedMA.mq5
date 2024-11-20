#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "Shifted MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

// 입력 파라미터
input int    MA_Period = 20;     // 이동평균 기간
input int    MA_Shift = -1;      // 시프트 (-1은 과거로 1봉 이동)

double MABuffer[];
int ma_handle;

int OnInit()
{
    SetIndexBuffer(0, MABuffer, INDICATOR_DATA);
    
    // 이동평균선을 과거로 1봉 이동
    PlotIndexSetInteger(0, PLOT_SHIFT, MA_Shift);
    
    // 이동평균 핸들 생성
    ma_handle = iMA(_Symbol, _Period, MA_Period, 0, MODE_SMA, PRICE_CLOSE);
    
    return(INIT_SUCCEEDED);
}

int OnCalculate(...)
{
    // 이동평균 데이터 복사
    CopyBuffer(ma_handle, 0, 0, rates_total, MABuffer);
    
    return(rates_total);
} 