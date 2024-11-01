//+------------------------------------------------------------------+
//|                                        SocketHTTPRequest.mq5     |
//|                        Copyright 2024, Your Name                 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

input string   ServerAddress = "127.0.0.1";  // 서버 주소
input int      ServerPort = 5000;            // 서버 포트

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   // GET 요청 테스트
   TestGetRequest();
   
   // POST 요청 테스트
   TestPostRequest();
}

//+------------------------------------------------------------------+
//| GET 요청 테스트 함수                                              |
//+------------------------------------------------------------------+
void TestGetRequest()
{
   string request = "GET /webrequest_test?param1=value1&param2=value2 HTTP/1.1\r\n";
   request += "Host: " + ServerAddress + "\r\n";
   request += "Connection: close\r\n\r\n";
   
   string response = SendHTTPRequest(request);
   
   if(response != "")
   {
      Print("GET Request Result:\n", response);
   }
}

//+------------------------------------------------------------------+
//| POST 요청 테스트 함수                                             |
//+------------------------------------------------------------------+
void TestPostRequest()
{
   string post_data = "param1=value1&param2=value2";
   string request = "POST /webrequest_test HTTP/1.1\r\n";
   request += "Host: " + ServerAddress + "\r\n";
   request += "Content-Type: application/x-www-form-urlencoded\r\n";
   request += "Content-Length: " + IntegerToString(StringLen(post_data)) + "\r\n";
   request += "Connection: close\r\n\r\n";
   request += post_data;
   
   string response = SendHTTPRequest(request);
   
   if(response != "")
   {
      Print("POST Request Result:\n", response);
   }
}

//+------------------------------------------------------------------+
//| HTTP 요청 전송 및 응답 수신 함수                                   |
//+------------------------------------------------------------------+
string SendHTTPRequest(string request)
{
   int socket = SocketCreate();
   
   if(socket != INVALID_HANDLE)
   {
      if(SocketConnect(socket, ServerAddress, ServerPort, 5000))
      {
         char req[];
         int len = StringToCharArray(request, req) - 1;
         if(SocketSend(socket, req, len) == len)
         {
            char rsp[];
            string response = "";
            int timeout = 5000;
            uint start_time = GetTickCount();
            
            do
            {
               int bytes = SocketIsReadable(socket);
               if(bytes > 0)
               {
                  ArrayResize(rsp, bytes);
                  int received = SocketRead(socket, rsp, bytes, timeout);
                  if(received > 0)
                  {
                     response += CharArrayToString(rsp, 0, received);
                  }
               }
            }
            while(!IsStopped() && GetTickCount() - start_time < timeout);
            
            SocketClose(socket);
            return response;
         }
         else
         {
            Print("Failed to send request. Error code: ", GetLastError());
         }
      }
      else
      {
         Print("Connection failed. Error code: ", GetLastError());
      }
      SocketClose(socket);
   }
   else
   {
      Print("Socket creation failed. Error code: ", GetLastError());
   }
   
   return "";
}