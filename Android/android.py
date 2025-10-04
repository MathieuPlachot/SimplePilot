import kivy
from kivy.app import App
from kivy.uix.label import Label
from kivy.uix.gridlayout import GridLayout
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.popup import Popup
from kivy.clock import Clock

import socket


class MyGrid(GridLayout):
    def __init__(self, **kwargs):
        super(MyGrid, self).__init__(**kwargs)
        self.cols = 1

        layoutAutoManu = GridLayout()
        layoutAutoManu.cols = 2

        self.infoLabel = Label(text = "MODE / CURRENT / SETPOINT / HEARTBEAT", font_size = 80)
        self.add_widget(self.infoLabel)

        self.btnAuto = Button(text="AUTO", font_size=80)
        self.btnAuto.bind(on_press=self.sendModeAuto)
        layoutAutoManu.add_widget(self.btnAuto)

        self.btnManu = Button(text="MANU", font_size=80)
        self.btnManu.bind(on_press=self.sendModeManu)
        layoutAutoManu.add_widget(self.btnManu)

        self.add_widget(layoutAutoManu)

        self.btnSet = Button(text="SET", font_size=80)
        self.btnSet.bind(on_press=self.sendSet)
        self.add_widget(self.btnSet)


        layoutLR = GridLayout()
        layoutLR.cols = 2

        self.btnLeft = Button(text="<<<", font_size=80)
        self.btnLeft.bind(on_press=self.pressLeft)
        self.btnLeft.bind(on_release=self.releaseLeft)
        layoutLR.add_widget(self.btnLeft)

        self.btnRight = Button(text=">>>", font_size=80)
        self.btnRight.bind(on_press=self.pressRight)
        self.btnRight.bind(on_release=self.releaseRight)
        layoutLR.add_widget(self.btnRight)

        self.add_widget(layoutLR)

        self.UDP_IP = "192.168.1.95"
        self.UDP_PORT = 1234
        self.sock = socket.socket(socket.AF_INET, # Internet
                                socket.SOCK_DGRAM) # UDP
        self.sock.settimeout(0.1)
        

        Clock.schedule_interval(self.sendReceiveUpdate, 1)

    def sendModeAuto(self, instance):
        message = bytearray(b'\x01')
        self.sendCommand(instance, message)

    def sendModeManu(self, instance):
        message = bytearray(b'\x02')
        self.sendCommand(instance, message)

    def pressLeft(self, instance):
        self.sendLeft(instance)
        Clock.schedule_interval(self.sendLeft, 0.4)

    def releaseLeft(self, instance):
        Clock.unschedule(self.sendLeft)

    def sendLeft(self, instance):
        message = bytearray(b'\x03')
        self.sendCommand(instance, message)

    def pressRight(self, instance):
        self.sendRight(instance)
        Clock.schedule_interval(self.sendRight, 0.4)

    def releaseRight(self, instance):
        Clock.unschedule(self.sendRight)

    def sendRight(self, instance):
        message = bytearray(b'\x04')
        self.sendCommand(instance, message)

    def sendSet(self, instance):
        message = bytearray(b'\x05')
        self.sendCommand(instance, message)

    def sendReceiveUpdate(self, instance):
        message = bytearray(b'\x06')
        self.sendCommand(instance, message)
        try:
            data, addr = self.sock.recvfrom(64) # buffer size is 1024 bytes
            print("received message: ", data)
            self.infoLabel.text = str(data)[2:-1]
        except:
            pass

    def sendCommand(self, instance, message):
        try:
            MESSAGE = message

            # print("UDP target IP: %s" % UDP_IP)
            # print("UDP target port: %s" % UDP_PORT)
            print("message: %s" % MESSAGE)

            
            self.sock.sendto(MESSAGE, (self.UDP_IP, self.UDP_PORT))
            # raise Exception("Test")
        except Exception as e:
            print('Excp')
            popup = Popup(
                title='Popup Demo', content = Label(text=str(e)),
                auto_dismiss=False, size_hint=(None, None),
                size=(400, 400)
            )
            popup.open()

class MyApp(App):
    def build(self):
        return MyGrid()


if __name__ == "__main__":
    MyApp().run()