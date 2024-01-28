import asyncio
import signal
import json
from gmqtt import Client as MQTTClient
# no json

STOP = asyncio.Event()

def on_connect(client, flags, rc, properties):
    print('Connected')

def on_message(client, topic, payload, qos, properties):
    dict = json.loads(payload) # no json
    print(f'RECV MSG: {topic} {payload} {dict["topic"]}')

def on_disconnect(client, packet, exc=None):
    print('Disconnected')

def ask_exit(*args):
    STOP.set()

async def main(broker_host, port = 1883):
    client = MQTTClient("test-publisher")

    client.on_connect = on_connect
    client.on_disconnect = on_disconnect

    # Connectting the MQTT broker
    await client.connect(broker_host, port)

    json_msg = json.loads('{"topic": "mpu", "data": 4}')

    # Send the data of test
    client.publish("/mpu", json_msg)
    # make a function that does this ^
    # takes in topic and data

    await STOP.wait()
    await client.disconnect()

if __name__ == '__main__':
    loop = asyncio.new_event_loop()

    loop.add_signal_handler(signal.SIGINT, ask_exit)
    loop.add_signal_handler(signal.SIGTERM, ask_exit)

    host = '127.0.0.1'
    loop.run_until_complete(main(host))