# Control motor through PWM

import socket
import threading
import time
import json


class UDPHandler:

    REFRESH = b'\x06'
    AUTO = b'\x01'
    MANU = b'\x02'
    LEFT = b'\x03'
    RIGHT = b'\x04'
    SET = b'\x05'

    def __init__(self):

        UDP_IP = "192.168.1.95"
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



# while True:
#     data, addr = sock.recvfrom(1024) # buffer size is 1024 bytes
#     print("received message: %s" % data)


# import time

# def crawl(link, delay=3):
#     print(f"crawl started for {link}")
#     time.sleep(delay)  # Blocking I/O (simulating a network request)
#     print(f"crawl ended for {link}")

# links = [
#     "https://python.org",
#     "https://docs.python.org",
#     "https://peps.python.org",
# ]

# # Start threads for each link
# threads = []
# for link in links:
#     # Using `args` to pass positional arguments and `kwargs` for keyword arguments
#     t = threading.Thread(target=crawl, args=(link,), kwargs={"delay": 2})
#     threads.append(t)

# # Start each thread
# for t in threads:
#     t.start()

# # Wait for all threads to finish
# for t in threads:
#     t.join()