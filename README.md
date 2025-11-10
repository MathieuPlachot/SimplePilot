# Purpose

This is a Simple GPS based tiller pilot project (In Progress).

It aims at providing an easy to deploy and easy to use tiller pilot system with a user friendly control application running on several environments (Android, IOS, Linux, Mac, Windows), compatible with on-the-shelf components.

It is written in python for the control unit part, and in Flutter for the user interface part.

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

# Hardware Requirements

Following hardware is necessary:
* Control unit : A computer with Python and PWM output capability (Raspberry Pi Zero WH is used for development & testing)
* User interface : any Android, IOS, Mac, Linux or Windows device with Wifi (Debian & Android are used for development & testing)
* Motor driver board : any driver board converting PWM to you desired output voltage and current depending on the actuator used (this one is uesed for development & testing : https://www.amazon.fr/dp/B08DHW5HCQ)
* Linear actuator : any  fast enough linear actuator compatible with you driver board. Fast enough might depend on the boat and sea conditions, trial and error might be needed. (this one has been used for development & testing : https://www.amazon.fr/dp/B0CFYNY23P).

