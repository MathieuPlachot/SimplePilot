from geographiclib.geodesic import Geodesic

def smallestError(setPoint, currentHeading):
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

def latGPRMCtoNumericDegrees(latGPRMC):
    sign = None

    degrees = int(latGPRMC[0:2])
    minutes = float(latGPRMC[2:-2])
    direction = latGPRMC.split(",")[1]

    if direction == "N":
        sign = 1
    elif direction == "S":
        sign = -1
    
    totalMinutes = sign * (60 * degrees + minutes)
    totalDegrees = float(totalMinutes/60)
    # print("GPRMC ", latGPRMC, "degrees", degrees, "minutes", minutes, "direction", direction, "result", totalDegrees)
    return totalDegrees

def lonGPRMCtoNumericDegrees(lonGPRMC):
    sign = None

    degrees = int(lonGPRMC[0:3])
    minutes = float(lonGPRMC[3:-2])
    direction = lonGPRMC.split(",")[1]

    if direction == "E":
        sign = 1
    elif direction == "W":
        sign = -1
    totalMinutes = sign * (60 * degrees + minutes)
    totalDegrees = float(totalMinutes/60)
    # print("GPRMC ", lonGPRMC, "degrees", degrees, "minutes", minutes, "direction", direction, "result", totalDegrees)
    return totalDegrees

def distAndBearingAtoB(pointAGPRMCCoordinates, pointBGPRMCCoordinates):
    # print("point A", pointAGPRMCCoordinates)
    # print("point B", pointBGPRMCCoordinates)
    latADeg = latGPRMCtoNumericDegrees(pointAGPRMCCoordinates["LATITUDE"])
    lonADeg = lonGPRMCtoNumericDegrees(pointAGPRMCCoordinates["LONGITUDE"])
    latBDeg = latGPRMCtoNumericDegrees(pointBGPRMCCoordinates["LATITUDE"])
    lonBDeg = lonGPRMCtoNumericDegrees(pointBGPRMCCoordinates["LONGITUDE"])
    # print("Invert Problem", latADeg, lonADeg, latBDeg, lonBDeg)
    res = Geodesic.WGS84.Inverse(latADeg, lonADeg, latBDeg, lonBDeg)
    retVal = {}
    retVal["DISTANCE"] = int(res["s12"])
    bearing = int(res["azi1"])
    if bearing < 0:
        bearing = 360 + bearing
    retVal["BEARING"] = bearing
    # print(retVal)
    return retVal

# print(distAndBearingAtoB(latAGPRMC, lonAGPRMC, latBGPRMC, lonBGPRMC))
