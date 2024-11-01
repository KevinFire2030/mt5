#include <Object.mqh>

struct STradeParams {
    ENUM_POSITION_TYPE type;
    double volume;
    double sl;
    double tp;
    
    void Clear() {
        type = POSITION_TYPE_BUY;
        volume = 0.0;
        sl = 0.0;
        tp = 0.0;
    }
};

class CPosition : public CObject {
public:
    ulong ticket;
    ENUM_POSITION_TYPE type;
    double volume;
    double price;
    double sl;
    double tp;
    datetime openTime;
    
    CPosition() {
        ticket = 0;
        type = POSITION_TYPE_BUY;
        volume = 0.0;
        price = 0.0;
        sl = 0.0;
        tp = 0.0;
        openTime = 0;
    }
}; 