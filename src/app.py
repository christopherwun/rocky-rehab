import sys

import asyncio



from PyQt5 import uic, QtWidgets

from PyQt5.QtCore import QSize, QTimer

from PyQt5.QtWidgets import QWidget, QGraphicsScene, QGraphicsPixmapItem

from PyQt5.QtGui import QImage, QPixmap

import pyqtgraph as pg

import numpy as np



from bleak import BleakScanner, BleakClient

from bleak.backends.characteristic import BleakGATTCharacteristic



import qasync

import time



# from gpiozero import Servo

# from gpiozero import Button

# from gpiozero import LED

# from gpiozero.tools import sin_values

# from gpiozero.pins.pigpio import PiGPIOFactory



# myFactory = PiGPIOFactory()



# BLE peripheral ID

ADDRESS = "58:BF:25:3A:FE:F6"  # EDIT THIS VARIABLE | Testing on MAC 92D177DF-6844-1998-90B5-74701C25897E | Testing on Windows 24:0A:C4:AD:94:36



'''DO NOT EDIT ANYTHING BELOW THIS for Part 1'''

UART_CHAR_UUID = "5212ddd0-29e5-11eb-adc1-0242ac120002"



qtDesignerFile = "mainwindow.ui"  # Enter file here.



class MyApp(QtWidgets.QWidget):

    def __init__(self, parent=None):

        super().__init__(parent)



        # initial variables

        self._client = None

        self._storedData = []

        self._device = None



        # GUI Set up, resize to size of raspberry pi screen

        self.resize(800, 480)

        self.init_UI()



        # Initialize timer for countdown

        self.timer = QTimer()

        self.timer.timeout.connect(self.update_countdown)

        self.countdown = 4

        self.led_countdown = 0

        self.punch_cooldown = 1



        # Initialize game variables

        self.score = 0

        self.highscore = 0

        self.thresh = 0

        self.bonus_enabled = False

        self.active = False

        self.punched = False

        self.mode = "start" # start, game

        # self.servo = Servo(17, min_pulse_width = 0.5/1000, max_pulse_width = 2.5/1000, pin_factory=myFactory)  # Adjusted to match the GPIO pin

        # self.servo.mid()

        # self.figure_servo = Servo(22, min_pulse_width = 0.5/1000, max_pulse_width = 2.5/1000, pin_factory=myFactory)

        # self.figure_servo.mid()

        # self.button = Button(2)

        self.btnOn = False

        # self.led = LED(27)

        # self.led.off()



    def init_UI(self):

        # establish main UI

        uic.loadUi(qtDesignerFile, self)



        # setup up plot, which is of class PlotWidget

        try:

            file = open("highscore.txt", "r")

        except:

            file = open("highscore.txt", "w")

            file.write("0")

            file.close()

            file = open("highscore.txt", "r")

        self.highscore = int(file.read())

        # self.hiscore_text.setText(f"Highscore: {self.highscore}")

        print(self.graphicsView.scene())

        self.scene = QGraphicsScene()

        self.graphicsView.setScene(self.scene)

        self.pic = QGraphicsPixmapItem()

        self.load("")

        # connect push buttons

        self.connectButton.clicked.connect(self.handle_connect)

        self.startButton.clicked.connect(self.game_setup)  # Corrected button name

        self.startButton.setEnabled(False)



    

    @qasync.asyncSlot()

    async def game_setup(self):

        # Builtin calibration period

        self.score = 0

        # self.servo.mid()



        self.status_text.setText("Punch three times (each time a number appears) to calibrate.")

        await asyncio.sleep(2)

        # self.led.blink(0.50, 1.5, 3)

        

        self.load("3")

        await asyncio.sleep(2)

        punch1 = 4 * np.mean(self._storedData[-200:])

        bg1 = 4 * np.mean(self._storedData[-50:])



        self.load("2")

        await asyncio.sleep(2)

        punch2 = 4 * np.mean(self._storedData[-200:])

        bg2 = np.mean(self._storedData[-50:])



        self.load("1")

        await asyncio.sleep(2)

        punch3 = 4 * np.mean(self._storedData[-200:])

        bg3 = 4 * np.mean(self._storedData[-50:])



        self.load("")



        thresh_values = [punch1 - bg1, punch2 - bg2, punch3 - bg3]

        self.thresh = 3*np.mean(thresh_values) + bg1

        self.thresh = max(self.thresh, 150)

        self.thresh = min(self.thresh, 100)

        self.bonus_enabled = False

        

        await self.play_game()

    

    def load(self, status):

        if status == "success":

            self.scene.clear()

            fname = "boom.jpg"

            x = 200

            y = 200

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "3":

            self.scene.clear()

            fname = "3.png"

            x = 100

            y = 100

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "2":

            self.scene.clear()

            fname = "2.png"

            x = 100

            y = 100

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "1":

            self.scene.clear()

            fname = "1.png"

            x = 100

            y = 100

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "gameover":

            self.scene.clear()

            fname = "gg.png"

            x = 300

            y = 200

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "punch":

            self.scene.clear()

            fname = "punch.png"

            x = 300

            y = 200

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        elif status == "oops":

            self.scene.clear()

            fname = "oops.jpg"

            x = 300

            y = 200

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)

        else:

            self.scene.clear()

            fname = "rocky_rehab2.png"

            x = 300

            y = 200

            image_qt = QImage(fname).scaled(x, y)

            self.pic = QGraphicsPixmapItem()

            self.pic.setPixmap(QPixmap.fromImage(image_qt))

            self.scene.setSceneRect(0, 0, x, y)

            self.scene.addItem(self.pic)



    @property

    def device(self):

        return self._device



    @property

    def client(self):

        return self._client



    async def build_client(self, device):

        if self._client is not None:

            await self._client.stop()

        self._client = BleakClient(self._device)

        await self.start()



    @qasync.asyncSlot()

    async def handle_connect(self):

        self.status_text.setText("Scanning for device...")  # Corrected widget name

        await self.handle_scan()

        self.status_text.setText("Connecting to device...")  # Corrected widget name

        await self.build_client(self._device)

        self.status_text.setText("Connected")  # Corrected widget name



        self.startButton.setEnabled(True)

        self.connectButton.setEnabled(False)



        await self.handle_stream()



    @qasync.asyncSlot()

    async def handle_scan(self):

        self._device = await BleakScanner.find_device_by_address(ADDRESS)

        self.status_text.setText("Found device")  # Corrected widget name



    @qasync.asyncSlot()

    async def start(self):

        await self.client.connect()



    @qasync.asyncSlot()

    async def handle_stream(self):

        await self.client.start_notify(UART_CHAR_UUID, self.notification_handler)



    @qasync.asyncSlot()

    async def handle_stop(self):

        await self.client.stop_notify(UART_CHAR_UUID)

        await self.client.disconnect()

        self._client = None

        self.status_text.setText('Device was disconnected.')  # Corrected widget name



    # def begin_calibration(self):

    #     # Start the countdown

    #     self.timer.start(1000)  # Start timer, update every second

    #     self.calibrateButton.setEnabled(False)  # Disable button during countdown



    #     # self.handle_stream() # Start stream



    def update_countdown(self):

        if self.mode == "start":

            pass

        # elif self.mode == "calibrate":

        #     if self.countdown > 0:

        #         if self.countdown > 3:

        #             self.status_text.setText("Get ready...")

        #         else:

        #             self.status_text.setText(f"Calibrating in {self.countdown} seconds...")

        #         self.countdown -= 1

        #     elif self.countdown == 0:

        #         self.status_text.setText("Punch!")

        #         self.countdown -= 1

        #     elif self.countdown == -1:

        #         self.timer.stop()  # Stop the timer

        #         self.countdown = 3  # Reset countdown

        #         # self.handle_stop()  # Stop stream

        #         self.calibrateButton.setEnabled(True)  # Enable button after countdown

        #     else:

        #         self.timer.stop()  # Stop the timer

        #         self.countdown = 3

        elif self.mode == "game":

            # Update countdown during game

            if self.countdown > 0:

                self.status_text.setText(f"Time remaining: {self.countdown} seconds")

                self.countdown -= 1



                # Deal with led countdown

                if self.active:

                    self.led_countdown -= 1

                    if self.led_countdown == 0:

                        self.active = False

                        # self.led.off()

                        self.load("")

                

                if (self.punch_cooldown > -1):

                    self.punch_cooldown -= 1

                    if self.punch_cooldown == 0:

                        self.punched = False

                    # if self.punch_cooldown == -1:
                        # self.figure_servo.source = 0

            elif (self.score >= 800) and (self.bonus_enabled != True):

                self.status_text.setText("Bonus round unlocked! 2x points!")

                self.countdown = 30

                self.bonus_enabled = True

            # End of game

            else:

                self.status_text.setText("Game over!")

                self.load("gameover")

                # self.figure_servo.source = 0

                # self.servo.mid()

                self.timer.stop()

                self.countdown = 30

                self.startButton.setEnabled(True)

                # self.calibrateButton.setEnabled(True)

                # self.connectButton.setEnabled(True)

                self.mode = "start"



                try:

                    file = open("highscore.txt", "r")

                except:

                    file = open("highscore.txt", "w")

                    file.write("0")

                    file.close()

                    file = open("highscore.txt", "r")

                highscore = int(file.read())

                if self.score > highscore:

                    file = open("highscore.txt", "w")

                    file.write(str(self.score))

                    file.close()

                    self.hiscore_text.setText(f"Highscore: {self.score}")

                else:

                    self.hiscore_text.setText(f"Highscore: {highscore}")

                file.close()



    @property

    def storedData(self):

        return self._storedData



    @property

    def curve(self):

        return self._curve



    def notification_handler(self, characteristic: BleakGATTCharacteristic, data: bytearray):

        """Simple notification handler which prints the data received."""

        convertData = list(data)

        print(np.mean(convertData))

        print(self.thresh)

        print(self.punched)

        oldData = np.mean(self._storedData)

        self.update_plot(convertData)

        if (self.punched and self.countdown >= 30):

            self.punched = False

        if (np.mean(convertData) > self.thresh and not self.punched and self.countdown < 30):

            print("punch detected")

            self.punched = True

            self.punch_cooldown = 1



    def update_plot(self, vals):

        self._storedData.append(vals)

        if len(self._storedData) > 500:

            self._storedData = self._storedData[-500:]

        # plotData = np.ravel(self._storedData)

        # self.curve.setData(plotData)



    def closeEvent(self, event):

        super().closeEvent(event)

        for task in asyncio.all_tasks():

            task.cancel()



    @qasync.asyncSlot()

    async def play_game(self):

        self.mode = "game"

        # self.servo.min()



        self.status_text.setText("Starting game now!")

        self.load("starting")





        self.handle_stream()  # Start stream

        self.countdown = 30

        self.punched = False

        self.startButton.setEnabled(False)

        self.connectButton.setEnabled(False)

        self.timer.start(1000)  # Start timer, update every second



        while self.mode == "game":

            # Randomly turn on and off the LED for 1, 2, or 3 seconds

            # Randomly generate a number between 1 and 3

            time = np.random.randint(2, 4)



            # Randomly generate a number between 0 and 30... 0 will mean activate, anything else is off

            led = np.random.randint(0, 20) # 30 so that 0 has a 1/30 chance of being selected, it is expected to get 1 every 30*0.1 = 3 seconds

            if (led == 0 and self.active == False): # if led is on and active is false

                self.active = True

                # self.led.on()

                self.led_countdown = 3

                # self.load("punch")

                # self.scene.addText("Punch NOW!")

                self.status_text.setText("Punch NOW!")

            else:

                # do nothing

                pass



            # If bonus round currently enable, add "trick" flashes

            if (self.bonus_enabled and self.active == False):

                trickflash = np.random.randint(0, 20)

                if (trickflash == 0):

                    # self.led.on()

                    await asyncio.sleep(0.1)

                    # self.led.off()



            

            # If the average is greater than 100, activate the servo

            if ((self.punched or self.button.is_pressed) and not self.btnOn): # Only if previously not on

                # do smth to servo

                # self.servo.mid()
# 
                self.btnOn = True

                if self.active:

                    self.load("success")

                    self.score += 100

                    if self.bonus_enabled:

                        self.score += 100

                    self.active = False

                    # self.led.off()

                    # self.figure_servo.source = sin_values()

                    # self.figure_servo.source_delay = 0.0025

                    await asyncio.sleep(0.5)

                    self.load("")

                else:

                    self.score -= 50

                    if self.bonus_enabled:

                        self.score -= 50

                    # self.load("oops")

                    await asyncio.sleep(0.5)

                    # self.load("")



                print("button on")

            elif ((not self.punched or not self.button.is_pressed) and self.btnOn): # Only if previously on

                # do smth to servo

                # self.servo.min()

                self.btnOn = False

                self.punched = False

                print("button off")



            # Update score

            self.score_text.setText(f"Score: {self.score}")



            # Delay for a bit to allow for the next iteration

            await asyncio.sleep(0.1)



def main(args):

    app = QtWidgets.QApplication(sys.argv)

    loop = qasync.QEventLoop(app)

    asyncio.set_event_loop(loop)

    a = MyApp()

    a.show()

    with loop:

        loop.run_forever()





if __name__ == "__main__":

    main(sys.argv)

    # await main(sys.argv)  # for jupyter notebooks

