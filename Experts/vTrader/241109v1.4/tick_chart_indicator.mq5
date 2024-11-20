//+------------------------------------------------------------------+
//| 틱 차트 지표                                                        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window  // 별도 창에 표시
#property indicator_height 350      // 창 높이 설정
#property indicator_buffers 4
#property indicator_plots   1

// 입력 파라미터
input int InpTickCount = 5;        // 틱 개수

// 캔들스틱 설정
#property indicator_type1   DRAW_CANDLES
#property indicator_color1  clrLime      // 상승봉 색상
#property indicator_color2  clrRed       // 하락봉 색상
#property indicator_width1  2            // 캔들 두께

// 버퍼
double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];

// 틱 데이터 구조체
struct TickBarData {
    datetime time;
    long time_msc;
    double open;
    double high;
    double low;
    double close;
    ulong volume;
    int tickCount;
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                           |
//+------------------------------------------------------------------+
int OnInit()
{
    // 버퍼 설정
    SetIndexBuffer(0, OpenBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, HighBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, LowBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, CloseBuffer, INDICATOR_DATA);
    
    // 지표 이름 설정
    IndicatorSetString(INDICATOR_SHORTNAME, "Tick Chart (" + IntegerToString(InpTickCount) + " ticks)");
    
    // 차트 속성 설정
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_SHOW_GRID, false);
    ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
    ChartSetInteger(0, CHART_SHOW_VOLUMES, false);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
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
    static int lastIndex = -1;
    TickBarData bar;
    int currentIndex;
    
    // 새로운 봉 데이터 확인
    if(LoadBarData(bar, currentIndex) && currentIndex > lastIndex) {
        // 버퍼에 데이터 추가
        int idx = rates_total - 1;
        OpenBuffer[idx] = bar.open;
        HighBuffer[idx] = bar.high;
        LowBuffer[idx] = bar.low;
        CloseBuffer[idx] = bar.close;
        
        lastIndex = currentIndex;
    }
    
    return(rates_total);
}

//+------------------------------------------------------------------+
//| 봉 데이터 읽기 함수                                               |
//+------------------------------------------------------------------+
bool LoadBarData(TickBarData& bar, int& index)
{
    string prefix = "TickChart_" + _Symbol + "_";
    
    if(!GlobalVariableCheck(prefix + "Index")) 
        return false;
        
    index = (int)GlobalVariableGet(prefix + "Index");
    bar.time = (datetime)GlobalVariableGet(prefix + "Time");
    bar.time_msc = (long)GlobalVariableGet(prefix + "TimeMsc");
    bar.open = GlobalVariableGet(prefix + "Open");
    bar.high = GlobalVariableGet(prefix + "High");
    bar.low = GlobalVariableGet(prefix + "Low");
    bar.close = GlobalVariableGet(prefix + "Close");
    bar.volume = (ulong)GlobalVariableGet(prefix + "Volume");
    
    // 새로운 봉 확인 후 플래그 리셋
    bool isNewBar = (GlobalVariableGet(prefix + "IsNewBar") == 1);
    if(isNewBar) GlobalVariableSet(prefix + "IsNewBar", 0);
    
    return isNewBar;
}

//+------------------------------------------------------------------+
//| 지표 제거 시 정리                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, "TickCandle_");
}