//+------------------------------------------------------------------+
//| Expert Advisor: XAUUSD Candlestick Bot                          |
//| Description: Trading based on candlestick pattern, ADX, RSI     |
//| Platform: MetaTrader 5 (MT5)                                    |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

// Input Parameters
input double RiskPercentage = 2.0; // Risiko per trade dalam persen dari equity
input int ATR_Period = 14;
input double ATR_Multiplier = 1.5;
input int ADX_Period = 14;
input double ADX_Threshold = 25;
input int RSI_Period = 14;
input double RSI_Overbought = 70;
input double RSI_Oversold = 30;
input int TimeFrameConfirmation = PERIOD_H1;
input double TP_Multiplier = 2.0; // Take Profit multiplier

// Function to check candlestick pattern
bool IsBullishEngulfing()
{
   if(Close[1] < Open[1] && Close[0] > Open[0] && Close[0] > Open[1] && Open[0] < Close[1])
      return true;
   return false;
}

bool IsBearishEngulfing()
{
   if(Close[1] > Open[1] && Close[0] < Open[0] && Close[0] < Open[1] && Open[0] > Close[1])
      return true;
   return false;
}

// Function to get ADX value
double GetADX()
{
   return iADX(_Symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
}

// Function to get RSI value
double GetRSI()
{
   return iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE, 0);
}

// Function to get ATR-based Stop Loss and Take Profit
double GetATRStopLoss()
{
   return iATR(_Symbol, PERIOD_CURRENT, ATR_Period, 0) * ATR_Multiplier;
}

double GetATRTakeProfit()
{
   return GetATRStopLoss() * TP_Multiplier;
}

// Function to calculate dynamic lot size based on equity
double CalculateLotSize()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = (equity * RiskPercentage) / 100.0;
   double sl = GetATRStopLoss();
   if (sl <= 0) return 0.01; // Default lot size jika SL nol atau tidak valid
   double lotSize = riskAmount / sl / 10.0;
   return NormalizeDouble(lotSize, 2); // Menyesuaikan presisi lot size
}

// Function to check higher timeframe confirmation
bool IsTrendConfirmed()
{
   double maCurrent = iMA(_Symbol, PERIOD_CURRENT, 35, 0, MODE_SMA, PRICE_CLOSE, 0);
   double maHigher = iMA(_Symbol, TimeFrameConfirmation, 35, 0, MODE_SMA, PRICE_CLOSE, 0);
   return (maCurrent > maHigher);
}

// Function to execute trades
void ExecuteTrade()
{
   double adx = GetADX();
   double rsi = GetRSI();
   double sl = GetATRStopLoss();
   double tp = GetATRTakeProfit();
   double lotSize = CalculateLotSize();
   
   if(adx > ADX_Threshold)
   {
      if(IsBullishEngulfing() && rsi < RSI_Oversold && IsTrendConfirmed())
      {
         trade.Buy(lotSize, _Symbol, Ask, 0, Bid - sl, Ask + tp, "Buy XAUUSD");
      }
      else if(IsBearishEngulfing() && rsi > RSI_Overbought && !IsTrendConfirmed())
      {
         trade.Sell(lotSize, _Symbol, Bid, 0, Ask + sl, Bid - tp, "Sell XAUUSD");
      }
   }
}

// Expert Advisor OnTick function
void OnTick()
{
   ExecuteTrade();
}
