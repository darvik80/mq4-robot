//+ – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – + //| MyFirstEA.mq4 |
//| Copyright 2017, |
//+ – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – +
#property copyright "Copyright 2019"
#property version "1.00"
#property strict
//+ – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – +
sinput string tt = "Trade Settings";
input double Lot = 0.01;
input int TakeProfit = 300;
input int StopLoss = 300;
input int Slippage = 30;
sinput string en = "Envelopes Properties";
input int period = 14;
input double deviation=0.10;
sinput string zz = "ZZ Properties";
input int Depth = 12;
input int Deviation= 5;
input int BackStep = 3;
input int Magic = 254521;
double enveUP, enveDW, ZZ;
datetime open;

int OnInit() {
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
    if (Open[0] != open) {
        enveUP = iEnvelopes(NULL, 0, period, MODE_SMA, 10, PRICE_CLOSE, deviation, MODE_UPPER, 1);
        enveDW = iEnvelopes(NULL, 0, period, MODE_SMA, 10, PRICE_CLOSE, deviation, MODE_LOWER, 1);
        ZZ = iCustom(Symbol(), 0, "ZigZag", Depth, Deviation, BackStep, 0, 1);
        if (enveUP > 0 && enveDW > 0 && ZZ > 0) {
            open = Open[0];
        }
    }

    if (CountTrades(OP_BUY, Magic) == 0 && Ask < enveDW && ZZ < enveDW) {
        OpenOrders(OP_BUY, Lot);
    }

    if (CountTrades(OP_SELL, Magic) == 0 && Bid > enveUP && ZZ > enveUP) {
        OpenOrders(OP_SELL, Lot);
    }

    if (CountTrades(OP_BUY, Magic) > 0 && Bid > enveUP) {
        CloseOrders(OP_BUY, Magic);
    }

    if (CountTrades(OP_SELL, Magic)> 0 && Ask <enveDW) {
        CloseOrders(OP_SELL, Magic);
    }
 }

int CountTrades(int type, int magic) {
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == Symbol() && (OrderType() == type || type == -1) && (OrderMagicNumber() == magic || magic == -1)) {
                count++;
            }
        }
    }

    return count;
 }

void OpenOrders(int type, double lot) {
    if (type != OP_BUY && type != OP_SELL) {
        return;
    }

    int ticket;
    double price = 0.0;

    if (type == OP_BUY) {
        price = Ask;
    } else if (type == OP_SELL) {
        price = Bid;
    }

    if (price <= 0) {
        return;
    }

    ticket = OrderSend(Symbol(), type, lot, price, Slippage, 0, 0, "", Magic, 0, clrLimeGreen);
    if (ticket > 0) {
        //Устанавливаем Стоп-лосс и Тейк-профит для Бай-ордера
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            double sl = 0.0, tp = 0.0;
            if (type == OP_BUY) {
                sl = OrderOpenPrice() - (StopLoss * _Point);
                sl = NormalizeDouble(sl, _Digits);
                tp = OrderOpenPrice() + (TakeProfit * _Point);
                tp = NormalizeDouble(tp, _Digits);
            } else if (type == OP_SELL) {
                sl = OrderOpenPrice() + (StopLoss * _Point);
                sl = NormalizeDouble(sl, _Digits);
                tp = OrderOpenPrice() - (TakeProfit * _Point);
                tp = NormalizeDouble(tp, _Digits);
            }

            bool mod = false;
            int count = 0;
            while (!mod) {
                mod = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, clrYellow);
                count++;
                if (count >= 100) {
                    mod = true;
                    break;
                }
            }
        }
    }
}

bool CloseOrders(int type, int magic) {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderMagicNumber() == magic || magic == -1) {
                if (OrderSymbol() == Symbol() && (OrderType () == type || type == -1)) {
                    if (OrderType() == OP_BUY) {
                        return OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrAqua);
                    } else if (OrderType() == OP_SELL) {
                        return OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrAqua);
                    }
                }
            }
        }
    }

    return false;
}
//+ – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – — – +