# Control motor through PWM



class PilotMotor:

    INWARDS = "INWARDS"
    OUTWARDS = "OUTWARDS"

    def __init__(self):
        self.EN_GPIO = 23 # GPIO23 Pin 16


        


    def command(self, speed, direction):
        # print("Motor ", speed, direction)

        # print("DUTY",speed)

        if speed > 98:
            speed = 98

        print("[MOTOR] Apply DUTY ", speed, "DIRECTION", direction)

    def stop(self):        
        print("[MOTOR] Apply STOP ")
        






