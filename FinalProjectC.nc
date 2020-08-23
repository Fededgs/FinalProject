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
		interface Timer<TMilli> as MilliTimerACK;
		interface SplitControl as AMControl;
    	interface Packet;	
    	interface Random;		
	}
}
implementation {
	message_t packet;
	bool locked;
	bool ack=FALSE;
	uint8_t counter=1;
	
	//count needed to Server Netw to established if the packet received is a duplicates
	/*
	uint8_t last_count_1 = 0;
	uint8_t last_count_2 = 0;
	uint8_t last_count_3 = 0;		
	uint8_t last_count_4 = 0;	
	uint8_t last_count_5 = 0;
	
	*/
	uint8_t count_server[5];
		
	event void Boot.booted() {
		dbg("boot","Application booted on node %u.\n",TOS_NODE_ID);
		call AMControl.start();
	}
	
	
	event void AMControl.startDone(error_t err) {
	    if (err == SUCCESS) {
	    	dbg("radio","Radio on \n");
			switch (TOS_NODE_ID)
			{
				//sensor node 1
				case 1:
					call MilliTimer.startPeriodic(PERIOD_NODE);
				break;
				//sensor node 2
				case 2:
					call MilliTimer.startPeriodic(PERIOD_NODE);;
				break;
				//sensor node 3
				case 3:
					call MilliTimer.startPeriodic(PERIOD_NODE);
				break;
				//sensor node 4	
				case 4:
					call MilliTimer.startPeriodic(PERIOD_NODE);
				break;
				//sensore node 5
				case 5:
					call MilliTimer.startPeriodic(PERIOD_NODE);
				break;
				//4 --> gateway
				//5 --> gateway
				//6 --> Network Server
				default:
				break;
			}	    	
	    }
	    else {
		    dbgerror("radio","Restart radio \n");
			call AMControl.start();
	    }
	}
  
  
	event void AMControl.stopDone(error_t err) {
    	//
	}
	
  
	event void MilliTimer.fired(){	
	
		dbg("timer","MillitTimer fired at %s.\n", sim_time_string());
		//printf("Timer FIRED \n");
		//printfflush();	  
		
		if(locked || ack){ //se sta provando a ritrasmetter in millitimerack.fired, non posso inviare uovo packetto
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
	  	
		//printf("Sent: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	 	//printfflush();
	 	
	 	
	  	
	  	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO AM_BROADCAST_ADDR
	  	
			dbg("radio_send", "Packet DATA sent successfully!\n");
			dbg("radio_pack",">>>Pack\n ", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t\t Payload Sent\n" );
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm->msg_type);
			dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm->nodeid);
			dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm->gateway);
			dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm->value);
			dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm->count);
			dbg_clear("radio_send", "\n ");
			dbg_clear("radio_pack", "\n");
	  		
	  		locked=TRUE;
	  		ack=TRUE;
	  		counter++;
	  		call MilliTimerACK.startOneShot(PERIOD_ACK);	
	  		
	  	}	
	  		
		}
		
	}
	
	
	
	event void MilliTimerACK.fired(){
		
		dbg("timer","MilliTimerACK fired at %s.\n", sim_time_string());
		
		if(ack){//ack==true, ack not received.--> retrasmission
		
			//dbg_clear("radio_ack", "\t\t RETRASMISSION and NO ack received at time %s \n", sim_time_string());
		
			radio_count_msg_t* rcm =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	
			 
			//printf("RETRASMISSION %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
			//printfflush();
			
			if(call AMSend.send(4,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO AM_BROADCAST_ADDR
				
				dbg("radio_send", "Packet RETRASMISSION DATA sent successfully!\n");
				dbg("radio_pack",">>>Pack\n ", call Packet.payloadLength( &packet ) );
				dbg_clear("radio_pack","\t\t Payload Sent\n" );
				dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm->msg_type);
				dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm->nodeid);
				dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm->gateway);
				dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm->value);
				dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm->count);
				dbg_clear("radio_send", "\n ");
				dbg_clear("radio_pack", "\n");
				
		  		locked=TRUE;
		  		ack=TRUE;
		  		//counter++;
		  		call MilliTimerACK.startOneShot(PERIOD_ACK); //start at 0+Period_ack	
	  		}		
		
		}
		/*
		else{
			dbg_clear("radio_ack", "\t\t RETRASMISSION STOPPED  at time %s \n", sim_time_string());

			//printf("TimerAck stopped");
			//printfflush();	 
		}
		*/
			
	
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
      		
      		//dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
	
	  		
      		//packet error received
      		if(rcm==NULL){ 
				  		return bufPtr;	
			  		}
			
			dbg("radio_pack", "locked?: %hhu \n",locked);  		
			  		
	  		if(rcm->msg_type==DATA){
	  			dbg("radio_pack", "DATA message arrived\n");
	  			//printf("Rec DATA: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	  			//printfflush();
	  		}
	   		if(rcm->msg_type==ACK){
	   			dbg("radio_pack", "ACK message arrived\n");
	   			//printf("Rec ACK: %u,%u,%u,%u,%u \n",rcm->msg_type,rcm->nodeid,rcm->gateway,rcm->value,rcm->count);
	   			//printfflush();
	   		}
	   		
	   		
			dbg("radio_pack", ">>>Pack \n");
			dbg_clear("radio_pack","\t\t Payload Received\n" );
			dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm->msg_type);
			dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm->nodeid);
			dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm->gateway);
			dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm->value);
			dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm->count);
			dbg_clear("radio_send", "\n ");
			dbg_clear("radio_pack", "\n");
			  		

			if(TOS_NODE_ID==1 || TOS_NODE_ID==2 || TOS_NODE_ID==3){ 
			
				dbg_clear("radio_ack", "\t\t ACK received - RETRASMISSION STOPPED at time %s \n", sim_time_string());
 	 			call MilliTimerACK.stop();	 

 	 			
 	 			if(rcm->count == counter-1){
 	 				ack=FALSE;
 	 			}
 	 		}
	 	 	
		//-------------------__resending to Network server__--------------------------------------------------------------------------
	 	 	if(TOS_NODE_ID==4 || TOS_NODE_ID==5  ){
	 	 	
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
					  	
				 	 	if(call AMSend.send(6,&packet,sizeof(radio_count_msg_t))==SUCCESS){ 
				 	 		dbg("radio_send", "Packet DATA GATEWAY-->SERVER sent successfully!\n");
							dbg("radio_pack",">>>Pack\n ", call Packet.payloadLength( &packet ) );
							dbg_clear("radio_pack","\t\t Payload Sent\n" );
							dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm_new->msg_type);
							dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm_new->nodeid);
							dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm_new->gateway);
							dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm_new->value);
							dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm_new->count);
							dbg_clear("radio_send", "\n ");
							dbg_clear("radio_pack", "\n");
				 	 	
				 	 		//printf("Sent DATA%u,%u,%u,%u,%u \n",rcm_new->msg_type,rcm_new->nodeid,rcm_new->gateway,rcm_new->value,rcm_new->count);
					  		locked=TRUE;	
					  		//printfflush();	 
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
				  		
				  			dbg("radio_send", "Packet ACK GATEWAY-->NODE sent successfully!\n");
							dbg("radio_pack",">>>Pack\n ", call Packet.payloadLength( &packet ) );
							dbg_clear("radio_pack","\t\t Payload Sent\n" );
							dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm_ack->msg_type);
							dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm_ack->nodeid);
							dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm_ack->gateway);
							dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm_ack->value);
							dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm_ack->count);
							dbg_clear("radio_send", "\n ");
							dbg_clear("radio_pack", "\n");
							
				 	 		//printf("Sent ACK %u,%u,%u,%u,%u \n",rcm_ack->msg_type,rcm_ack->nodeid,rcm_ack->gateway,rcm_ack->value,rcm_ack->count);
					  		locked=TRUE;	
					 	 	//printfflush();	 					  		
				  		}
				  		
				  	}
	  			}	
 	 		}
 	 		
 	 		if(TOS_NODE_ID==6){ //Server network
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
				  	
				  	
				  	
				  	dbg_clear("radio_pack","\t\t DUPLICATES\n" );
					dbg_clear("radio_pack", "\t\t sensor node 1 counter: %hhu \n ", count_server[0]);
					dbg_clear("radio_pack", "\t\t sensor node 2 counter: %hhu \n ", count_server[1]);
					dbg_clear("radio_pack", "\t\t sensor node 3 counter: %hhu \n ", count_server[2]);
					dbg_clear("radio_pack", "\t\t sensor node 4 counter: %hhu \n ", count_server[3]);
					dbg_clear("radio_pack", "\t\t sensor node 5 counter: %hhu \n ", count_server[4]);
		  	
		  			if(count_server[rcm->nodeid-1]==rcm->count ){
				  		dbg_clear("radio_pack","\t\t IT'S A DUPLICATE!!!\n" );
				  	}
				  	
				  	else{
				  		printf(" %u %u\n",rcm->nodeid,rcm->value );
				  		printfflush();
				  		dbg_clear("radio_pack","\t\t NOT a Duplicate\n" );
				  		count_server[rcm->nodeid - 1]=rcm->count;
				  	}
				  	
 	 			
 	 				if(call AMSend.send(rcm->gateway,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO
 	 				
 	 						dbg("radio_send", "Packet ACK SERVER-->GATEWAY sent successfully!\n");
							dbg("radio_pack",">>>Pack\n ", call Packet.payloadLength( &packet ) );
							dbg_clear("radio_pack","\t\t Payload Sent\n" );
							dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", rcm_ack->msg_type);
							dbg_clear("radio_pack", "\t\t msg_nodeid: %hhu \n ", rcm_ack->nodeid);
							dbg_clear("radio_pack", "\t\t msg_gateway: %hhu \n ", rcm_ack->gateway);
							dbg_clear("radio_pack", "\t\t value: %hhu \n ", rcm_ack->value);
							dbg_clear("radio_pack", "\t\t counter: %hhu \n ", rcm_ack->count);
							dbg_clear("radio_send", "\n ");
							dbg_clear("radio_pack", "\n");
				 	 		//printf("Sent ACK %u,%u,%u,%u,%u \n",rcm_ack->msg_type,rcm_ack->nodeid,rcm_ack->gateway,rcm_ack->value,rcm_ack->count);
					  		locked=TRUE;	
					  		//printfflush();	 
				  		}
 	 			
 	 			}
 	 		
 	 		
 	 		}
 	 		
 	 		
 	 		
 	 	
 	 	return bufPtr;
 	 }
 	 
 }
 }

