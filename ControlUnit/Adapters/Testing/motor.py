# Control motor through PWM



class PilotMotor:

    INWARDS = "INWARDS"
    OUTWARDS = "OUTWARDS"

    def __init__(self):
        self.EN_GPIO = 23 # GPIO23 Pin 16


    def commandNumerical(self, commandValue):

        if commandValue > 0 :
            direction = PilotMotor.OUTWARDS
        else:
            direction = PilotMotor.INWARDS

        speed = abs(commandValue)
        
        self.commandSpeedDirection(speed, direction)


    def commandSpeedDirection(self, speed, direction):
        # print("Motor ", speed, direction)

        # print("DUTY",speed)

        if speed > 98:
            speed = 98

        print("[MOTOR][TESTING] Apply ", speed, direction)
        # print("[MOTOR] Apply DUTY ", speed, "DIRECTION", direction)

    def stop(self):
        print("[MOTOR][TESTING] Apply STOP ")

    def cleanup(self):
        print("[MOTOR][TESTING] Cleanup ")
        






