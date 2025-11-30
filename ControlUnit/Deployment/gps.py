import serial
import threading
import time

class PilotGPS:

    def __init__(self):

        self.listeningThread = threading.Thread(target=self.listen)
        self.RMCData = {}
        self.listening = True

        try:
            self.ser = serial.Serial("/dev/ttyACM0", baudrate=9600)
            self.listeningThread.start()
        except Exception as e:
            print("Could not connect to GPS.", e)

    def listen(self):
        while self.listening:
            line = self.ser.readline()
            if "$GPRMC" in str(line):
                RMCString = str(line)
                RMCList = RMCString.split(",")
                self.RMCData["TIME"] = RMCList[1]
                self.RMCData["VALIDITY"] = RMCList[2]
                self.RMCData["LATITUDE"] = RMCList[3]+","+RMCList[4]
                self.RMCData["LONGITUDE"] = RMCList[5]+","+RMCList[6]
                self.RMCData["SPEED"] = RMCList[7]
                self.RMCData["ROUTE"] = RMCList[8]
                # print(self.RMCData)

    

    def getGPSRoute(self):
        if "ROUTE" in self.RMCData:
            if self.RMCData["ROUTE"] != "":
                return self.RMCData["ROUTE"]
        return None
    
    def getGPSPosition(self):
        if "LATITUDE" in self.RMCData:
            retVal = {}
            retVal["LATITUDE"] = self.RMCData["LATITUDE"]
            retVal["LONGITUDE"] = self.RMCData["LONGITUDE"]
            return retVal
        return None

    def getStatus(self):
        if "VALIDITY" in self.RMCData:
            return self.RMCData["VALIDITY"]
        return "-"
    
    def getSpeed(self):
        if "SPEED" in self.RMCData:
            return self.RMCData["SPEED"]
        return None

    






