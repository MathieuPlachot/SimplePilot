# Control motor through PWM

import socket
import threading
import time
import json


class UDPHandler:

    AUTO = b'\x01'
    MANU = b'\x02'
    LEFT = b'\x03'
    RIGHT = b'\x04'
    SET = "SET"
    REFRESH = b'\x06'


    def __init__(self):

        UDP_IP = "10.3.141.1"
        UDP_PORT_RCV = 1234
        UDP_PORT_REP = 5678

        self.rcvSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.rcvSock.bind((UDP_IP, UDP_PORT_RCV))
        self.rcvSock.settimeout(3)

        self.repSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.repSock.bind((UDP_IP, UDP_PORT_REP))
        self.repSock.settimeout(3)

        self.listeningThread = threading.Thread(target=self.listen)
        self.transmittingThread = threading.Thread(target=self.transmitStatus)
        self.listening = True
        self.lastCommand = None
        self.clientAddress = None

        self.heartBeat = 0

    def getCommand(self):
        command = self.lastCommand
        self.lastCommand = None
        return command

    def listen(self):
        i = 0
        while self.listening:
            # print("Listening")
            try:
                data, addr = self.rcvSock.recvfrom(1024) # buffer size is 1024 bytes
                self.lastCommand = data
                self.clientAddress = addr
            except:
                pass
                # print("Timeout")

    def transmitStatus(self, pilotStatus):
        # print(self.clientAddress)
        pilotStatus["LNK"] = self.heartBeat

        if self.heartBeat == 0:
            self.heartBeat = 1
        else:
            self.heartBeat = 0
        
        pilotStatusJsonString = json.dumps(pilotStatus)
        pilotStatusJsonStringBytes = pilotStatusJsonString.encode('utf-8')
        self.repSock.sendto(pilotStatusJsonStringBytes, (self.clientAddress[0],5678))
        return

    def startTransmitting(self, pilotStatus):
        self.transmittingThread = threading.Thread(target=self.transmitStatus, args=(pilotStatus,))
        self.transmittingThread.start()

    def startListening(self):
        self.listeningThread.start()

    def end(self):
        self.listening = False
        self.listeningThread.join()