#include "FinalProject.h"
//#include "printf.h"

configuration FinalProjectAppC{}
implementation {
	components MainC, FinalProjectC as App;
	components new AMSenderC(AM_RADIO_COUNT_MSG); 
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components new TimerMilliC() as timer1;
	components new TimerMilliC() as timerACK ; //ACK
	components ActiveMessageC;
	components RandomC;
	
	//components for printf
	//components PrintfC;
  	//components SerialStartC;
	
	App.Boot -> MainC.Boot;
  
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	
	App.MilliTimer -> timer1;
	App.MilliTimerACK -> timerACK;
	App.Packet -> AMSenderC;
	App.Random -> RandomC;	

}
