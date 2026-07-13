from Common import pilot
from Adapters.Deployment import gps
from Adapters.Deployment import motor

myPilot = pilot.Pilot(motor.PilotMotor, motor.PilotMotor(), gps.PilotGPS())
myPilot.run()
