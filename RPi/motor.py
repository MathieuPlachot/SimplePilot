# Control motor through PWM


try:
    import RPi.GPIO as GPIO
    from rpi_hardware_pwm import HardwarePWM
except Exception as e:
    print("Import Failed")
    print(e)

class PilotMotor:

    INWARDS = "INWARDS"
    OUTWARDS = "OUTWARDS"

    def __init__(self, testing):

        self.testing = testing

        if self.testing:
            pass
        else:
            self.EN_GPIO = 23 # GPIO23 Pin 16
            GPIO.setmode(GPIO.BCM) # Broadcom pin-numbering scheme
            GPIO.setup(self.EN_GPIO, GPIO.OUT) # EN pin set as output
            
            self.IN1PWM = HardwarePWM(pwm_channel=0, hz=1000, chip=0) # Channel 0 is GPIO18 Pin 12
            self.IN2PWM = HardwarePWM(pwm_channel=1, hz=1000, chip=0) # Channel 1 is GPIO19 Pin 35
            self.IN1PWM.start(0)
            self.IN2PWM.start(0)

        


    def command(self, speed, direction):
        # print("Motor ", speed, direction)

        # print("DUTY",speed)

        if speed > 98:
            speed = 98

        if self.testing:
            print("[TESTING][Motor] Apply ", speed, direction)
            return
        
        GPIO.output(self.EN_GPIO, GPIO.HIGH)
        if direction == PilotMotor.INWARDS:
            self.IN1PWM.change_duty_cycle(0)
            self.IN2PWM.change_duty_cycle(speed)
        elif direction == PilotMotor.OUTWARDS:
            self.IN2PWM.change_duty_cycle(0)
            self.IN1PWM.change_duty_cycle(speed)

    def stop(self):

        if self.testing:
            print("[TESTING][Motor] Stop")
            return
        
        GPIO.output(self.EN_GPIO, GPIO.LOW)
        self.IN1PWM.change_duty_cycle(0)
        self.IN2PWM.change_duty_cycle(0)
        






