#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"
#property strict

#include <JAson.mqh>

// 서버 URL 설정
string server_url = "http://127.0.0.1:5000/ask";

// LLM에 질문하는 함수
string AskLLM(string question)
{
    string headers = "Content-Type: application/json\r\n";
    char post[], result[];
    string escaped_question = StringReplace(question, "\\", "\\\\");
    escaped_question = StringReplace(escaped_question, "\"", "\\\"");
    string post_data = "{\"question\":\"" + escaped_question + "\"}";
    StringToCharArray(post_data, post, 0, StringLen(post_data), CP_UTF8);
    
    ResetLastError();
    Print("Sending request with data: ", post_data);
    
    string result_headers;
    int res = WebRequest("POST", server_url, headers, 5000, post, result, result_headers);
    
    if(res == -1)
    {
        int error_code = GetLastError();
        Print("Error in WebRequest. Error code =", error_code);
        if(error_code == 4014)
            MessageBox("Add the address '" + server_url + "' to the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION);
        return "오류 발생: " + IntegerToString(error_code);
    }
    else
    {
        if(res == 200)
        {
            string response = CharArrayToString(result, 0, -1, CP_UTF8);
            Print("서버 응답: ", response);
            
            CJAVal json;
            if(json.Deserialize(response))
            {
                return json["answer"].ToStr();
            }
            else
            {
                return "JSON 파싱 오류";
            }
        }
        else
        {
            return "HTTP 오류: " + IntegerToString(res);
        }
    }
}

// 프로그램 시작점
void OnStart()
{
    string user_question = "MQL5에 대해 간단히 설명해주세요.";
    Print("질문: ", user_question);
    
    string answer = AskLLM(user_question);
    Print("답변: ", answer);
}