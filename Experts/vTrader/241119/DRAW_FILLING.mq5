#property indicator_separate_window  // 별도 창에 표시
#property indicator_buffers 2        // 2개의 버퍼 사용
#property indicator_plots   1        // 1개의 플롯 사용

#property indicator_type1   DRAW_FILLING     // 채우기 스타일
#property indicator_color1  clrRed,clrBlue   // 두 가지 색상 정의

input int Fast=13;    // 빠른 이동평균선 기간
input int Slow=21;    // 느린 이동평균선 기간
input int shift=1;    // 미래 방향 이동
input int N=5;        // 색상 변경 주기(틱)

double IntersectionBuffer1[];  // 상단 경계선
double IntersectionBuffer2[];  // 하단 경계선
int fast_handle;              // 빠른 MA 핸들
int slow_handle;              // 느린 MA 핸들

color colors[]={clrRed,clrBlue,clrGreen,clrAquamarine,clrBlanchedAlmond,clrBrown,clrCoral,clrDarkSlateGray};

int OnInit()
{
    SetIndexBuffer(0, IntersectionBuffer1, INDICATOR_DATA);
    SetIndexBuffer(1, IntersectionBuffer2, INDICATOR_DATA);

    // 이동 설정
    PlotIndexSetInteger(0, PLOT_SHIFT, shift);

    // MA 핸들 생성
    fast_handle = iMA(_Symbol, _Period, Fast, 0, MODE_SMA, PRICE_CLOSE);
    slow_handle = iMA(_Symbol, _Period, Slow, 0, MODE_SMA, PRICE_CLOSE);


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

    static int ticks=0;

    ticks++;

    if(ticks>=N)
     {
      //--- Change the line properties
      ChangeLineAppearance();
      //--- Reset the counter of ticks to zero
      ticks=0;
     }

     if(prev_calculated==0)
     {
      //--- Copy all the values of the indicators to the appropriate buffers
      int copied1=CopyBuffer(fast_handle,0,0,rates_total,IntersectionBuffer1);
      int copied2=CopyBuffer(slow_handle,0,0,rates_total,IntersectionBuffer2);
     }

     else // Fill only those data that are updated
     {
      //--- Get the difference in bars between the current and previous start of OnCalculate()
      int to_copy=rates_total-prev_calculated;
      //--- If there is no difference, we still copy one value - on the zero bar
      if(to_copy==0) to_copy=1;
      //--- copy to_copy values to the very end of indicator buffers
      int copied1=CopyBuffer(fast_handle,0,0,to_copy,IntersectionBuffer1);
      int copied2=CopyBuffer(slow_handle,0,0,to_copy,IntersectionBuffer2);
     }

     return(rates_total);


}

//+------------------------------------------------------------------+
//| Changes the colors of the channel filling                        |
//+------------------------------------------------------------------+
void ChangeLineAppearance()
  {
   
    string comm="";

    int number=MathRand();

    int size=ArraySize(colors);

    int color_index1=number%size;
    
    PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,colors[color_index1]);


    comm=comm+"\r\nColor1 "+(string)colors[color_index1];


    number=MathRand();

    int color_index2=number%size;

    PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,colors[color_index2]);

    comm=comm+"\r\nColor2 "+(string)colors[color_index2];

    Comment(comm);

  }