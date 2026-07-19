from Common.UDPHandler import UDPHandler
from Common.Utilities import calc
from pathlib import Path
import time
import json
import sys
import numpy as np


class Pilot:

    def __init__(self, motorClass, motor, gps):
        self.currentParameters = self.loadParamsFromConf()
        self.saveParamsToConf()
        self.motorClass = motorClass
        self.myMotor = motor
        self.myGPS = gps
        self.mode = "MANU"
        self.currentWPTRouteName = "ROUTE1"
        self.currentWPTName = None
        self.currentWPTDistance = None
        self.setPoint = 90
        self.currentHeading = None
        self.currentSpeed = None
        self.myUDPHandler = UDPHandler()
        self.myUDPHandler.startListening()
        self.prevError = None
        self.prevTime = None
        self.derivativeStepSecs = 1
        self.lastDerivativeEvalTime = None
        self.error_rate = 0
        self.command = 0
        self.error = 0
        self.Kp = 0
        self.Kd = 0
        self.Ki = 0
        self.Cp = 0
        self.Ci = 0
        self.Cd = 0
        self.C = 0

        self.forcedKp = None
        self.forcedKi = None
        self.forcedKd = None

    def saveParamsToConf(self):
        scriptDir = Path(__file__).parent
        confPath = scriptDir / ".pilotconf.json"
        confFile = open(confPath, "w")
        confFile.write(json.dumps(self.currentParameters, indent = 4))
        confFile.close()
        return
    
    def loadParamsFromConf(self):
        scriptDir = Path(__file__).parent
        confPath = scriptDir / ".pilotconf.json"        
        confFile = open(confPath, "r")
        jsonString = confFile.read()
        confFile.close()
        return json.loads(jsonString)

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
                if self.currentHeading != None:

                    self.prevError = None
                    self.prevTime = None
                    self.error_rate = 0
                    
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
                self.myUDPHandler.startTransmitting(self.getStatus())
                return
            
            elif commandDict["COMMAND"] == UDPHandler.INCREASE_TILLER:
                if self.mode == "MANU":
                    duration = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_DURATION"]
                    percentage = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_PERCENTAGE"]
                    self.myMotor.command(percentage, self.motorClass.INWARDS)
                    time.sleep(duration)
                    self.myMotor.stop()
                    return
                else:
                    return # Not applicable in not MANU mode

            elif commandDict["COMMAND"] == UDPHandler.DECREASE_TILLER:
                if self.mode == "MANU":
                    duration = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_DURATION"]
                    percentage = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_PERCENTAGE"]
                    self.myMotor.command(percentage, self.motorClass.OUTWARDS)
                    time.sleep(duration)
                    self.myMotor.stop()
                    return
                else:
                    return # Not applicable in not MANU mode
                
            elif commandDict["COMMAND"] == UDPHandler.INCREASE_SETPOINT:

                self.prevError = None
                self.prevTime = None
                self.error_rate = 0
                
                value = commandDict["VALUE"]
                if self.setPoint < 360 - value:
                    self.setPoint+=value
                else:
                    self.setPoint = value - (360 - self.setPoint)
                return
            
            elif commandDict["COMMAND"] == UDPHandler.DECREASE_SETPOINT:

                self.prevError = None
                self.prevTime = None
                self.error_rate = 0
                
                value = commandDict["VALUE"]
                if self.setPoint >= value:
                    self.setPoint-=value
                else:
                    self.setPoint = 360 - (value - self.setPoint)
                return
            
            elif commandDict["COMMAND"] == UDPHandler.APPLY_PARAMS:
                self.currentParameters = commandDict["PARAMS"]
                return
            
            elif commandDict["COMMAND"] == UDPHandler.APPLY_SAVE_PARAMS:
                self.currentParameters = commandDict["PARAMS"]
                self.saveParamsToConf()
                return
            
            elif commandDict["COMMAND"] == UDPHandler.FORCE_COEFFS:
                print("values", commandDict["VALUES"])
                forcedCoeffs = commandDict["VALUES"].split(",")
                print("coeffs", forcedCoeffs)
                self.forcedKp = float(forcedCoeffs[0])
                self.forcedKi = float(forcedCoeffs[1])
                self.forcedKd = float(forcedCoeffs[2])


        except Exception as e:
            print("Could not interpret UDP command")
            print(e)
            pass

    def interpolateCoeffWithSpeed(self, coeffName):

        speeds = []
        coeffValues = []

        for setting in self.currentParameters["PID_SETTINGS"]["COEFFICIENTS"]:
            speeds.append(setting["SPEED"])
            coeffValues.append(setting[coeffName])
        
        coeffValue = float(np.interp(self.currentSpeed, speeds, coeffValues))
        # print(coeffName, coeffValue)
        return coeffValue

    def commandFromError(self):
        result = {}

        if self.forcedKp == None:
            self.Kp = self.interpolateCoeffWithSpeed("KP")
        else:
            self.Kp = self.forcedKp

        if self.forcedKi == None:
            self.Ki = self.interpolateCoeffWithSpeed("KI")
        else:
            self.Ki = self.forcedKi

        if self.forcedKd == None:
            self.Kd = self.interpolateCoeffWithSpeed("KD")
        else:
            self.Kd = self.forcedKd

        # if int(self.currentTime) % 5 == 0:
        #     print("Using Kp,Ki,Kd", self.Kp, self.Ki, self.Kd)

        # self.error_rate = 0

        if self.prevError != None and self.lastDerivativeEvalTime != None:
            if self.currentTime - self.lastDerivativeEvalTime >= self.derivativeStepSecs:
                # delta_t = self.currentTime - self.prevTime
                delta_err = self.error - self.prevError
                self.error_rate = delta_err / self.derivativeStepSecs
                self.lastDerivativeEvalTime = self.currentTime
                self.prevError = self.error
                print("error, prev error, delta err, error_rate", self.error, self.prevError, delta_err, self.error_rate)
        else:
            self.lastDerivativeEvalTime = self.currentTime
            self.prevError = self.error
        
        self.Cp = self.Kp * self.error
        self.Cd = self.Kd * self.error_rate
        
        self.C = self.Cp + self.Cd

        if abs(self.C) < int(self.currentParameters["PID_SETTINGS"]["DEAD_ZONE_PERCENTAGE"]):
            result["SPEED"] = 0
        else:
            result["SPEED"] = abs(self.C)

        if self.C > 0 :
            result["DIR"] = self.motorClass.OUTWARDS
        else:
            result["DIR"] = self.motorClass.INWARDS
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
        status["Ki"] = self.Ki
        status["CP"] = self.Cp
        status["CD"] = self.Cd
        status["Ci"] = self.Ci
        status["C"] = self.C
        status["PARAMS"] = self.currentParameters
        return status
    
    def routeRankFromRouteName(self, routeName):
        rank = 0
        for route in self.currentParameters["ROUTES"]:
            if route["NAME"] == routeName:
                return rank
            rank+=1
        return None
    
    def wptRankFromRouteNameAndWptName(self, routeName, wptName):
        
        rank = 0

        routeRank = self.routeRankFromRouteName(routeName)
        wptList = self.currentParameters["ROUTES"][routeRank]["WAYPOINTS"]

        for wpt in wptList:
            if wpt["NAME"] == wptName:
                return rank
            else:
                rank+=1


    
    def wptDataFromRouteAndWPTName(self, routeName, wptName):
        # print("Find wpt data", routeName, wptName)
        routeRank = self.routeRankFromRouteName(routeName)
        wptRank = self.wptRankFromRouteNameAndWptName(routeName, wptName)
        return self.currentParameters["ROUTES"][routeRank]["WAYPOINTS"][wptRank]

    def selectClosestWaypointFromCurrentRoute(self):
        lowestDistance = None
        currentRouteRank = self.routeRankFromRouteName(self.currentWPTRouteName)
        currentRouteDefinition = self.currentParameters["ROUTES"][currentRouteRank]
        currentRouteWaypointsList = currentRouteDefinition["WAYPOINTS"]

        for wpt in currentRouteWaypointsList:

            wptDistance = calc.distAndBearingAtoB(self.currentPosition, wpt)["DISTANCE"]

            if lowestDistance == None:
                lowestDistance = wptDistance
                self.currentWPTName = wpt["NAME"]
            elif wptDistance < lowestDistance:
                lowestDistance = wptDistance
                self.currentWPTName = wpt["NAME"]

    # Select the next waypoint in the current route. If current waypoint is already the last of the route, fallback to MANU mode.
    def selectNextWaypointFromCurrentRoute(self):

        currentRouteRank = self.routeRankFromRouteName(self.currentWPTRouteName)
        currentRouteDefinition = self.currentParameters["ROUTES"][currentRouteRank]
        currentRouteWaypointsList = currentRouteDefinition["WAYPOINTS"]

        currentWayPointRankInRoute = self.wptRankFromRouteNameAndWptName(self.currentWPTRouteName, self.currentWPTName)
        
        if currentWayPointRankInRoute == len(currentRouteWaypointsList) - 1:
            print("End of route : switching to MANU mode")
            self.currentWPTName = None
            self.currentWPTRouteName = None
            self.mode = "MANU"
        else:
            self.currentWPTName = self.currentParameters["ROUTES"][currentRouteRank]["WAYPOINTS"][currentWayPointRankInRoute + 1]["NAME"]
            return


    def run(self):
        lastDebugTime = 0
        while True:
            self.currentTime = time.time()
            self.handleUDP()

            try:
                self.currentHeading = self.myGPS.getGPSRoute()
                self.currentPosition = self.myGPS.getGPSPosition()
                self.currentSpeed = float(self.myGPS.getSpeed())
            except Exception:
                # print("Missing GPS data")
                continue


            if self.mode == "WAYPOINT":

                if not self.currentWPTRouteName:
                    print("No route selected for WPT mode. Falling back to MANU mode")
                    self.mode = "MANU"
                elif self.currentWPTName == None: # If no current waypoint is defined, select the closest one from current position
                    self.selectClosestWaypointFromCurrentRoute()
                    print("No current Waypoint, selecting closest waypoint", self.currentWPTName)
                
                # print("crurrent route", self.currentWPTRouteName)
                # print("current wpt", self.currentWPTName)
                wptData = self.wptDataFromRouteAndWPTName(self.currentWPTRouteName,self.currentWPTName)
                distAndBearingToWaypoint = calc.distAndBearingAtoB(self.currentPosition, wptData)

                # Set setPoint towards current waypoint
                self.setPoint = distAndBearingToWaypoint["BEARING"]
                self.currentWPTDistance = distAndBearingToWaypoint["DISTANCE"]

                # If getting close to the current waypoint, target the next waypoint of the route
                if self.currentWPTDistance <= self.currentParameters["WAYPOINT_SWITCHING_THRESHOLD"]:
                    print("Reached Waypoint, switching to next.")
                    self.selectNextWaypointFromCurrentRoute()

            if self.mode == "AUTO" or self.mode == "WAYPOINT":
                if(self.setPoint != None and self.currentHeading != None):
                    self.error = calc.smallestError(self.setPoint, self.currentHeading)
                    self.command = self.commandFromError()
                    self.myMotor.command(self.command["SPEED"], self.command["DIR"])
                    if self.currentTime - lastDebugTime >= 0.5:
                        print("MODE", self.mode, "ROUTE", self.currentWPTRouteName, "WPT", self.currentWPTName, "WPT_DIST", self.currentWPTDistance, "SET", self.setPoint, "CURRENT", self.currentHeading, "ERROR", self.error, "error rate", self.error_rate, "Cp", self.Cp, "Cd", self.Cd, "COMMAND", self.command, "Kp", self.Kp, "Kd", self.Kd)
                        lastDebugTime = self.currentTime


# ToDo
# Linearly interpolated coefficients
# Waypoint mode
# Handle configuration file
# Harmonize return values when no value is availble (None instead of "-" ?)
