# MQL5_ea_ADXandMA_mql5
Expert Advisor with ADXandMA based params
EA ARTICLE NOTES
Article name "Step-By-Step Guide to writing a Expert Advisor.

--double is used to store floating point constants,which contains 
an integer part, a decimal point, and a franction part.

-The Lot to trade is stored in the Lot variable name.
-The adxHandle is to be used to store the ADX indicator, while the maHandle is used to store 
the handle for the Moving average indicator for each bar on the chart.

-The maVal[] is a dynamic array that will hold the values of the Moving Average indicator for each bar on the chart.

-p_close isa variable we will use to store the Close price for the bar we are going to monitor for checking our Buy/Sell trades.

- STP and TKP are going to be used to store the Stoploss and the Take profit values in our EA.

-The plsDI[],minDI[],adxVal[] are dynamic arrays that will hold the values of +DI,-DI and main ADX(of the ADX
indicator) for each bar on the chart.

--Dynamic arrays- this is an array declared without a dimension. Or, no values are specified in the pair of square brackets.
-Static arrays - this is an array that has it's dimensions defined at the point of declaration.
 
Example of a Static array
double allbars[20];//This will take 20 elements

