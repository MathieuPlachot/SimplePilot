# Control motor through PWM

import socket
import threading
import time
import json


class UDPHandler:

    AUTO = "AUTO"
    MANU = "MANU"
    DECREASE_TILLER = "DECREASE_TILLER"
    INCREASE_TILLER = "INCREASE_TILLER"
    DECREASE_SETPOINT = "DECREASE_SETPOINT"
    INCREASE_SETPOINT = "INCREASE_SETPOINT"
    SET = "SET"
    SET_MODE = "SET_MODE"
    REFRESH = "REFRESH"
    APPLY_PARAMS = "APPLY_PARAMS"
    APPLY_SAVE_PARAMS = "APPLY_SAVE_PARAMS"

    UDP_IP = "0.0.0.0" # Any
    UDP_PORT_RCV = 50002
    UDP_PORT_REP = 50002


    def __init__(self):

        

        self.srvSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # TCP Socket
        self.srvSock.bind((UDPHandler.UDP_IP, UDPHandler.UDP_PORT_RCV))

        self.listeningThread = threading.Thread(target=self.listen)
        self.transmittingThread = threading.Thread(target=self.transmitStatus)
        self.listening = True
        self.lastCommand = None
        self.lastClientAddress = None

        self.heartBeat = 0

    def getCommand(self):
        command = self.lastCommand
        self.lastCommand = None
        return command

    def listen(self):
        while self.listening:
            data, addr = self.srvSock.recvfrom(1024)
            print("[UDPHandler] Received data from", addr, "[", data, "]")
            self.lastCommand = data
            self.lastClientAddress = addr

    def transmitStatus(self, pilotStatus):
        print("[UDPHandler] Transmitting status to", self.lastClientAddress)

        pilotStatus["LNK"] = self.heartBeat

        if self.heartBeat == 0:
            self.heartBeat = 1
        else:
            self.heartBeat = 0
        
        pilotStatusJsonString = json.dumps(pilotStatus)
        pilotStatusJsonStringBytes = pilotStatusJsonString.encode('utf-8')
        self.srvSock.sendto(pilotStatusJsonStringBytes, (self.lastClientAddress[0],UDPHandler.UDP_PORT_REP))
        
        return

    def startTransmitting(self, pilotStatus):
        self.transmittingThread = threading.Thread(target=self.transmitStatus, args=(pilotStatus,))
        self.transmittingThread.start()

    def startListening(self):
        self.listeningThread.start()

    def end(self):
        self.listening = False
        self.listeningThread.join()
