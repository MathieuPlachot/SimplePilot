import math

amin = 40.5
amax = 71
c = 26.5

for b in range (1,100):
    cosAMin = (amin*amin - b*b - c*c)/(-2*b*c)
    cosAMax = (amax*amax - b*b - c*c)/(-2*b*c)
    # alphaMin = math.acos()
    # alphaMax = math.acos((amax*amax - b*b - c*c)/(-2*b*c))
    if(cosAMax <= 1 and cosAMax >= -1 and cosAMin <= 1 and cosAMin >=-1):
        # print("B", b, "cos min", cosAMin, "cos max", cosAMax)
        alphaMin = math.degrees(math.acos(cosAMin))
        alphaMax = math.degrees(math.acos(cosAMax))
        middle = (alphaMax+alphaMin)/2
        print(b, alphaMin, alphaMax,middle)


