Federico Di Giusto

10693473


Link repository github: https://github.com/Fededgs/FinalProject

Link channel ThingSpeak: https://thingspeak.com/channels/1119275

# FinalProject

## In the folder:
* ```/logfile``` logfiles:
  * ```duplicate_detected.txt```: case of a duplicate. Server receive the msg->counter equal to the last one it receive from the same node.
  * ```logfile_trasmission_KO_single_node.txt```: single node, ACK received by the sensor and MillitimerACK stopped for retrasmission. (node1=sensor node, node4=gateway, node5=server))
  * ```logfile_trasmission_OK_single_node.txt```: single node, Retrasmission of the same Packet.(node1=sensor node, node4=gateway, node5=server))
  * ```logfile_trasmission_OK_3_nodes_simultaneous.txt```: Scenario with 3 nodes, and ACK implemented and receives.
  * ```logfile_trasmission_RETRASMISSION_node_3_failed.txt```: Scenaario with 3 nodes, ACK not received from sensor 3, it re-sends it.
* ```node_red.json```: Node-red Clipboard
* ```RunSimulationScript.py```: Script for debugging
