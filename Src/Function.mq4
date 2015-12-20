//+------------------------------------------------------------------+
//| Re-Calculate LotSize function                                    |
//| Ex. Lots = reLotSize(Lots, true);                                |
//| Call Before make any new ordersend                               |
//+------------------------------------------------------------------+
double reLotSize(double currLotSize, bool decreaseFlag){
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