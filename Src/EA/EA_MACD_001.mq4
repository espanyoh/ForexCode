//+------------------------------------------------------------------+
//|                                                 MACD_TEST.mq4    |
//|                                                       Espanoh    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Espanyoh"
#property link      "hotyoh@gmail.com"

extern double Lots=0.1;  
extern double TrailingStop=20;
extern int    MACD_level=500;//25; //(1-12)
extern int    MAGIC=100001;
extern int    tp_limit=100;//60;
int gap=1;
extern int wait_time_b4_SL=10000;

extern int TakeProfit = 50;
extern int StopLoss = 10;
double pips;

int      trend=0,last_trend=0, pending_time, ticket, total, pace, tp_cnt;
bool     sell_flag, buy_flag, find_highest=false, find_lowest=false;
double   MACD_Strength=0;
         
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  { 
  pips = getPips();
   return(0);
  }

//+------------------------------------------------------------------+
//| expert de-initialization function                                   |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| MACD function derives the value of MACD with default settings    |
//+------------------------------------------------------------------+
int best_deal()
  {
   double MACDSignal1,MACDSignal2;
   
   MACDSignal2=iMA(NULL,PERIOD_M1,MACD_level,0,MODE_EMA,Close[0],0)-iMA(NULL,PERIOD_M1,MACD_level+1,0,MODE_EMA,Close[0],0);
   MACDSignal1=iMA(NULL,PERIOD_M1,MACD_level,0,MODE_EMA,Close[gap],gap)-iMA(NULL,PERIOD_M1,MACD_level+1,0,MODE_EMA,Close[gap],gap);

   if ((find_highest && Close[0]>OrderOpenPrice()+Point*5) && MACDSignal2<MACDSignal1)
     { find_highest=false; return (1); } 
   
   else if ((find_lowest && Close[0]<OrderOpenPrice()-Point*5) && MACDSignal2>MACDSignal1)
     { find_lowest=false; return (1); } 
  
   return (0);
  }
//+--------------------------------------------------------------------------------+
int MACD_Direction ()
  {
  //printf("MACD_Direction call");
   double MACDSignal1,MACDSignal2,ind_buffer1[100], Signal1, Signal2;
   
   //MACDSignal2=iMA(NULL,0,12,0,MODE_EMA,Close[0],0)-iMA(NULL,0,26,0,MODE_EMA,Close[0],0);
   //MACDSignal1=iMA(NULL,0,12,0,MODE_EMA,Close[gap],gap)-iMA(NULL,0,26,0,MODE_EMA,Close[gap],gap);
   
   MACDSignal2=iMA(NULL,0,12,0,0,Close[0],0)-iMA(NULL,0,26,0,MODE_EMA,Close[0],0);
   MACDSignal1=iMA(NULL,0,12,0,0,Close[gap],gap)-iMA(NULL,0,26,0,MODE_EMA,Close[gap],gap);

   MACD_Strength=MACDSignal2-MACDSignal1; if (MACD_Strength<0) MACD_Strength=MACD_Strength*(-1);

   if(MACDSignal1<0) return (-1); 
   if(MACDSignal1>0) return (1); 
   else return (0);  
  }
  
  
//+--------------------------------------------------------------------------------+
//| ClosePending function closes the open order (mainly due to stoploss condition) |
//+--------------------------------------------------------------------------------+
void ClosePending()
 {
     if(OrderType()<=OP_SELL && OrderSymbol()==Symbol()) 
        {
          if(OrderType()==OP_BUY)
             {  
               OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
               pending_time=0; 
             }  
          else
             {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); 
               pending_time=0; 
             }  
        }
 }
//+------------------------------+
//| The main start function      |
//+------------------------------+
void do_order(int type) {
   Lots = reLotSize(Lots, true, true);
   
   if (type==1){
      ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(StopLoss*pips), Ask+(TakeProfit*pips),"PM",MAGIC,0,White);
      //ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"PM",MAGIC,0,White); // buy
      buy_flag=false;
      find_highest=true;
   }else if (type==2){
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(StopLoss*pips), Bid-(TakeProfit*pips),"PM",MAGIC,0,Red);   
      //ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"PM",MAGIC,0,Red);
      sell_flag=false;
      find_lowest=true;  
   }
             
   if(ticket>0){
      pace=tp_limit; 
      tp_cnt=0; 
      pending_time=0; 
   }
 }

//+------------------------------+
//| The main start function      |
//+------------------------------+
int trailing_stop(int type)
 {
     pace++;
     if(TrailingStop>0 && type==1 && pace>tp_limit && tp_cnt<tp_limit) // check for trailing stop value
        { 
         if(Bid-OrderOpenPrice()>Point*TrailingStop)
          { 
           if(OrderStopLoss()<Bid-Point*TrailingStop)
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
             pace=0; tp_cnt++; pending_time=0; return (1);
            }
          }
        }

     else if(TrailingStop>0 && type==2 && pace>tp_limit && tp_cnt<tp_limit)
        { 
         if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
          { 
           if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
             pace=0; tp_cnt++; pending_time=0; return (1); 
            }
          }
        }
   if (TrailingStop>0 && tp_cnt>=tp_limit) ClosePending();
 }

int start()
  {
   //printf("start");
   int count; 

   if(Bars<100) {  Print("bars less than 100"); return(0); } 

   last_trend=trend;
   trend=MACD_Direction();
   
   total=OrdersTotal(); 

   for(count=0;count<total;count++) 
      {
         pending_time++;
         OrderSelect(count, SELECT_BY_POS, MODE_TRADES);
         if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
            {  
               if(OrderType()==OP_BUY) 
                  {  
                     trailing_stop(1);

                     if (trend<0 && last_trend>0 && Close[0]>OrderOpenPrice()+Point*5) 
                        { 
                           ClosePending(); return (0);
                        } 

                     if (best_deal()==1)
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_highest=false;
                           return (0);
                        } 

                     if (find_highest && pending_time>wait_time_b4_SL && Close[0]<=OrderOpenPrice()+Point*(pending_time-wait_time_b4_SL))
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_highest=false;
                           return (0);
                        } 
                  }
                else 
                  { 
                     trailing_stop(2);

                     if (trend>0 && last_trend<0 && Close[0]<OrderOpenPrice()-Point*5) 
                        { 
                           ClosePending(); return (0);
                        } 

                     if (best_deal()==1)
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_lowest=false;
                           return (0);
                        } 

                     if (find_lowest && pending_time>wait_time_b4_SL && Close[0]>=OrderOpenPrice()-Point*(pending_time-wait_time_b4_SL))
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_lowest=false;
                           return (0);
                        } 
                   }
             }
        return (0);
      }
   //printf("trend : "+trend+", last_trend : "+last_trend);
   if (trend>0 && last_trend<0 /*&& MACD_Strength>Point*0.001*/)  
         { buy_flag=true; sell_flag=false; last_trend=trend; }

   else if (trend<0 && last_trend>0 /*&& MACD_Strength>Point*0.001*/)  
         { sell_flag=true; buy_flag=false; last_trend=trend; }

   //printf("sell_flag : "+sell_flag+", buy_flag : "+buy_flag);
   if (sell_flag==true || buy_flag==true)
     { 
      if (buy_flag==true) do_order(1); 
      if (sell_flag==true) do_order(2); 
     }     
 }



//+------------------------------------------------------------------+
//| Re-Calculate LotSize function                                    |
//| Ex. Lots = reLotSize(Lots, true, true);                          |
//+------------------------------------------------------------------+
double reLotSize(double currLotSize, bool recalculateFlag, bool decreaseFlag){
   if(!recalculateFlag)
      return currLotSize;

   double balance = AccountBalance();
   double newLotSize = DoubleToStr(AccountBalance()/1000, 2);
   if(decreaseFlag){
      return newLotSize;
   }else{
      if(newLotSize > currLotSize) 
         return newLotSize;
      else 
          return currLotSize;
   }
}

//+------------------------------------------------------------------+
//| Set PIP in firs time function                                    |
//| Ex. pips = getPips();                                            |
//+------------------------------------------------------------------+
double getPips(){
   double tickSize = MarketInfo(NULL, MODE_TICKSIZE);
   if(tickSize == 0.00001 || tickSize == 0.001)
      return tickSize *10;
   else
      return tickSize;
 }