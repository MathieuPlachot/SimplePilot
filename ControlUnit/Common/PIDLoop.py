import time



class PIDLoop:

    def __init__(self, Kp, Ki, Kd):

        self.Kp = Kp
        self.Ki = Ki
        self.Kd = Kd

        self.Cp = None
        self.Ci = None
        self.Cd = None
        self.C = None

        self.prevError = None
        self.lastDerivativeEvalTime = None
        self.derivativeStepSecs = 1

        self.setPoint = None

    def errorFromCurrentValue(self, value):
        return float(value) - float(self.setPoint)
        
    def outputFromCurrentValue(self, value):

        result = {}

        currentTime = time.time()

        error = self.errorFromCurrentValue(value)

        if self.prevError != None and self.lastDerivativeEvalTime != None:
            if currentTime - self.lastDerivativeEvalTime >= self.derivativeStepSecs:
                # delta_t = self.currentTime - self.prevTime
                delta_err = error - self.prevError
                self.error_rate = delta_err / self.derivativeStepSecs
                self.lastDerivativeEvalTime = currentTime
                self.prevError = error
                print("error, prev error, delta err, error_rate", error, self.prevError, delta_err, self.error_rate)
        else:
            self.lastDerivativeEvalTime = currentTime
            self.prevError = error
        
        self.Cp = self.Kp * error
        self.Cd = self.Kd * self.error_rate
        self.C = self.Cp + self.Cd

        return self.C

    # Getters and Setters
    
    def setSetPoint(self, setPoint):
        self.setPoint = setPoint
        self.prevError = None
        self.prevTime = None
        self.error_rate = 0

    def getSetPoint(self):
        return self.setPoint

    def setKp(self, Kp):
        self.Kp = Kp

    def getKp(self):
        return self.Kp

    def setKi(self, Ki):
        self.Ki = Ki

    def getKi(self):
        return self.Ki

    def setKd(self, Kd):
        self.Kd = Kd

    def getKd(self):
        return self.Kd

    def getCp(self):
        return self.Cp

    def getCd(self):
        return self.Cd

    def getCi(self):
        return self.Ci

    def getC(self):
        return self.C

    

    