//+------------------------------------------------------------------+
//|                                                EA_SMA_001.mq4    |
//|                                                       Espanoh    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Espanyoh"
#property link      "hotyoh@gmail.com"

extern double lotSize=0.1;  
extern int    magicNumber=100002;

extern bool UseMoveToBE=false;
extern int WhenToMoveToBE=20;
extern int PipsToLockIn=5;

extern bool adjustLotSize=true;
extern bool UserCandleTrail=false;
extern double PadAmount=10;

extern bool UseTrailingStop=false;
extern int WhenToTrail=20;
extern int TrailAmount=20;

extern int SlowMA = 25;
extern int SlowMaShift = 0;
extern int SlowMaMethod = MODE_SMA;
extern int SlowMaAppliedTo = 0;

extern int FastMA = 5;
extern int FastMaShift = 0;
extern int FastMaMethod = MODE_SMA;
extern int FastMaAppliedTo = 0;


extern int TakeProfit = 50;
extern int StopLoss = 20;
extern int threshold = 1;
double pips;
        
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
int deinit(){
   return(0);
}

void OnTick(){
   if(OpenOrdersThisPair(Symbol())>0){
      if(UseMoveToBE) MoveToBE();
      if(UseTrailingStop) AdjustTrail();
   }
   if(IsNewCandle()){
      CheckForMaTrade();
   }
}


void CheckForMaTrade(){
   double PreviousFast = iMA(NULL, 0, FastMA, FastMaShift, FastMaMethod, FastMaAppliedTo, 2);
   double CurrentFast  = iMA(NULL, 0, FastMA, FastMaShift, FastMaMethod, FastMaAppliedTo, 1);
   double PreviousSlow = iMA(NULL, 0, SlowMA, SlowMaShift, SlowMaMethod, SlowMaAppliedTo, 2);
   double CurrentSlow  = iMA(NULL, 0, SlowMA, SlowMaShift, SlowMaMethod, SlowMaAppliedTo, 1);
   printf("CheckForMaTrade : " +PreviousFast+"," + CurrentFast +"," + PreviousSlow +"," + PreviousSlow );
   
   if(PreviousFast<PreviousSlow && CurrentFast>CurrentSlow
      && CurrentFast-PreviousSlow > threshold*pips)
      OrderEntry(0);
   if(PreviousFast>PreviousSlow && CurrentFast<CurrentSlow
      && CurrentSlow-CurrentFast > threshold*pips)
      OrderEntry(1);
}

void OrderEntry(int diretion){
   printf("Call open order : direction ==> "+diretion);
   if(OpenOrdersThisPair(Symbol()) > 0) {
      return;
   }
   lotSize = reLotSize(lotSize, adjustLotSize, true);
   
   printf("Call open order : current order ==> "+OpenOrdersThisPair(Symbol()));
   if(diretion == 0){
      double bsl=0;
      double btp=0;
      if(StopLoss!=0) bsl=Ask-(StopLoss*pips);
      if(TakeProfit==0) btp=Ask+(TakeProfit+pips);
      
      int buyticket =0;
      if(OpenOrdersThisPair(Symbol()) == 0) 
      OrderSend(NULL, OP_BUY, lotSize, Ask, 3, Ask-(StopLoss*pips), Ask+(TakeProfit*pips), NULL, magicNumber, 0, Green);
   }

   if(diretion == 1){
      double ssl=0;
      double stp=0;
      if(StopLoss!=0) ssl=Bid+(StopLoss*pips);
      if(TakeProfit!=0) stp=Bid-(TakeProfit+pips);
      
      int sellticket =0;
      if(OpenOrdersThisPair(Symbol()) == 0) 
         OrderSend(NULL, OP_SELL, lotSize, Bid, 3, Bid+(StopLoss*pips), Bid-(TakeProfit*pips), NULL, magicNumber, 0, Red);
   }
}


int OpenOrdersThisPair(string pair){
   int total=0;
   for(int i=OrdersTotal()-1; i>=0; i--){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==pair) 
         total++;
   }
   return (total);
}

void  MoveToBE(){
   //Buy Order section
   for (int b=OrdersTotal()-1;b>=0;b--){
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == magicNumber)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_BUY)
                  if(Bid-OrderOpenPrice() > WhenToMoveToBE*pips){
                     if(OrderOpenPrice()>OrderStopLoss()){
                        printf("[MoveToBE]");
                        OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()+(PipsToLockIn*pips), OrderTakeProfit(), 0, CLR_NONE);
                      }
                  }
    }
    
   //Sell Order section
   for (int s=OrdersTotal()-1;s>=0;s--){
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == magicNumber)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_SELL)
                  if(OrderOpenPrice()-Ask > WhenToMoveToBE*pips)
                     //if(OrderStopLoss() > Ask + pips*TrailAmount || OrderStopLoss()==0)
                     if(OrderOpenPrice()<OrderStopLoss())
                        OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()-(PipsToLockIn*pips), OrderTakeProfit(), 0, CLR_NONE);
    }
   
}

void AdjustTrail(){


   //Buy Order section
   for (int b=OrdersTotal()-1;b>=0;b--){
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == magicNumber)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_BUY)
                  if(UserCandleTrail){
                     if(IsNewCandle())
                        if(OrderStopLoss()< Low[1]-PadAmount*pips)
                           OrderModify(OrderTicket(), OrderOpenPrice(), Low[1]-PadAmount*pips, OrderTakeProfit(), 0, CLR_NONE);
                  }else{
                     if(Bid-OrderOpenPrice() > WhenToTrail*pips)
                        if(OrderStopLoss() < Bid - pips*TrailAmount)  {
                           printf("[AdjustTrail]");
                           OrderModify(OrderTicket(), OrderOpenPrice(), Bid-(pips*TrailAmount), OrderTakeProfit(), 0, CLR_NONE);
                        }
                  }
    }
    
   //Sell Order section
   for (int s=OrdersTotal()-1;s>=0;s--){
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == magicNumber)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_SELL)
                  if(UserCandleTrail){
                     if(OrderStopLoss()> High[1]+PadAmount*pips)
                           OrderModify(OrderTicket(), OrderOpenPrice(), High[1]+PadAmount*pips, OrderTakeProfit(), 0, CLR_NONE);
                  }else{
                     if(OrderOpenPrice()-Ask > WhenToTrail*pips)
                        if(OrderStopLoss() > Ask + pips*TrailAmount || OrderStopLoss()==0)
                           OrderModify(OrderTicket(), OrderOpenPrice(), Ask +(pips*TrailAmount), OrderTakeProfit(), 0, CLR_NONE);
                  }
    }
 }

bool IsNewCandle(){
   static int BarsOnChart=0;
   if (Bars == BarsOnChart)
      return false;
   BarsOnChart = Bars;     
   return true;
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