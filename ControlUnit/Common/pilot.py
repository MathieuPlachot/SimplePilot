from Common.UDPHandler import UDPHandler
from Common.Utilities import calc
from Common.PIDLoop import PIDLoop
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
        self.currentHeading = None
        self.currentSpeed = None
        self.currentPosition = None
        self.myUDPHandler = UDPHandler()
        self.myUDPHandler.startListening()
        self.prevTime = None
        self.command = 0

        self.GPSPIDLoop = PIDLoop(
            self.currentParameters["PID_SETTINGS"]["KP"],
            self.currentParameters["PID_SETTINGS"]["KI"],
            self.currentParameters["PID_SETTINGS"]["KD"]
            )


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
                    self.GPSPIDLoop.setSetPoint(float(self.currentHeading))
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
                    speed = float(commandDict["SPEED"])
                    # duration = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_DURATION"]
                    # percentage = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_PERCENTAGE"]
                    self.myMotor.command(speed, self.motorClass.INWARDS)
                    time.sleep(duration)
                    self.myMotor.stop()
                    return
                else:
                    return # Not applicable in not MANU mode

            elif commandDict["COMMAND"] == UDPHandler.DECREASE_TILLER:
                if self.mode == "MANU":
                    duration = float(commandDict["DURATION"])
                    speed = float(commandDict["SPEED"])
                    # duration = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_DURATION"]
                    # percentage = self.currentParameters["MANUAL_MODE_SETTINGS"]["TILLER_IMPULSE_PERCENTAGE"]
                    self.myMotor.command(speed, self.motorClass.OUTWARDS)
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
                self.GPSPIDLoop.setKp(float(forcedCoeffs[0]))
                self.GPSPIDLoop.setKi(float(forcedCoeffs[1]))
                self.GPSPIDLoop.setKd(float(forcedCoeffs[2]))


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

    

    def getStatus(self):
        status = {}
        status["SETPOINT"] = self.GPSPIDLoop.getSetPoint()
        status["CURRENT"] = self.currentHeading
        status["GPSSTATE"] = self.myGPS.getStatus()
        status["MODE"] = self.mode
        status["SPEED"] = self.myGPS.getSpeed()
        status["LATITUDE"] = None
        status["LONGITUDE"] = None
        if self.currentPosition:
            try:
                status["LATITUDE"] = calc.latGPRMCtoNumericDegrees(self.currentPosition["LATITUDE"])
                status["LONGITUDE"] = calc.lonGPRMCtoNumericDegrees(self.currentPosition["LONGITUDE"])
            except Exception:
                print("Could not convert GPS position to numeric degrees")
        status["Kp"] = self.GPSPIDLoop.getKp()
        status["Kd"] = self.GPSPIDLoop.getKd()
        status["Ki"] = self.GPSPIDLoop.getKi()
        status["Cp"] = self.GPSPIDLoop.getCp()
        status["Cd"] = self.GPSPIDLoop.getCd()
        status["Ci"] = self.GPSPIDLoop.getCi()
        status["C"] = self.GPSPIDLoop.getC()
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


    def shutdown(self):
        print("Shutting down, stopping motor...")
        self.myMotor.stop()
        self.myMotor.cleanup()

    def run(self):
        lastDebugTime = 0
        try:
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
                    if(self.GPSPIDLoop.getSetPoint() != None and self.currentHeading != None):
                        # self.error = calc.smallestError(self.setPoint, self.currentHeading)
                        # self.command = self.commandFromError()
                        gpsPIDoutput = self.GPSPIDLoop.outputFromCurrentValue(self.currentHeading)

                        self.command = {}

                        if abs(gpsPIDoutput) < int(self.currentParameters["PID_SETTINGS"]["DEAD_ZONE_PERCENTAGE"]):
                            self.command["SPEED"] = 0
                        else:
                            self.command["SPEED"] = abs(gpsPIDoutput)

                        if gpsPIDoutput > 0 :
                            self.command["DIR"] = self.motorClass.OUTWARDS
                        else:
                            self.command["DIR"] = self.motorClass.INWARDS

                        self.myMotor.command(self.command["SPEED"], self.command["DIR"])

                        if self.currentTime - lastDebugTime >= 0.5:
                            # print("MODE", self.mode, "ROUTE", self.currentWPTRouteName, "WPT", self.currentWPTName, "WPT_DIST", self.currentWPTDistance, "SET", self.GPSPIDLoop.getSetPoint(), "CURRENT", self.currentHeading, "ERROR", self.error, "error rate", self.error_rate, "Cp", self.Cp, "Cd", self.Cd, "COMMAND", self.command, "Kp", self.Kp, "Kd", self.Kd)
                            lastDebugTime = self.currentTime
        except KeyboardInterrupt:
            self.shutdown()


# ToDo
# Waypoint mode
# Harmonize return values when no value is availble (None instead of "-" ?)
# Rework smallest error with new PIDLoop architecture
