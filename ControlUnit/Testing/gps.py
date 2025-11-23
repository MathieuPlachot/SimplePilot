import threading
import time
import random


class PilotGPS:

    def __init__(self):

        self.listeningThread = threading.Thread(target=self.listen)
        self.RMCData = {}
        self.listening = True

        self.listeningThread.start()

    def listen(self):
        while self.listening:
            time.sleep(1) # Simulate 1s waiting time between GPS frames
            self.RMCData["TIME"] = time.time()
            self.RMCData["VALIDITY"] = "A" # Always valid in testing mode
            self.RMCData["LATITUDE"] = "0000.00,N"
            self.RMCData["LONGITUDE"] = "00000.00,E"

            simulatedRoute = random.random() * 10 + 175 # 180 degrees +/- 5 degrees
            simulatedSpeed = random.random() + 5 # 5kts -0/+1kt

            self.RMCData["SPEED"] = str(simulatedSpeed)
            self.RMCData["ROUTE"] = str(simulatedRoute)

    def getGPSRoute(self):
        if "ROUTE" in self.RMCData:
            if self.RMCData["ROUTE"] != "":
                return self.RMCData["ROUTE"]
        return "-"
    
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
        return "-"

    






