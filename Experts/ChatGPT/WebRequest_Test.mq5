//+------------------------------------------------------------------+
//|                                              WebRequest_Test.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. 서버에 보낼 JSON 데이터
   string json_data = "{\"symbol\": \"BTCUSD\", \"period\": 30}";

   // 2. 서버 URL 설정
   string server_url = "http://127.0.0.1:5000/api/trading-decision";  // 로컬 서버 URL

   // 3. Content-Type 헤더 설정 (문자열로 명확히 설정)
   string headers = "Content-Type: application/json\r\n";  // 정확한 Content-Type 설정

   // 4. WebRequest를 사용하여 서버로 POST 요청 보내기
   char post_data[];                        
   StringToCharArray(json_data, post_data);  // JSON 데이터를 Char 배열로 변환

   char result[];        // 응답 데이터를 받을 배열
   string result_headers;  // 응답 헤더를 저장할 문자열
   int timeout = 5000;    // 타임아웃 5초

   // WebRequest 호출
   int response_code = WebRequest(
       "POST",            // 메서드
       server_url,        // URL
       headers,           // 헤더 (문자열로 전달)
       "",                // 쿠키 (사용하지 않음)
       timeout,           // 타임아웃
       post_data,         // 보내는 데이터 (JSON)
       ArraySize(post_data),  // 데이터 크기
       result,            // 응답 데이터를 받을 배열
       result_headers     // 응답 헤더를 저장할 문자열
   );
   
   // 5. 응답 코드 확인 및 처리
   if (response_code != 200)  // 응답 코드가 200이 아닐 경우 오류 출력
     {
      Print("서버 요청 실패: 응답 코드 ", response_code);
      return INIT_FAILED;
     }

   // 6. 서버 응답을 처리하여 출력
   string response = CharArrayToString(result);  // 응답 데이터를 문자열로 변환
   Print("서버 응답: ", response);  // 응답 출력

   return INIT_SUCCEEDED;
  }




//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
