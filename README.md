# Purpose

This is a Simple GPS based tiller pilot project (In Progress).

It aims at providing an easy to deploy and easy to use tiller pilot system with a user friendly control application running on several environments (Android, IOS, Linux, Mac, Windows), compatible with on-the-shelf components.

It is written in python for the control unit part, and in Flutter for the user interface part.

<img width="1316" height="917" alt="SimplePilotAndroid" src="https://github.com/user-attachments/assets/da071ef6-ece0-460a-ad5e-ff9824d5b4d0" />

# Features

## Manual Mode (MANU)
The manual mode allows to directly control the tiller through the User Interface application by increments.

## Automatic Mode (AUTO)
The automatic mode lets the boat follow a GPS heading (setPoint) through PID control of the tiller speed and direction (configurable coefficients)

## Waypoint Mode (WPT)
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

# Configuration
## ControlUnit

The ControlUnit configuration file consists in a JSON with following schema :

```
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Navigation Control Configuration",
  "type": "object",
  "properties": {
    "PID_SETTINGS": {
      "type": "array",
      "description": "List of PID controller settings for different speeds",
      "items": {
        "type": "object",
        "properties": {
          "SPEED": { "type": "number" },
          "KP": { "type": "number" },
          "KI": { "type": "number" },
          "KD": { "type": "number" }
        },
        "required": ["SPEED", "KP", "KI", "KD"]
      }
    },
    "WAYPOINT_SWITCHING_THRESHOLD": {
      "type": "number",
      "description": "Distance threshold for switching to the next waypoint"
    },
    "ROUTES": {
      "type": "array",
      "description": "List of navigation routes",
      "items": {
        "type": "object",
        "properties": {
          "NAME": { "type": "string" },
          "WAYPOINTS": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "NAME": { "type": "string" },
                "LATITUDE": {
                  "type": "string",
                  "pattern": "^[0-9]{4,}\\.[0-9]+,[NS]$",
                  "description": "Latitude in degrees/minutes format with hemisphere (N/S)"
                },
                "LONGITUDE": {
                  "type": "string",
                  "pattern": "^[0-9]{5,}\\.[0-9]+,[EW]$",
                  "description": "Longitude in degrees/minutes format with hemisphere (E/W)"
                }
              },
              "required": ["NAME", "LATITUDE", "LONGITUDE"]
            }
          }
        },
        "required": ["NAME", "WAYPOINTS"]
      }
    }
  },
  "required": ["PID_SETTINGS", "WAYPOINT_SWITCHING_THRESHOLD", "ROUTES"]
}
```

Here is a sample configuration :

```
{
    "PID_SETTINGS": [
        {
            "SPEED": 2,
            "KP": 1,
            "KI": 2,
            "KD": 3
        },
        {
            "SPEED": 10,
            "KP": 10,
            "KI": 4,
            "KD": 6
        }
    ],
    "WAYPOINT_SWITCHING_THRESHOLD": 10,
    "ROUTES": [
        {
            "NAME": "ROUTE1",
            "WAYPOINTS": [
                {
                    "NAME": "ROUTE1_WPT1",
                    "LATITUDE": "4734.5942,N",
                    "LONGITUDE": "00216.6824,W"
                },
                {
                    "NAME": "ROUTE1_WPT2",
                    "LATITUDE": "4734.6194,N",
                    "LONGITUDE": "00216.4988,W"
                },
                {
                    "NAME": "ROUTE1_WPT3",
                    "LATITUDE": "4734.5756,N",
                    "LONGITUDE": "00216.4754,W"
                },
                {
                    "NAME": "ROUTE1_WPT4",
                    "LATITUDE": "4734.5588,N",
                    "LONGITUDE": "00216.6686,W"
                }
            ]
        }
    ]
}
```

# Usage
## Running the Control Unit Application

To launch the control unit application, run the following command from the RPi folder:

```
python3 pilot.py
```

# Interfaces
## Control Unit <-> User Interface Application
### Transport Layer

The interface between the Control Unit and the User Interface Application relies on UDP. The ControlUnit listens on port 50002 and replies on the request source port.

### Commands & Statuses

Commands are sent from the User Interface Application to the Control Unit, Statuses are sent back from the Control Unit to the User Interface Application.

Commands & Statuses use the JSON format.

Following Commands are defined (one command per UDP Frame):

| Command | Description | Parameters | Example |
|---|---|---|---|
|REFRESH|Send back Statuses|None|{"COMMAND":"REFRESH"}|
|SET|Use the current measured heading as its new setpoint.|None|{"COMMAND":"SET"}|
|SET_MODE|Switch mode to MODE|MODE (String: "AUTO"/"MANU"/"WAYPOINT")|{"COMMAND":"SET_MODE","MODE":"AUTO"}|
|APPLY_PARAMS|Apply (without saving) the parameters provided as a JSON string complying with the schema provided in the Configuration/ControlUnit section of this README.|PARAMS (String)|{"COMMAND":"APPLY_PARAMS","PARAMS":"{...}"|
|APPLY_SAVE_PARAMS|Apply and save the parameters provided as a JSON string complying with the schema provided in the Configuration/ControlUnit section of this README.|PARAMS (String)|{"COMMAND":"APPLY_PARAMS","PARAMS":"{...}"|
|INCREASE_SETPOINT|Increase the current setpoint by VALUE degrees|VALUE (Float)|{"COMMAND":"INCREASE_SETPOINT", "VALUE":12.7}|
|DECREASE_SETPOINT|Decrease the current setpoint by VALUE degrees|VALUE (Float)|{"COMMAND":"DECREASE_SETPOINT", "VALUE":12.7}|
|INCREASE_TILLER|Move the tiller in the direction of increasing heading at full duty cycle during DURATION seconds|DURATION (Float)|{"COMMAND":"INCREASE_TILLER","DURATION":0.5}|
|DECREASE_TILLER|Move the tiller in the direction of decreasing heading at full duty cycle during DURATION seconds|DURATION (Float)|{"COMMAND":"DECREASE_TILLER","DURATION":0.5}

Following Statuses are sent alltogether in a single UDP frame upon reception of a REFRESH Command:

| Key | Description | 
|---|---|
|MODE|current mode of the control unit (AUTO/MANU)|
|CURRENT|current heading measured by the control unit|
|SETPOINT|current setpoint targeted by the control unit|
|SPEED|current speed measured by the control unit|
|GPS_VALIDITY|validity status of GPS information provided to the control unit|
|PARAMS|Currently used parameters provided as a JSON string complying with the schema provided in the Configuration/ControlUnit section of this README|
