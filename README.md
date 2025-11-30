# Purpose

This is a Simple GPS based tiller pilot project (In Progress).

It aims at providing an easy to deploy and easy to use tiller pilot system with a user friendly control application running on several environments (Android, IOS, Linux, Mac, Windows), compatible with on-the-shelf components.

It is written in python for the control unit part, and in Flutter for the user interface part.

<img width="1316" height="917" alt="SimplePilotAndroid" src="https://github.com/user-attachments/assets/da071ef6-ece0-460a-ad5e-ff9824d5b4d0" />

# Features

## Manual Mode (MANU)
The manual mode allows to directly control the tiller through the User Interface application by imcrements.

# Automatic Mode (AUTO)
The automatic mode lets the boat follow a GPS heading (setPoint) through PID control of the tiller speed and direction (configurable coefficients)

# Waypoint Mode (WPT)
The Waypoint mode lets the boat follow a path defined by successive GPS waypoints (to be configured beforehand). The switching from the current waypoint to the next is made when the current waypoint is less than a configurable distance from the boat position.


# Architecture

The control unit:
* Retrieves route data from an NMEA compatible GPS
* Computes the command to be applied to the actuator connected to the tiller and output a PWM the to motor driver board

The motor driver board:
* Converts the PWM input from the control unit to voltage command to the motor

The user interface:
* Visualizes current mode (AUTO/MANU)
* Visualizes current GPS route
* Visualizes and set target GPS route
* Sets main parameters (PID controller coefficients, control unit IP address ...)

# Hardware & Software Requirements

Following hardware is necessary:
* Control unit : A computer with Python and PWM output capability (Raspberry Pi Zero WH is used for development & testing)
* User interface : any Android, IOS, Mac, Linux or Windows device with Wifi (Debian & Android are used for development & testing)
* Motor driver board : any driver board converting PWM to you desired output voltage and current depending on the actuator used (this one is uesed for development & testing : https://www.amazon.fr/dp/B08DHW5HCQ)
* Linear actuator : any  fast enough linear actuator compatible with you driver board. Fast enough might depend on the boat and sea conditions, trial and error might be needed. (this one has been used for development & testing : https://www.amazon.fr/dp/B0CFYNY23P).

# Installation

Yet to be written

# Usage
## Running the Control Unit Application

To launch the control unit application, run the following command from the RPi folder:

```
python3 pilot.py Kp Kd Ki
```

Kp, Kd, Ki being the PID coefficients to be used by the application (for example 1 10 0)

# Interfaces
## Control Unit <-> User Interface

The interface between the control unit application and the user interface application relies on UDP exchanges based on JSON format.

The general structure of commands from the user interface to the control unit is as follows :

{COMMAND:"cmd_name", PARAMETER_1:"param1_value", PARAMETER_2 ...}

Following commands are defined :

Command: "REFRESH"
Parameters: None
Purpose: request the control unit to send back statuses to the requester

Command: "SET"
Parameters: None
Purpose: request the control unit to use the current measured heading as its new setpoint.

Command: "SET_MODE"
Parameters: MODE
Purpose: request the control unit to switch its mode to MODE ("AUTO"/"MANU"/"WAYPOINT").

Command: "APPLY_PARAMS"
Parameters: KP, KI, KD
Purpose: ordrequester the control unit to apply (without saving) the parameters provided for KP, KD and KI coefficients.

Command: "APPLY_SAVE_PARAMS"
Parameters: KP, KI, KD
Purpose: request the control unit to apply and save the parameters provided for KP, KD and KI coefficients.

Command: "INCREASE_SETPOINT"
Parameters: VALUE
Purpose: request the control unit to increase the current setpoint by VALUE degrees.

Command: "DECREASE_SETPOINT"
Parameters: VALUE
Purpose: request the control unit to decrease the current setpoint by VALUE degrees.

Command: "INCREASE_TILLER"
Parameters: DURATION
Purpose: request the control unit to move the tiller towards increasing heading at full duty cycle during DURATION seconds.

Command: "DECREASE_TILLER"
Parameters: DURATION
Purpose: request the control unit to move the tiller towards decreasing heading at full duty cycle during DURATION seconds.

The statuses from the control unit application to the user interface application follow the below format :

{MODE:"mode", KP:"kp_value", KD:"kd_value", KI:"ki_value", CURRENT:"current_heading", SETPOINT:"setpoint", SPEED:"speed", GPS_VALIDITY:"gps_validity"}

with:
mode: current mode of the control unit (AUTO/MANU)
kp_value: current value of Kp coefficient used by the control unit
kd_value: current value of Kd coefficient used by the control unit
ki_value: current value of Ki coefficient used by the control unit
current_heading: current heading measured by the control unit
setpoints: current setpoint targeted by the control unit
speed: current speed measured by the control unit
gps_validity: validity status of GPS information provided to the control unit
