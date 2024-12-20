
int OnInit()
{
   // 1. 서버에 보낼 URL 및 데이터 설정
   string url = "http://127.0.0.1:5000/api/trading-decision";  // Flask 서버 URL
   string postData = "{\"key\":\"value\"}";                    // 전송할 JSON 데이터
   string headers = "Content-Type: application/json\r\n";      // 헤더 설정

   char charResult[1024];    // 응답 데이터를 받을 배열
   string result_headers;    // 응답 헤더를 저장할 문자열
   int timeout = 5000;       // 타임아웃 설정 (5초)

   // postData를 char 배열로 변환 (문자열 데이터를 Char 배열로 변환)
   char post_data_array[];
   StringToCharArray(postData, post_data_array);

   // 2. WebRequest 함수 호출 (첫 번째 오버로드 사용)
   int result = WebRequest(
       "POST",                  // HTTP 메서드 (POST)
       url,                     // 요청할 URL
       headers,                 // 헤더 문자열
       NULL,                    // 쿠키 (NULL로 설정)
       timeout,                 // 타임아웃 (5초)
       post_data_array,         // 보낼 데이터 (Char 배열)
       ArraySize(post_data_array) - 1,  // 데이터 크기
       charResult,              // 응답 데이터를 받을 배열
       result_headers           // 응답 헤더를 저장할 문자열
   );

   // 3. 응답 코드가 200인지 확인하여 처리
   if (result == 200) 
   {
       string response = CharArrayToString(charResult);  // 응답 데이터를 문자열로 변환
       Print("서버 응답: ", response);  // 서버 응답 출력
   }
   else
   {
       Print("WebRequest error: ", result);  // 오류 코드 출력
   }

   return(INIT_SUCCEEDED);
}
