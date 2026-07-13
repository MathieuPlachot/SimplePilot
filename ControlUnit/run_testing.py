from Common import pilot
from Adapters.Testing import gps
from Adapters.Testing import motor

myPilot = pilot.Pilot(motor.PilotMotor, motor.PilotMotor(), gps.PilotGPS())
myPilot.run()
