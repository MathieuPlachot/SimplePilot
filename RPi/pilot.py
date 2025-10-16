from motor import PilotMotor
from gps import PilotGPS
from UDPHandler import UDPHandler
import time


class Pilot:

    def __init__(self):
        self.myMotor = PilotMotor()
        self.myGPS = PilotGPS()
        self.mode = "MANU"
        self.setPoint = 7
        self.currentHeading = 0
        self.myUDPHandler = UDPHandler()
        self.myUDPHandler.startListening()
        self.Kp = 10



    def refreshClient(self):
        self.myUDPHandler.startTransmitting(self.getStatus())

    def handleUDP(self):

        udpCommand = self.myUDPHandler.getCommand()

        if udpCommand == None:
            return

        # print("UDP", udpCommand)

        if self.mode == "MANU":
            if udpCommand == UDPHandler.LEFT:
                print("GO LEFT")
                self.myMotor.command(98, PilotMotor.INWARDS)
                time.sleep(0.5)
                self.myMotor.stop()
                return
            elif udpCommand == UDPHandler.RIGHT:
                print("GO RIGHT")
                self.myMotor.command(98, PilotMotor.OUTWARDS)
                time.sleep(0.5)
                self.myMotor.stop()
                return
            
        if self.mode == "AUTO":
            if udpCommand == UDPHandler.LEFT:
                if self.setPoint >= 10:
                    self.setPoint-=10
                else:
                    self.setPoint = 360 - (10 - self.setPoint)
                return
            if udpCommand == UDPHandler.RIGHT:
                if self.setPoint < 350:
                    self.setPoint+=10
                else:
                    self.setPoint = 10 - (360 - self.setPoint)
                return
        
        if udpCommand == UDPHandler.AUTO:
            print("AUTO")
            self.mode = "AUTO"
            return

        if udpCommand == UDPHandler.MANU:
            print("MANU")
            self.myMotor.stop()
            self.mode = "MANU"
            return

        if udpCommand == UDPHandler.SET:
            print("SET ", self.currentHeading)
            if self.currentHeading != "-":
                self.setPoint = self.currentHeading
                return

        if udpCommand == UDPHandler.REFRESH:
            self.refreshClient()
            return

        return

    def smallestError(self, setPoint, currentHeading):
        e = None
        if abs(setPoint - currentHeading) <=180:
            e = currentHeading - setPoint
        else:

            sign = 0
            if currentHeading - setPoint >= 0:
                sign = 1
            else:
                sign = -1

            e = sign * (abs(currentHeading - setPoint) - 360)
        return e

    def commandFromError(self, error):
        result = {}
        result["SPEED"] = self.Kp * abs(error)
        if error > 0 :
            result["DIR"] = PilotMotor.OUTWARDS
        else:
            result["DIR"] = PilotMotor.INWARDS
        return result

    def getStatus(self):
        status = {}
        status["SETPOINT"] = self.setPoint
        status["CURRENT"] = self.currentHeading
        status["GPSSTATE"] = self.myGPS.getStatus()
        status["MODE"] = self.mode
        return status

    def run(self):

        cycle = 0
        while True:
            cycle+=1
            self.handleUDP()
            self.currentHeading = self.myGPS.getGPSRoute()

            if self.mode == "AUTO":
                error = self.smallestError(self.setPoint, self.currentHeading)
                command = self.commandFromError(error)
                self.myMotor.command(command["SPEED"], command["DIR"])
                if cycle % 100000 == 0:
                    print("SET", self.setPoint, "CURRENT", self.currentHeading, "ERROR", error, "COMMAND", command)

myPilot = Pilot()
myPilot.run()
