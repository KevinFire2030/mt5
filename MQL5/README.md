# vTrader

MQL5로 구현한 자동매매 시스템

## 프로젝트 구조
```
vTrader/
├── Experts/
│ └── FxPro/
│   └── vTrader.mq5 # EA 메인 파일
├── Include/
│   └── FxPro/
│     └── vTrader.mqh # 메인 트레이딩 클래스
├── README.md
├── 구현.md
├── .gitignore
└── LICENSE
```
## 설치 방법
1. MT5 데이터 폴더 열기 (파일 > 데이터 폴더 열기)
2. 프로젝트 파일을 해당 폴더에 복사
3. MT5 재시작
4. 네비게이터 창에서 Expert Advisors > FxPro > vTrader 확인

## 사용 방법
1. 차트에 EA 드래그 앤 드롭
2. 파라미터 설정
   - TimeFrame: 분석 시간프레임
   - Risk: 리스크 비율(%)
   - MaxPositions: 최대 포지션 수
   - MaxPyramiding: 최대 피라미딩 수

## 라이센스
MIT License