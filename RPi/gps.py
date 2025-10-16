import serial
import threading



class PilotGPS:

    def __init__(self):
        
        self.listeningThread = threading.Thread(target=self.listen)
        self.RMCData = {}
        self.listening = True

        try:
            self.ser = serial.Serial("/dev/ttyACM0", baudrate=9600)
            self.listeningThread.start()
        except:
            print("Could not connect to GPS")

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

    def getGPSRoute(self):
        if "ROUTE" in self.RMCData:
            if self.RMCData["ROUTE"] != "":
                # return self.RMCData["ROUTE"]
                return self.RMCData["SPEED"]
        return "-"

    def getStatus(self):
        if "VALIDITY" in self.RMCData:
            return self.RMCData["VALIDITY"]
        return "-"

    






