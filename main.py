import json
import requests
from time import sleep
import datetime
import os


class App:

    TIME_EVENT = 'TIME'

    def __init__(self, game, display_name):
        self._game = game
        self._display_name = display_name
        self._url = App._load_url()

    @staticmethod
    def _load_url():
        path = os.path.join(
            os.environ.get('PROGRAMDATA'),
            'SteelSeries',
            'SteelSeries Engine 3',
            'coreProps.json'
        )
        while not os.path.exists(path):
            print(f'SteelSeries Engine 3 not launched. Repeating check...')
            sleep(5)
        return json.load(open(path))['address']

    def register(self):
        metadata = {
            'game': self._game,
            'game_display_name': self._display_name,
        }
        r = requests.post(f'http://{self._url}/game_metadata', json=metadata)

    def start(self):
        self.register()
        self._bind()

    def _bind(self):
        raise NotImplementedError()

    def run(self):
        raise NotImplementedError()


class ClockApp(App):

    def __init__(self):
        super().__init__('CLOCK', 'Clock')

    def _bind(self):
        handler = {
            'game': self._game,
            'event': ClockApp.TIME_EVENT,
            'icon_id': 15,
            'handlers': [
                {
                    'device-type': 'screened',
                    'mode': 'screen',
                    'zone': 'one',
                    "datas": [
                        {
                            "icon-id": 15,
                            'has-text': True,
                            # 'bold': True,
                            'length-millis': 1100
                        }
                    ]
                }
            ]
        }
        r = requests.post(f'http://{self._url}/bind_game_event', json=handler)

    def send(self, time):
        data = {
            'game': self._game,
            'event': ClockApp.TIME_EVENT,
            'data': {'value': time}
        }
        r = requests.post(f'http://{self._url}/game_event', json=data)

    def run(self):
        print('Running clock app...')
        while True:
            now = datetime.datetime.now()
            self.send(now.strftime("%X"))
            sleep(0.25)


def main():
    app = ClockApp()
    app.start()
    app.run()


if __name__ == '__main__':
    main()
