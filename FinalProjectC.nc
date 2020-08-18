#include "Timer.h"
#include "FinalProject.h"
#include "printf.h"

module FinalProjectC @safe(){
	uses {
	 	interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface SplitControl as AMControl;
    	interface Packet;	
    	interface Random;		
	}
}
implementation {
	message_t packet;
	bool locked;
	
	event void Boot.booted() {
		call AMControl.start();
	}
	
	
	event void AMControl.startDone(error_t err) {
	    if (err == SUCCESS) {
			switch (TOS_NODE_ID)
			{
				//sensor node 1
				case 1:
					call MilliTimer.startPeriodic(PERIOD_NODE_1);
				break;
				//sensor node 2
				case 2:
					call MilliTimer.startPeriodic(PERIOD_NODE_2);
				break;
				//sensor node 3
				case 3:
					call MilliTimer.startPeriodic(PERIOD_NODE_3);
				break;
				
				//4 --> gateway
				//5 --> Network Server
				default:
				break;
			}	    	
	    }
	    else {
	      call AMControl.start();
	    }
	}
  
  
	event void AMControl.stopDone(error_t err) {
    	//
	}
	
  
	event void MilliTimer.fired(){	
		printf("Timer FIRED \n");
		printfflush();	  
		
		if(locked){
	  		return;
	  	}
	  	else {
		radio_count_msg_t* rcm =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	  
	  	if(rcm==NULL){
	  		return;	
	  	}
	  	
	  	rcm->value=call Random.rand16() % 100;
	  	rcm->nodeid=TOS_NODE_ID;
	  	
	  	printf("Sent%u,%u \n",rcm->nodeid,rcm->value);
	 	printfflush();
	 	
	 	
	  	
	  	if(call AMSend.send(4,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO
	  		locked=TRUE;	
	  	}	
	  		
		}
		
	}
	
	
	//locked set to FALSE
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr) {
		  locked = FALSE;
		}
 	}
 	
 	
 	//Receive packet Gateway
 	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
 	 	
 	 	if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
 	 	
	 	else {
	 		
      		radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      		
      		printf(" %u %u\n",rcm->nodeid,rcm->value );
	 	 	printfflush();	 
	 	 	
		//-------------------__resending to Network server__--------------------------------------------------------------------------
	 	 	if(TOS_NODE_ID==4 ){
	 	 	
		 	 	if(locked){
		  			return bufPtr;
		  		}
			  	else {
					radio_count_msg_t* rcm_new =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	  
				  	if(rcm==NULL){
				  		return bufPtr;	
			  	}
			  	
			  	rcm_new->value=rcm->value;
			  	rcm_new->nodeid=rcm->nodeid;
			  	
		 	 	if(call AMSend.send(5,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO
		  		locked=TRUE;	
		  		}
	  		
	  		}
	 	 		
	 	 	
 	 		}
 	 	
 	 	return bufPtr;
 	 }
 	 
 }
 }

