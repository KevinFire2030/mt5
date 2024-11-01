//+------------------------------------------------------------------+
//| TestWebRequest.mq5                                             |
//|                        Copyright 2024, Your Name                |
//|                                       https://www.example.com    |
//+------------------------------------------------------------------+
input string serverUrl = "http://localhost:8080"; // 서버 URL

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    string jsonData = "{\"chart_data\": []}"; // 요청할 JSON 데이터
    string decision = GetAIDecision(jsonData);
    Print("Decision received from server: ", decision);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| AI 결정 요청 함수                                               |
//+------------------------------------------------------------------+
string GetAIDecision(string jsonData)
{
    string headers = "Content-Type: application/json\r\n";
    char postData[];
    StringToCharArray(jsonData, postData); // JSON 데이터를 char 배열로 변환
    char result[];
    string resultString;

    // WebRequest 함수 호출
    int res = WebRequest("POST", serverUrl, headers, 10, postData, result, resultString);

    // 오류 처리
    if (res == 0)
    {
        Print("WebRequest failed: ", GetLastError());
        return "hold"; // 오류 발생 시 기본값 반환
    }

    // 응답 출력
    Print("Response from server: ", resultString); // 전체 응답 출력
    return ParseJsonDecision(resultString);
}

//+------------------------------------------------------------------+
//| JSON 응답에서 결정 필드 추출 함수                               |
//+------------------------------------------------------------------+
string ParseJsonDecision(string jsonResponse)
{
    Print("Raw JSON response: ", jsonResponse); // 원본 JSON 응답 출력

    // JSON 응답에서 "decision" 필드를 추출
    string decision = "";
    int startPos = StringFind(jsonResponse, "\"decision\":\"");
    if (startPos != -1)
    {
        startPos += StringLen("\"decision\":\"");
        int endPos = StringFind(jsonResponse, "\"", startPos);
        if (endPos != -1)
        {
            decision = StringSubstr(jsonResponse, startPos, endPos - startPos);
        }
    }
    return decision;
}

//+------------------------------------------------------------------+
