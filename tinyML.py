import socket
import pandas as pd
import tensorflow as tf
import numpy as np
   


# Prepare Socket for transmission
SERVER_IP = "127.0.0.1"
SERVER_PORT = 6000

receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
receive_sock.bind((SERVER_IP, SERVER_PORT))

PROCESSING_IP = "127.0.0.1"
PROCESSING_PORT = 6969

send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 


# # Load the TinyML model
model = tf.keras.models.load_model('model_6_1_2024')


LABELS = [
    "none",
    "little_attracting",
    "little_NOT_attracting",
    "long_attracting",
    "strong_hooking",
    "strong_NOT_hooking",
    "subtle"
]

buffer = []

while True:
  data, addr = receive_sock.recvfrom(1024) # buffer size is 1024 bytes

  if(data is not None):
    msg = data.decode('utf-8')
    print("RECEIVE: %s" % msg)

    raw = msg.split('/')[1]
    values = raw.split(':')[1]
    max = 32800
    x = int(values.split(';')[0]) / max
    y = int(values.split(';')[1]) / max 
    z = int(values.split(';')[2]) / max
    buffer += [x, y, z]

    if(len(buffer) == 300):
        inputs = np.array(buffer)
        inputs = inputs[None, :]
        output = model.predict(inputs)
        prediction = np.argmax(output,1)[0]
        send_data = "tinyML/event:"+LABELS[prediction]
        print('SEND:\t', send_data)
        MESSAGE = bytes(send_data, 'utf-8')
        send_sock.sendto(MESSAGE, (PROCESSING_IP, PROCESSING_PORT))
        buffer.clear()



