/**
 *  
 *  @author Di Giusto Federico 10693473
 *
 */
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
	uint8_t counter=0;
	
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
	  	rcm->msg_type=DATA;
	  	rcm->count = counter;
	  	
		printf("Sent: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	 	printfflush();
	 	
	 	
	  	
	  	if(call AMSend.send(4,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO AM_BROADCAST_ADDR
	  		locked=TRUE;
	  		counter++;	
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
      		
      		//packet error received
      		if(rcm==NULL){ 
				  		return bufPtr;	
			  		}
			  		
			  		
	  		if(rcm->msg_type==DATA){
	  			printf("Rec DATA: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	  		}
	   		if(rcm->msg_type==ACK){
	   			printf("Rec ACK: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	   		}
			  		

	 	 	printfflush();	 
	 	 	
		//-------------------__resending to Network server__--------------------------------------------------------------------------
	 	 	if(TOS_NODE_ID==4  ){
	 	 	
		 	 	if(locked){
		  			return bufPtr;
		  		}
			  	else {
			  	//4 receive 2 types of messages; data and ack. must distinguish them.
			  	
					radio_count_msg_t* rcm_new =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	  
				  	
			  		
			  		//DATA received from sensor node-->INOLTRARE
				  	if(rcm->msg_type==DATA){
				  		rcm_new->msg_type= DATA;
					  	rcm_new->value=rcm->value;
					  	rcm_new->nodeid=rcm->nodeid;
					  	rcm_new->count=rcm->count;
					  	rcm_new->gateway=TOS_NODE_ID;
					  	
				 	 	if(call AMSend.send(5,&packet,sizeof(radio_count_msg_t))==SUCCESS){ 
				 	 		printf("Sent DATA%u,%u,%u,%u,%u \n",rcm_new->msg_type,rcm_new->nodeid,rcm_new->gateway,rcm_new->value,rcm_new->count);
					  		locked=TRUE;	
				  		}
				  	}
				  	//ACK received from Server Network
				  	if(rcm->msg_type==ACK){
				  		
				  		radio_count_msg_t* rcm_ack =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	
 	 				
	 	 				rcm_ack->msg_type= ACK;
					  	rcm_ack->value=0;//in ACK no need of value
					  	rcm_ack->nodeid=rcm->nodeid;
					  	rcm_ack->count=rcm->count;
					  	rcm_ack->gateway=rcm->gateway;
					  	
				  		if(call AMSend.send(rcm->nodeid,&packet,sizeof(radio_count_msg_t))==SUCCESS){
				 	 		printf("Sent ACK %u,%u,%u,%u,%u \n",rcm_ack->msg_type,rcm_ack->nodeid,rcm_ack->gateway,rcm_ack->value,rcm_ack->count);
					  		locked=TRUE;	
				  		}
				  		
				  	}
	  			}	
 	 		}
 	 		
 	 		if(TOS_NODE_ID==5){ //Server network
 	 		//TODO: check duplicates
 	 			if(locked){
 	 				return bufPtr;
 	 			}
 	 			else{
 
 	 				radio_count_msg_t* rcm_ack =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	
 	 				
 	 				rcm_ack->msg_type= ACK;
				  	rcm_ack->value=0;//in ACK no need of value
				  	rcm_ack->nodeid=rcm->nodeid;
				  	rcm_ack->count=rcm->count;
				  	rcm_ack->gateway=rcm->gateway;
 	 			
 	 				if(call AMSend.send(rcm->gateway,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO
				 	 		printf("Sent ACK %u,%u,%u,%u,%u \n",rcm_ack->msg_type,rcm_ack->nodeid,rcm_ack->gateway,rcm_ack->value,rcm_ack->count);
					  		locked=TRUE;	
				  		}
 	 			
 	 			}
 	 		
 	 		
 	 		}
 	 		
 	 		if(TOS_NODE_ID==1 || TOS_NODE_ID==2 || TOS_NODE_ID==3){ 
 	 			printf("ACK RECEIVED BY NODES");
 	 			//SE rcm->counter== count OK TODO
 	 		}
 	 		
 	 	
 	 	return bufPtr;
 	 }
 	 
 }
 }

