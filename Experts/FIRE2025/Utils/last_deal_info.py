import MetaTrader5 as mt5
from datetime import datetime
import pandas as pd
import pytz

def connect_mt5():
    """MT5에 연결"""
    if not mt5.initialize():
        print("MT5 연결 실패")
        mt5.shutdown()
        return False
    return True

def get_last_deals(count=20):
    """최근 거래 내역 조회"""
    if not connect_mt5():
        return None
        
    # 현재 시간 기준으로 거래 내역 가져오기
    timezone = pytz.timezone("EET")  # Eastern European Time (UTC+2)
    to_date = datetime.now(timezone)
    
    # 거래 내역 조회
    deals = mt5.history_deals_get(0, to_date)
    
    if deals is None or len(deals) == 0:
        print("거래 내역이 없습니다")
        return None
        
    # 거래 내역을 데이터프레임으로 변환
    df = pd.DataFrame(list(deals), columns=[
        "ticket", "order_ticket", "position_id", "time", "type",
        "entry", "magic", "position_id", "volume", "price",
        "commission", "swap", "profit", "symbol", "comment"
    ])
    
    # 시간 컬럼을 datetime으로 변환
    df['time'] = pd.to_datetime(df['time'], unit='s')
    
    # 최근 거래부터 정렬
    df = df.sort_values('time', ascending=False)
    
    # 요청된 수만큼 반환
    return df.head(count)

def analyze_deals(df):
    """거래 내역 분석"""
    if df is None or len(df) == 0:
        return
        
    print("\n=== 최근 거래 분석 ===")
    print(f"전체 거래 수: {len(df)}")
    
    # 수익 거래와 손실 거래 계산
    profitable_deals = df[df['profit'] > 0]
    loss_deals = df[df['profit'] < 0]
    
    print(f"수익 거래: {len(profitable_deals)}")
    print(f"손실 거래: {len(loss_deals)}")
    
    if len(df) > 0:
        win_rate = (len(profitable_deals) / len(df)) * 100
        print(f"승률: {win_rate:.2f}%")
        print(f"총 수익: {df['profit'].sum():.2f}")
        print(f"평균 수익: {df['profit'].mean():.2f}")
        
    print("===================\n")
    
def print_last_deals(count=20):
    """최근 거래 내역 출력"""
    df = get_last_deals(count)
    if df is None:
        return
        
    print("\n=== 최근 거래 내역 ===")
    for _, deal in df.iterrows():
        print(f"\n거래 시간: {deal['time']}")
        print(f"심볼: {deal['symbol']}")
        print(f"거래량: {deal['volume']:.2f}")
        print(f"가격: {deal['price']:.5f}")
        print(f"수익: {deal['profit']:.2f}")
        print(f"수수료: {deal['commission']:.2f}")
        print(f"스왑: {deal['swap']:.2f}")
        print("-" * 30)
        
    analyze_deals(df)

if __name__ == "__main__":
    try:
        print_last_deals()
    finally:
        mt5.shutdown() 