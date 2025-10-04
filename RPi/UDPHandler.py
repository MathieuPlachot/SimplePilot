# Control motor through PWM

import socket
import threading
import time


class UDPHandler:

    REFRESH = b'\x06'
    AUTO = b'\x01'
    MANU = b'\x02'
    LEFT = b'\x03'
    RIGHT = b'\x04'
    SET = b'\x05'

    def __init__(self):

        UDP_IP = "192.168.1.95"
        UDP_PORT = 1234
        
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind((UDP_IP, UDP_PORT))
        self.sock.settimeout(3)

        self.listeningThread = threading.Thread(target=self.listen)

        self.listening = True

        self.lastCommand = None

    def getCommand(self):
        command = self.lastCommand
        self.lastCommand = None
        return command

    def listen(self):
        i = 0
        while self.listening:
            # print("Listening")
            try:
                data, addr = self.sock.recvfrom(1024) # buffer size is 1024 bytes
                self.lastCommand = data
            except:
                pass
                # print("Timeout")


    def start(self):
        self.listeningThread.start()

    def end(self):
        self.listening = False
        self.listeningThread.join()



# while True:
#     data, addr = sock.recvfrom(1024) # buffer size is 1024 bytes
#     print("received message: %s" % data)


# import time

# def crawl(link, delay=3):
#     print(f"crawl started for {link}")
#     time.sleep(delay)  # Blocking I/O (simulating a network request)
#     print(f"crawl ended for {link}")

# links = [
#     "https://python.org",
#     "https://docs.python.org",
#     "https://peps.python.org",
# ]

# # Start threads for each link
# threads = []
# for link in links:
#     # Using `args` to pass positional arguments and `kwargs` for keyword arguments
#     t = threading.Thread(target=crawl, args=(link,), kwargs={"delay": 2})
#     threads.append(t)

# # Start each thread
# for t in threads:
#     t.start()

# # Wait for all threads to finish
# for t in threads:
#     t.join()