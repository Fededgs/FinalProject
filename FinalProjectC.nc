/**
 *  
 *  @author Di Giusto Federico 10693473
 *
 */
#include "Timer.h"
#include "FinalProject.h"
//#include "printf.h" //TODO add if in Cooja-NodeRed

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
	uint8_t counter=1;
	//array for Server to store last counter and check duplicates
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
	  	
	  	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(radio_count_msg_t))==SUCCESS){ 
	  	
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
	  		counter++;
	  		call MilliTimerACK.startOneShot(PERIOD_ACK);	
	  		
	  		}	
	  		
		}
		
	}
	
	
	
	event void MilliTimerACK.fired(){
		
	
		radio_count_msg_t* rcm =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	
		
		dbg("timer","MilliTimerACK fired at %s.\n", sim_time_string());
		 	
		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(radio_count_msg_t))==SUCCESS){ //TODO AM_BROADCAST_ADDR
			
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
	  		
			//start oneshot timer for retrasmission
	  		call MilliTimerACK.startOneShot(PERIOD_ACK); 
  		}		
			
	}
	
	
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		
		if (&packet == bufPtr) {
		  locked = FALSE;
		}
		
 	}
 	
 	
/**************____RECEIVE PACKET____****************/ 	
 	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
 	 	
 	 	if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
 	 	
	 	else {
	 		
      		radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
	  		
      		//packet error received
      		if(rcm==NULL){ 
				  		return bufPtr;	
			  		}
			
			//for debugging, check if it's locked. It happens if gateway sends at the same time the packet to the Server.
			dbg("radio_pack", "locked?: %hhu \n",locked);  		
			  		
	  		if(rcm->msg_type==DATA){
	  			dbg("radio_pack", "DATA message arrived\n");
	  			
	  		}
	   		if(rcm->msg_type==ACK){
	   			dbg("radio_pack", "ACK message arrived\n");
	   			
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
			  		
			//CASE 1 : The sensor nodes receive the Packet(only ACK could be)
			if(TOS_NODE_ID==1 || TOS_NODE_ID==2 || TOS_NODE_ID==3 || TOS_NODE_ID==4 || TOS_NODE_ID==5){ 
	
 	 			if(rcm->count == counter-1){
 	 				dbg_clear("radio_ack", "\t\t ACK received - RETRASMISSION STOPPED at time %s \n", sim_time_string());
 	 				
 	 				//Stop the Retrasmission Timer
	 	 			call MilliTimerACK.stop();	
 	 				
 	 			}
 	 		}
	 	 	
			//CASE 2: Gateway receive a packet.Could be a DATA (that must be forwarded to Server) or an ACK (must be delivered to the original Sensor Node)
	 	 	if(TOS_NODE_ID==6 || TOS_NODE_ID==7  ){
	 	 	
		 	 	if(locked){
		  			return bufPtr;
		  		}
			  	else {
	  		
					radio_count_msg_t* rcm_new =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	  
				  				  		
			  		//DATA received from sensor node-->FORWARDING
				  	if(rcm->msg_type==DATA){
				  		rcm_new->msg_type= DATA;
					  	rcm_new->value=rcm->value;
					  	rcm_new->nodeid=rcm->nodeid;
					  	rcm_new->count=rcm->count;
					  	rcm_new->gateway=TOS_NODE_ID;
					  	
					  	//Sending to the Server Node
				 	 	if(call AMSend.send(8,&packet,sizeof(radio_count_msg_t))==SUCCESS){ 
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
				 	 		
					  		locked=TRUE;	
					  		
				  		}
				  	}
				  	
				  	//ACK received from Server Network--> DELIVERING to sensor Node
				  	if(rcm->msg_type==ACK){
				  		
				  		radio_count_msg_t* rcm_ack =(radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));	
 	 				
	 	 				rcm_ack->msg_type= ACK;
					  	rcm_ack->value=0;	//in ACK no need of value
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
							
					  		locked=TRUE;	
					 	 	
				  		}
				  		
				  	}
	  			}	
 	 		}
 	 		
 	 		//CASE 3: Server Node can receive ONLY DATA Packet
 	 		if(TOS_NODE_ID==8){ 
 	 		
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
				  	
					//print array elements for debugging
				  	dbg_clear("radio_pack","\t\t DUPLICATES\n" );
					dbg_clear("radio_pack", "\t\t sensor node 1 counter: %hhu \n ", count_server[0]);
					dbg_clear("radio_pack", "\t\t sensor node 2 counter: %hhu \n ", count_server[1]);
					dbg_clear("radio_pack", "\t\t sensor node 3 counter: %hhu \n ", count_server[2]);
					dbg_clear("radio_pack", "\t\t sensor node 4 counter: %hhu \n ", count_server[3]);
					dbg_clear("radio_pack", "\t\t sensor node 5 counter: %hhu \n ", count_server[4]);
		  	
		  			//The counter received was yet arrived before: duplicate
		  			if(count_server[rcm->nodeid-1]==rcm->count ){
				  		dbg_clear("radio_pack","\t\t IT'S A DUPLICATE!!!\n" );
				  	}
				  	//Not a duplicate--> ACK delivering to the gateway
				  	else{
				  	
				  		dbg_clear("radio_pack","\t\t NOT a Duplicate\n" );
				  		count_server[rcm->nodeid - 1]=rcm->count;
				  		
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
				 	 		
					  		locked=TRUE;	
					  		
				  		}
				  	}
				  	
 	 			

 	 			
 	 			}
 	 		
 	 		
 	 		}
 	 		
 	 		
 	 		
 	 	
 	 	return bufPtr;
 	 }
 	 
 }
 }

