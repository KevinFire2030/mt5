#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <FxPro/vTrader.mqh>

CvTrader* trader = NULL;

int OnInit() {
    trader = new CvTrader(Symbol());
    return trader.Init() ? INIT_SUCCEEDED : INIT_FAILED;
}

void OnDeinit(const int reason) {
    if(trader != NULL) {
        delete trader;
        trader = NULL;
    }
}

void OnTick() {
    if(trader != NULL) trader.OnTick();
}
