from motor import PilotMotor
from gps import PilotGPS
from UDPHandler import UDPHandler
import time
import json
import sys


class Pilot:

    def __init__(self, Kp, Kd, Ki):
        self.myMotor = PilotMotor()
        self.myGPS = PilotGPS()
        self.mode = "MANU"
        self.setPoint = 0
        self.currentHeading = 0
        self.speed = 0
        self.myUDPHandler = UDPHandler()
        self.myUDPHandler.startListening()
        self.prevError = None
        self.prevTime = None
        print("Kp", Kp, "Kd", Kd, "Ki", Ki)
        self.Kp = float(Kp)
        self.Kd = float(Kd)
        self.Ki = float(Ki)
        self.error_rate = 0
        self.command = 0
        self.error = 0
        self.Cp = 0
        self.Ci = 0
        self.Cd = 0



    def refreshClient(self):
        self.myUDPHandler.startTransmitting(self.getStatus())

    def handleUDP(self):

        udpCommand = self.myUDPHandler.getCommand()

        if udpCommand == None:
            return

        print("UDP", udpCommand)

        try:
            commandDict = json.loads(udpCommand)
            print(commandDict)

            if commandDict["COMMAND"] == UDPHandler.SET:
                print("SET ", self.currentHeading)
                if self.currentHeading != "-":
                    self.setPoint = float(self.currentHeading)
                    return

        except Exception as e:
            pass
            # print("Could not interpret UDP data")
            # print(e)


        if self.mode == "MANU":
            if udpCommand == UDPHandler.LEFT:
                print("GO LEFT")
                self.myMotor.command(98, PilotMotor.OUTWARDS)
                time.sleep(0.5)
                self.myMotor.stop()
                return
            elif udpCommand == UDPHandler.RIGHT:
                print("GO RIGHT")
                self.myMotor.command(98, PilotMotor.INWARDS)
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



        if udpCommand == UDPHandler.REFRESH:
            self.refreshClient()
            return

        return

    def smallestError(self, setPoint, currentHeading):
        e = None
        try:
            setPoint = float(setPoint)
            currentHeading = float(currentHeading)
        except:
            print("Could not compute error")
            return 0
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

    def commandFromError(self):
        result = {}

        # self.error_rate = 0
        currentTime = time.time()

        if self.prevError != None and self.error != self.prevError:
            delta_t = currentTime - self.prevTime
            delta_err = self.error - self.prevError
            self.error_rate = delta_err / delta_t
            # print("delta err delta_t error_rate", delta_err, delta_t, self.error_rate)

        if self.prevError != self.error:
            self.prevTime = currentTime
        self.prevError = self.error
        
        self.Cp = self.Kp * self.error
        self.Cd = self.Kd * self.error_rate
        
        signedSpeed = self.Cp + self.Cd

        result["SPEED"] = abs(signedSpeed)

        if signedSpeed > 0 :
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
        status["SPEED"] = self.myGPS.getSpeed()
        status["KP"] = self.Kp
        status["KD"] = self.Kd
        status["KI"] = self.Ki
        return status

    def run(self):

        cycle = 0
        while True:
            cycle+=1
            self.handleUDP()
            self.currentHeading = self.myGPS.getGPSRoute()

            if self.mode == "AUTO":
                if(self.setPoint != "-" and self.currentHeading != "-"):
                    self.error = self.smallestError(self.setPoint, self.currentHeading)
                    command = self.commandFromError()
                    self.myMotor.command(command["SPEED"], command["DIR"])
                    if cycle % 100 == 0:
                        print("SET", self.setPoint, "CURRENT", self.currentHeading, "ERROR", self.error, "error rate", self.error_rate, "Cp", self.Cp, "Cd", self.Cd, "COMMAND", command)

Kp = sys.argv[1] #1
Kd = sys.argv[2] #10
Ki = sys.argv[3] #0

myPilot = Pilot(Kp, Kd, Ki)
myPilot.run()
