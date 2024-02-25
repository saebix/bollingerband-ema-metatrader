//+------------------------------------------------------------------+
//|                                                    bollinger.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

input int bollingerperiod = 15;  //bollinger period
input double bollingerdeviation = 1.5; //bollinger deviation
input int fastmaperiod = 30;
input int slowmaperiod = 50;

input double Inpstoploss = 1.1;
input double Inptakeprofit = 1.6;

int bhandle,fastmahandle,slowmahandle,atrhandle;
double upperbuffer[];
double basebuffer[];
double lowerbuffer[];
double slowmabuffer[];
double fastmabuffer[];
double atrbuffer[];
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(12);
   bhandle = iBands(_Symbol,PERIOD_CURRENT,bollingerperiod,1,bollingerdeviation,PRICE_CLOSE);
   fastmahandle = iMA(_Symbol,PERIOD_CURRENT,fastmaperiod,1,MODE_EMA,PRICE_CLOSE);
   slowmahandle = iMA(_Symbol,PERIOD_CURRENT,slowmaperiod,1,MODE_EMA,PRICE_CLOSE);
   atrhandle=iATR(Symbol(),PERIOD_CURRENT,20);
   ArraySetAsSeries(upperbuffer,true);
   ArraySetAsSeries(basebuffer,true);
   ArraySetAsSeries(upperbuffer,true);
   ArraySetAsSeries(fastmabuffer,true);
   ArraySetAsSeries(slowmabuffer,true);
   ArraySetAsSeries(atrbuffer,true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
   if(bhandle!=INVALID_HANDLE){IndicatorRelease(bhandle);}
   IndicatorRelease(fastmahandle);
   IndicatorRelease(slowmahandle);
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
   if(!isNewBar()){return;}
   
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);
   int    Data=CopyRates(Symbol(), Period(),0,Bars(Symbol(),Period()),PriceInformation);
   
   double Ask =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   int values = CopyBuffer(bhandle,0,0,1,basebuffer) + CopyBuffer(bhandle,1,0,1,upperbuffer) + CopyBuffer(bhandle,2,0,1,lowerbuffer);
   
   if(values!=3){Print("fail to get buffer"); return;}
   
   CopyBuffer(fastmahandle,0,0,1,fastmabuffer);
   CopyBuffer(slowmahandle,0,0,1,slowmabuffer);
   
   CopyBuffer(atrhandle,0,0,1,atrbuffer);
   int cntsell,cntbuy;
   if(!countopenpositions(cntbuy,cntsell)){Print("faild cnt buy and sell");return;}
   
   double lastclose = PriceInformation[0].close;
   double lastatr           = NormalizeDouble( atrbuffer[0],_Digits);
   
   Comment("lastclose:",lastclose,"\nlowerbuffer: ",lowerbuffer[0],"\nfast ma: ",fastmabuffer[0],"\nslow ma: ",slowmabuffer[0],"\n",lastatr);
   
   
   
   
   if(cntbuy==0 && lastclose<=lowerbuffer[0] && fastmabuffer[0]>slowmabuffer[0])
   {
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,0.01,Ask,(Ask - lastatr*Inpstoploss),(Ask + lastatr*Inptakeprofit),NULL);
   
   }
   
   if(cntsell==0 && lastclose>=upperbuffer[0] && fastmabuffer[0]<slowmabuffer[0]){
   
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,0.01,Bid,(Bid + lastatr*Inpstoploss),(Bid - lastatr*Inptakeprofit),NULL);
   
   }
}

//+------------------------------------------------------------------+

bool isNewBar(){

   static datetime previoustime = 0;
   datetime currenttime = iTime(_Symbol,PERIOD_CURRENT,0);
   if (previoustime!=currenttime){
      previoustime = currenttime;
      return true;
   }

   return false;
}

bool countopenpositions(int &countbuy, int &countsell){


   countbuy = 0;
   countsell = 0;
   int total = PositionsTotal();
   for(int i = total-1;i>=0;i--){
      
      long type;
      ulong positionticket = PositionGetTicket(i);
      if(positionticket<=0){Print("failed to get position ticket");return false;}
      if(!PositionSelectByTicket(positionticket)){Print("failed to select ticket");return false;}
      if(!PositionGetInteger(POSITION_TYPE,type)){Print("failed to get type");return false;}
      if(type==POSITION_TYPE_BUY){countbuy++;}
      if(type==POSITION_TYPE_SELL){countsell++;}
   }
   return true;

}
