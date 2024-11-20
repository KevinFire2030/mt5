# MQL5 인디케이터 속성 가이드

## 1. 기본 정보 속성
```mq5
#property copyright "저작권 정보" // 저작권 정보
#property link "웹사이트 링크" // 웹사이트 링크
#property version "1.00" // 버전 정보
#property description "설명" // 인디케이터 설명
#property icon "아이콘경로.ico" // 아이콘 설정
```

## 2. 표시 위치 속성
```mq5
#property indicator_chart_window // 메인 차트창에 표시
#property indicator_separate_window // 별도의 창에 표시
```

## 3. 버퍼와 플롯 관련 속성
```mq5
#property indicator_buffers N // 버퍼 개수 설정
#property indicator_plots N // 그래프 플롯 개수 설정

```
## 4. 그래프 스타일 속성
```mq5
#property indicator_type1 DRAW_LINE // 선 형태
#property indicator_type1 DRAW_SECTION // 섹션
#property indicator_type1 DRAW_HISTOGRAM // 히스토그램
#property indicator_type1 DRAW_ARROW // 화살표
#property indicator_type1 DRAW_ZIGZAG // 지그재그
#property indicator_type1 DRAW_FILLING // 채우기
#property indicator_type1 DRAW_BARS // 봉차트
#property indicator_type1 DRAW_CANDLES // 캔들차트
```

### DRAW_SECTION
- 두 점을 **직선으로** 연결하는 그래프 스타일입니다. 
- 일반적인 DRAW_LINE과의 주요 차이점은:
  - DRAW_LINE: 모든 포인트를 연속적으로 연결
  - DRAW_SECTION: 빈 값(empty value)이 아닌 두 포인트 사이만 연결
- DRAW_SECTION은 주로:
  - 특정 조건에서만 선을 그리고 싶을 때
  - 불연속적인 선을 그리고 싶을 때
  - 피보나치 리트레이스먼트와 같은 도구를 만들 때

### DRAW_ARROW
- 화살표 그래프 스타일은 특정 조건에서 화살표를 표시하는 데 사용됩니다. 
- 이 스타일은 주로 매수 또는 매도 신호를 나타내는 데 사용됩니다.

#### 화살표 코드 설정
```mq5
PlotIndexSetInteger(index, PLOT_ARROW, arrow_code);
```
159: ● 점
167: ○ 빈 점
233: ↑ 위쪽 화살표
234: ↓ 아래쪽 화살표
241: ✓ 체크 마크

#### 화살표 위치 조정
```mq5
PlotIndexSetInteger(index, PLOT_ARROW_SHIFT, shift);
```
#### 화살표 표시 위치

BuyArrowBuffer[i] = low[i];   // 저가에 표시
SellArrowBuffer[i] = high[i]; // 고가에 표시


#### DRAW_ARROW는 주로:
- 매수/매도 신호 표시
- 중요 이벤트 표시
- 특정 조건 발생 지점 표시
등에 사용됩니다.

