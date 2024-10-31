# vTrader

터틀 트레이딩 기반의 자동 매매 시스템

## 개요

- 프로그램 명: vTrader
- 버전: 1.0
- 목적: 터틀 트레이딩 기반의 자동 매매
- 플랫폼: MetaTrader 5
- 브로커: FxPro

## 주요 기능

- 터틀 트레이딩 기반 자금 관리
- EMA 기반 진입/청산 전략
- 피라미딩 전략
- 리스크 관리

## 프로젝트 구조

```
MQL5/
├── Experts/
│   └── FxPro/
│       ├── vTrader.mq5          # 메인 EA 파일
│       ├── 설계.md              # 설계 문서
│       ├── 구현.md              # 구현 계획
│       └── Include/
│           └── vTrader.mqh      # 헤더 파일
└── README.md
```

## 설치 방법

1. 이 저장소를 클론합니다
2. MQL5 폴더의 내용을 MetaTrader 5의 MQL5 폴더에 복사합니다
3. MetaEditor에서 vTrader.mq5를 컴파일합니다
4. MetaTrader 5에서 EA를 차트에 적용합니다

## 사용 방법

1. EA 적용 후 입력 파라미터 설정
   - 타임프레임
   - 리스크 비율
   - 최대 포지션 수
   - 최대 피라미딩 수

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 