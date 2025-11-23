from motor import PilotMotor
from gps import PilotGPS
from UDPHandler import UDPHandler
from Utilities import calc
import time
import json
import sys

class Pilot:

    def __init__(self, Kp, Kd, Ki):
        self.loadParamsFromConf()
        self.myMotor = PilotMotor()
        self.myGPS = PilotGPS()
        self.mode = "MANU"
        self.currentWPTRoute = None
        self.currentWPT = None
        self.setPoint = 0
        self.currentHeading = 0
        self.speed = 0
        self.myUDPHandler = UDPHandler()
        self.myUDPHandler.startListening()
        self.prevError = None
        self.prevTime = None
        self.Kp = float(Kp)
        self.Kd = float(Kd)
        self.Ki = float(Ki)
        self.error_rate = 0
        self.command = 0
        self.error = 0
        self.Cp = 0
        self.Ci = 0
        self.Cd = 0

    def saveParamsToConf(self, paramName, paramValue):
        print("Saving value", paramValue, "to configuration for parameter", paramName)
        return
    
    def loadParamsFromConf(self):

        loadedParams = {}

        scriptDir = "/".join(__file__.split("/")[:-1])
        confFile = open(scriptDir + "/.pilotconf.txt", "r")
        for line in confFile.readlines():
            print(line)
            if line.startswith("#"):
                continue
            if "=" in line:
                paramName = line.split("=")[0].replace(" ","").replace("\n","")
                paramValue = line.split("=")[1].replace(" ","").replace("\n","")
                loadedParams[paramName] = paramValue
        print(loadedParams)
        return loadedParams


    def refreshClient(self):
        self.myUDPHandler.startTransmitting(self.getStatus())

    def handleUDP(self):

        udpCommand = self.myUDPHandler.getCommand()

        if udpCommand == None:
            return

        # print("UDP", udpCommand)

        try:
            commandDict = json.loads(udpCommand)
            print(commandDict)

            if commandDict["COMMAND"] == UDPHandler.SET:
                print("SET ", self.currentHeading)
                if self.currentHeading != "-":
                    self.setPoint = float(self.currentHeading)
                    return
            
            elif commandDict["COMMAND"] == UDPHandler.SET_MODE:
                if commandDict["MODE"] == "AUTO":
                    print("SET_MODE AUTO")
                    self.mode = "AUTO"
                    return
                elif commandDict["MODE"] == "MANU":
                    print("SET_MODE MANU")
                    self.myMotor.stop()
                    self.mode = "MANU"
                    return
                else:
                    print("SET_MODE not managed:", commandDict["MODE"])
                    return
                
            elif commandDict["COMMAND"] == UDPHandler.REFRESH:
                print("REFRESH")
                self.refreshClient()
                return
            
            elif commandDict["COMMAND"] == UDPHandler.INCREASE_TILLER:
                if self.mode == "MANU":
                    duration = float(commandDict["DURATION"])
                    self.myMotor.command(98, PilotMotor.INWARDS)
                    time.sleep(duration)
                    self.myMotor.stop()
                    return
                else:
                    return # Not applicable in not MANU mode

            elif commandDict["COMMAND"] == UDPHandler.DECREASE_TILLER:
                if self.mode == "MANU":
                    duration = float(commandDict["DURATION"])
                    self.myMotor.command(98, PilotMotor.OUTWARDS)
                    time.sleep(duration)
                    self.myMotor.stop()
                    return
                else:
                    return # Not applicable in not MANU mode
                
            elif commandDict["COMMAND"] == UDPHandler.INCREASE_SETPOINT:
                value = commandDict["VALUE"]
                if self.setPoint < 360 - value:
                    self.setPoint+=value
                else:
                    self.setPoint = value - (360 - self.setPoint)
                return
            
            elif commandDict["COMMAND"] == UDPHandler.DECREASE_SETPOINT:
                value = commandDict["VALUE"]
                if self.setPoint >= value:
                    self.setPoint-=value
                else:
                    self.setPoint = 360 - (value - self.setPoint)
                return
            
            elif commandDict["COMMAND"] == UDPHandler.APPLY_PARAMS:
                self.Kp = commandDict["KP"]
                self.Ki = commandDict["KI"]
                self.Kd = commandDict["KD"]
                return
            
            elif commandDict["COMMAND"] == UDPHandler.APPLY_SAVE_PARAMS:
                self.Kp = commandDict["KP"]
                self.Ki = commandDict["KI"]
                self.Kd = commandDict["KD"]
                self.saveParamToConf("KP", self.Kp)
                self.saveParamToConf("KI", self.Ki)
                self.saveParamToConf("KD", self.Kd)
                return

        except Exception as e:
            print("Could not interpret UDP command")
            print(e)
            pass

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
            self.currentPosition = self.myGPS.getGPSPosition()

            if self.mode == "WAYPOINT":
                self.currentWPT = {}
                self.currentWPT["LATITUDE"] = "0000.00,N"
                self.currentWPT["LONGITUDE"] = "00000.00,E"
                self.setPoint = calc.distAndBearingAtoB(self.currentPosition, self.currentWPT)["BEARING"]

            if self.mode == "AUTO" or self.mode == "WAYPOINT":
                if(self.setPoint != "-" and self.currentHeading != "-"):
                    self.error = calc.smallestError(self.setPoint, self.currentHeading)
                    command = self.commandFromError()
                    self.myMotor.command(command["SPEED"], command["DIR"])
                    if cycle % 100 == 0:
                        print("SET", self.setPoint, "CURRENT", self.currentHeading, "ERROR", self.error, "error rate", self.error_rate, "Cp", self.Cp, "Cd", self.Cd, "COMMAND", command)

Kp = sys.argv[1] #1
Kd = sys.argv[2] #10
Ki = sys.argv[3] #0

myPilot = Pilot(Kp, Kd, Ki)
myPilot.run()

# ToDo
# Linearly interpolated coefficients
# Waypoint mode
# Handle configuration file
# Harmonize return values when no value is availble (None instead of "-" ?)
