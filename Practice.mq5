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
      
//4.Handle for currency with 5 to 3 digits
//Currencies with 5 digits or 3 digits the STP AND TKP must be *10 for accuracy
STP=StopLoss;
TKP=TakeProfit;
if(_Digits==5||_Digits==3){
   STP=STP*10;
   TKP=TKP*10;
}

return(INIT_SUCCEEDED);
}
void OnDeInit(const int reason)
{
//This section or function is called when the EA is removed from the chart.
//Release indicators to save memory
IndicatorRelease(adxHandle);
IndicatorRelease(maHandle);
}


void OnTick(){

//This function process the NewTick event, which is generated when a new quote
//is received for a symbol.
//1.Check candle quantity to ensure enough activity is present
//Bars available on the chart should be more than 60.
if(Bars(_Symbol,_Period)<60)
   {
   Alert("We have less than 60 bars, EA will exit now");
   return;
   }
//2.Use the static Old_Time variable to store bar time.
//Each tick ,we will check the current bar time with the saved one.
//If the current bar time does not equal the saved bar time it indicates a new bar
static datetime Old_Time;
datetime New_Time[1];
bool IsNewBar=false;

//3.copy the last bar time to the element New_Time[0]
int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
if(copied>0)//This means that the data has been copied successfully
  {
   if(Old_Time!=New_Time[0])//Check to see if old time is equal to new time bar
   {
      IsNewBar=true;//If is not a first ,New bar has appeared
      if(MQLInfoInteger(MQL_DEBUG))Print("We have a new bar",New_Time[0],"old time was",Old_Time);
      Old_Time=New_Time[0];
   }
   
  }
   else{
   Alert("Error in copying historical time data,error = ",GetLastError());
   ResetLastError();
   return;
   }
//4.Note-EA should only check for new trade if we have a new bar
   if(IsNewBar==false)
   {
   return;
   }
//Ensure we have enough bars to work with
int Mybars= Bars(_Symbol,_Period);
   if(Mybars<60)//If bar count is less than 60
   {
   Alert("We have less than 60 bars,EA will now exit");
   return;
   }
//5.Defining MQL5 structures to be used for trades

   MqlTick latest_price; //Used for getting recent and latest price
   MqlTradeRequest mrequest; //Used for sending our trade requests
   MqlTradeResult mresult; //Used to get trade result
   MqlRates mrate[]; //used to store the prices,volumes and spread of each bar
   ZeroMemory(mrequest);// used to initialize mrequest structure
   
//6.Ensure array values for for the Rates,ADX Values and MA values
//is store serially similar to the timeseries array

//The array for the rates mrates
ArraySetAsSeries(mrate,true);
//The ADX DI+values array
ArraySetAsSeries(plsDI,true);
//The ADX DI-values array
ArraySetAsSeries(minDI,true);
//The ADX values arrays
ArraySetAsSeries(adxVal,true);
//The MA-8 values arrays
ArraySetAsSeries(maVal,true);
//7.Set all the arrays we will be using to store Bars details as series.
//Ensures that values copied into the array are indexed as timeseries.0,1,2,3(To correspond with vars index)
//---This could be done at the initialization section of our code.

//---Get the last price quote using the MQL5 MqlTick structure
if(!SymbolInfoTick(_Symbol,latest_price))
{
   Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
   return;
}
//---8.Get the details for the latest three bars
if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
   {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
   }
   
//---Note--When using CopyRate() I am storing all the information  into my mrate[])
//---To access content in array at this point, use dot notation
/*
ex
mrate[1].time // Bar 1 start time
*/
//---Copy the new values of our indicators to buffer(arrays) using the handle
   if(CopyBuffer(adxHandle,0,0,3,adxVal)<0||CopyBuffer(adxHandle,1,0,3,plsDI)<0||
      CopyBuffer(adxHandle,2,0,3,minDI)<0)
      {
      Alert ("Error copying ADX indicator Buffers - error:",GetLastError(),"!!");
      return;
      }
      if(CopyBuffer(maHandle,0,0,3,maVal)<0)
      {
      Alert("Error copying Moving Average indicator buffer- error:",GetLastError());
      return;
      }
      
      //Ensure that there are only one trade opened at a time by declaring 2 bool datatype variables
      bool Buy_opened=false;//Holds open Buy position 
      bool Sell_opened=false; //holds sell position data
      
      if(PositionSelect(_Symbol)==true)//we have an opened position
      {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
         {
          Buy_opened =true;//Its a buy
         }
         
         else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
         {
         
            Sell_opened = true;//It's a sell
            
         }
      }
   //---9.Copy the close price for the previoius bar prior to the current bar,that is Bar 1
      p_close = mrate[1].close;//bar 1 close price
      
      //--10.Check for a long setup :MA-8 increasing upward,
      //previous price close above it, ADX>22,+DI>-DI
      
      //Declare bool type variables to hold our Buy Conditions
      bool Buy_Condition_1 = (maVal[0]>maVal[1]) && (maVal[1]>maVal[2]);//MA-8 is Increasing upward
      bool Buy_Condition_2 = (p_close)>maVal[1]; //Previous price closed above MA-8
      bool Buy_Condition_3 = (adxVal[0]>Adx_Min); //current ADX value is greater than the minimum value(22)
      bool Buy_Condition_4 = (plsDI[0]>minDI[0]); //+DI greater than -DI
      
      //---Putting all together
      if(Buy_Condition_1 && Buy_Condition_2)
         {
         if(Buy_Condition_3 && Buy_Condition_4)
         {
         //Check for open buys
         if(Buy_opened)
           {
            Alert(("We already have a buy position!"));
            return;//this is so no other buys are open
           }
           mrequest.action = TRADE_ACTION_DEAL;//immediate order execution
           mrequest.price = NormalizeDouble(latest_price.ask,_Digits);//latest ask price
           mrequest.sl  = NormalizeDouble(latest_price.ask - STP*_Point,_Digits);//---stoploss
           mrequest.tp  = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits);//takeprofit
           mrequest.symbol = _Symbol;//Selects the current symbol
           mrequest.volume = Lot;//Lots to purchase
           mrequest.magic =EA_Magic;
           mrequest.type = ORDER_TYPE_BUY; //Sends buy order
           mrequest.type_filling = ORDER_FILLING_FOK;//Order execution type
           mrequest.deviation=100;//---Deviation from current price
           //Send Order
           double buyOrder= OrderSend(mrequest,mresult);
           }
           
             //get result code
               if(mresult.retcode==10009|| mresult.retcode==10008)// Either code means orders where placed successfully
                 {
                 Alert("A buy order has been successfully placed with Ticket#:" ,mresult.order,"!!");
                  
                 }
                 else
                 {
                  Alert("The buy order could not be placed-error:",GetLastError());
                  ResetLastError();
                  return;
                 }
         }
         
         //---Check for sell setup and place order for sell
         //Declare bool type variables to hold our sell conditions
         bool Sell_Condition_1 = (maVal[0]<maVal[1]) && (maVal[1]<maVal[2]);//MA-8 decreasing 
         bool Sell_Condition_2 = (p_close<maVal[1]);//Check for previous bar to close below current
         //bar
         bool Sell_Condition_3 = (adxVal[0]>Adx_Min);//Current ADX value is greater than the minimum (22)
         bool Sell_Condition_4 = (plsDI[0]<minDI[0]);//-DI greater than +DI
         
         //Completing sell process
         if(Sell_Condition_1 && Sell_Condition_2)
            {
               if(Sell_Condition_3 && Sell_Condition_4)
               
               //Check for any open sell trades
               if(Sell_opened)
               {
                  Alert("We already have a sell position");
                  return; //Don't open new trade
               }
               mrequest.action = TRADE_ACTION_DEAL; //Place trade immediately
               mrequest.price = NormalizeDouble(latest_price.bid,_Digits);//latest Bid price
               mrequest.sl = NormalizeDouble(latest_price.bid + STP*_Point,_Digits);//Stop loss
               mrequest.tp = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits);//Takeprofit
               mrequest.symbol= _Symbol; //Select current symbol
               mrequest.volume = Lot; //volume defined Lot size
               mrequest.magic = EA_Magic; //Obtain magic number
               mrequest.type = ORDER_TYPE_SELL; //Set sell order
               mrequest.type_filling = ORDER_FILLING_FOK;//Order execution type
               mrequest.deviation = 100; //Alloted deviation from current price
               //send sell order
               double sellOrder=OrderSend(mrequest,mresult);
            }
         
      //get result code
               if(mresult.retcode==10009|| mresult.retcode==10008)// Either code means orders where placed successfully
                 {
                 Alert("A buy order has been successfully placed with Ticket#:" ,mresult.order,"!!");
                  
                 }
                 else
                 {
                  Alert("The buy order could not be placed-error:",GetLastError());
                  ResetLastError();
                  return;
                 }






}
