from motor import PilotMotor
from gps import PilotGPS
from UDPHandler import UDPHandler
from Utilities import calc
from pathlib import Path
import time
import json
import sys
import numpy as np


class Pilot:

    def __init__(self):
        self.currentParameters = self.loadParamsFromConf()
        self.saveParamsToConf()
        self.myMotor = PilotMotor()
        self.myGPS = PilotGPS()
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
        self.error_rate = 0
        self.command = 0
        self.error = 0
        self.Cp = 0
        self.Ci = 0
        self.Cd = 0

    def saveParamsToConf(self):
        scriptDir = Path(__file__).parent
        confPath = scriptDir / ".pilotconf.txt"
        confFile = open(confPath, "w")
        confFile.write(json.dumps(self.currentParameters, indent = 4))
        confFile.close()
        return
    
    def loadParamsFromConf(self):
        scriptDir = Path(__file__).parent
        confPath = scriptDir / ".pilotconf.txt"        
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
                # self.currentParameters["KP"] = commandDict["KP"]
                # self.currentParameters["KI"] = commandDict["KI"]
                # self.currentParameters["KD"] = commandDict["KD"]
                return
            
            elif commandDict["COMMAND"] == UDPHandler.APPLY_SAVE_PARAMS:
                # self.currentParameters["KP"] = commandDict["KP"]
                # self.currentParameters["KI"] = commandDict["KI"]
                # self.currentParameters["KD"] = commandDict["KD"]
                # self.saveParamsToConf()
                return

        except Exception as e:
            print("Could not interpret UDP command")
            print(e)
            pass

    def interpolateCoeffWithSpeed(self, coeffName):

        speeds = []
        coeffValues = []

        for setting in self.currentParameters["PID_SETTINGS"]:
            speeds.append(setting["SPEED"])
            coeffValues.append(setting[coeffName])
        
        coeffValue = float(np.interp(self.currentSpeed, speeds, coeffValues))
        print(coeffName, coeffValue)
        return coeffValue

    def commandFromError(self):
        result = {}

        Kp = self.interpolateCoeffWithSpeed("KP")
        Ki = self.interpolateCoeffWithSpeed("KI")
        Kd = self.interpolateCoeffWithSpeed("KD")

        # print("Kp", Kp)

        # self.error_rate = 0

        if self.prevError != None and self.error != self.prevError:
            delta_t = self.currentTime - self.prevTime
            delta_err = self.error - self.prevError
            self.error_rate = delta_err / delta_t
            # print("delta err delta_t error_rate", delta_err, delta_t, self.error_rate)

        if self.prevError != self.error:
            self.prevTime = self.currentTime
        self.prevError = self.error
        
        self.Cp = Kp * self.error
        self.Cd = Kd * self.error_rate
        
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
        status["KP"] = 0 # self.currentParameters["KP"]
        status["KD"] = 1 # self.currentParameters["KD"]
        status["KI"] = 2 # self.currentParameters["KI"]
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
            except:
                print("Missing GPS data")
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
                    command = self.commandFromError()
                    self.myMotor.command(command["SPEED"], command["DIR"])
                    if self.currentTime - lastDebugTime >= 0.5:
                        print("MODE", self.mode, "ROUTE", self.currentWPTRouteName, "WPT", self.currentWPTName, "WPT_DIST", self.currentWPTDistance, "SET", self.setPoint, "CURRENT", self.currentHeading, "ERROR", self.error, "error rate", self.error_rate, "Cp", self.Cp, "Cd", self.Cd, "COMMAND", command)
                        lastDebugTime = self.currentTime

myPilot = Pilot()
myPilot.run()

# ToDo
# Linearly interpolated coefficients
# Waypoint mode
# Handle configuration file
# Harmonize return values when no value is availble (None instead of "-" ?)
