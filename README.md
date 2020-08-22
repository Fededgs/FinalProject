# FinalProject
Final proj of IOT


ack boolean, if true don't send

MillitimerACK set to 2000ms, because in some case during the simulation is too small set 1000ms

in log file the case is 123 4 5 ()node sensor

problem the node 6 can't receive at the same time duplicates, as is locked. found a way to ritardare arrivo del pacchetto al nodo 6 --> solved by changing dbm 5-6 in topology.txt