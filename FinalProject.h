#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct radio_count_msg {
	nx_uint8_t msg_type;
	nx_uint16_t value;
	nx_uint16_t nodeid;
	nx_uint16_t gateway;
	nx_uint16_t count; 
  
} radio_count_msg_t;

#define DATA 1
#define ACK 2 

enum {
  AM_RADIO_COUNT_MSG = 6,
  PERIOD_NODE=5000,
  PERIOD_ACK=1000,
  
};

#endif
