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
    if latGPRMC[8] == "N":
        sign = 1
    elif latGPRMC[8] == "S":
        sign = -1
    retVal = sign * (60 * int(latGPRMC[0:2]) + float(latGPRMC[2:7]))
    retVal = float(retVal/60)
    # print(int(latGPRMC[0:2]))
    # print(float(latGPRMC[2:7]))
    print(latGPRMC, "->", retVal)
    return retVal

def lonGPRMCtoNumericDegrees(lonGPRMC):
    sign = None
    if lonGPRMC[9] == "E":
        sign = 1
    elif lonGPRMC[9] == "W":
        sign = -1
    retVal = sign * (60 * int(lonGPRMC[0:3]) + float(lonGPRMC[3:8]))
    retVal = float(retVal/60)
    # print(int(latGPRMC[0:2]))
    # print(float(latGPRMC[2:7]))
    print(lonGPRMC, "->", retVal)
    return retVal

def distAndBearingAtoB(pointAGPRMCCoordinates, pointBGPRMCCoordinates):
    latADeg = latGPRMCtoNumericDegrees(pointAGPRMCCoordinates["LATITUDE"])
    lonADeg = lonGPRMCtoNumericDegrees(pointAGPRMCCoordinates["LONGITUDE"])
    latBDeg = latGPRMCtoNumericDegrees(pointBGPRMCCoordinates["LATITUDE"])
    lonBDeg = lonGPRMCtoNumericDegrees(pointBGPRMCCoordinates["LONGITUDE"])
    res = Geodesic.WGS84.Inverse(latADeg, lonADeg, latBDeg, lonBDeg)
    retVal = {}
    retVal["DIST"] = int(res["s12"])
    bearing = int(res["azi1"])
    if bearing < 0:
        bearing = 360 + bearing
    retVal["BEARING"] = bearing
    return retVal

# print(distAndBearingAtoB(latAGPRMC, lonAGPRMC, latBGPRMC, lonBGPRMC))
