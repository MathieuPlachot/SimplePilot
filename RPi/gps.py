import serial
import threading
import time
import random


class PilotGPS:

    def __init__(self):

        self.listeningThread = threading.Thread(target=self.listen)
        self.testListeningThread = threading.Thread(target=self.testListen)

        self.RMCData = {}
        self.listening = True

        try:
            self.ser = serial.Serial("/dev/ttyACM0", baudrate=9600)
            self.listeningThread.start()
        except Exception as e:
            print("Could not connect to GPS. Starting simulation thread.", e)
            self.testListeningThread.start()

    def listen(self):
        while self.listening:
            line = self.ser.readline()
            if "$GPRMC" in str(line):
                RMCString = str(line)
                RMCList = RMCString.split(",")
                self.RMCData["TIME"] = RMCList[1]
                self.RMCData["VALIDITY"] = RMCList[2]
                self.RMCData["LAT"] = RMCList[3]
                self.RMCData["LATNS"] = RMCList[4]
                self.RMCData["LON"] = RMCList[5]
                self.RMCData["LONEW"] = RMCList[6]
                self.RMCData["SPEED"] = RMCList[7]
                self.RMCData["ROUTE"] = RMCList[8]
                print(self.RMCData)

    def testListen(self):
        sign = 1
        init = random.randint(0,360)
        while self.listening:
            time.sleep(1)
            if not "ROUTE" in self.RMCData:
                self.RMCData["ROUTE"] = init
            else:
                self.RMCData["ROUTE"] = random.randint(init-5,init+5)

    def getGPSRoute(self):
        if "ROUTE" in self.RMCData:
            if self.RMCData["ROUTE"] != "":
                return self.RMCData["ROUTE"]
        return "-"

    def getStatus(self):
        if "VALIDITY" in self.RMCData:
            return self.RMCData["VALIDITY"]
        return "-"

    






