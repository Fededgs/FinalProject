#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct radio_count_msg {
  nx_uint16_t value;
  nx_uint16_t nodeid;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
  PERIOD_NODE_1=5000,
  PERIOD_NODE_2=5000,
  PERIOD_NODE_3=5000,
  
};

#endif
