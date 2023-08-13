//+------------------------------------------------------------------+
//|                                                     Practice.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input char StopLoss=30;          //Stop loss
input char TakeProfit=100;       //Take profit
//indicator parameters
input char MA_Period=8;          //Moving Average Period
input char ADX_Period=8;         //ADX Period
input uchar EA_Magic=123;       //Magic number
input double Adx_Min=22.0;     //Minimum ADX Value
input double Lot=0.1;           //Lots to trade
int adxHandle;                 // handle for our ADX indicator
int maHandle;                 // handle for our Moving Average indicator
double plsDI[],minDI[],adxVal[];//Dynamic arrays to hold the values of +DI,-DI,and ADX values for each bar
double maVal[];               //Dynamic array to hold the values of Moving Average for each bar
double p_close;               //Variable to store the close value of a bar
int STP,TKP;                  //Used for stoploss and takeprofit values


int OnInit()
{
//EA initilization function.First function called when EA is launched or attached
//to a chart and it is called once.This section is the best place to make some important
/*
We can decide to know if the chart has enough bars for our indicators.
*/

//1.Get handle for ADX indicator.
adxHandle= iADX(_Symbol,0,ADX_Period);
//2.Get handle for MA indicator.
maHandle= iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
//3.Check if the handle returns an invalid handle.
   if(adxHandle<0||maHandle<0)
      {
      Alert("Error Creating handle for indicators-error:",GetLastError(),"!!");
      }

return(0);
}
void OnDeInit(const int reason)
{
//This section or function is called when the EA is removed from the chart.
}


void OnTick(){

//This function process the NewTick event, which is generated when a new quote
//is received for a symbol.


}