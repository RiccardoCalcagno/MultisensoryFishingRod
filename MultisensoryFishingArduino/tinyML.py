import socket
import pandas as pd
import tensorflow as tf
import numpy as np
   


# Prepare Socket for transmission
SERVER_IP = ""
SERVER_PORT = 6969

receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
receive_sock.bind((SERVER_IP, SERVER_PORT))
receive_sock.setblocking(0)


# # Load the TinyML model
model = tf.keras.models.load_model('model_11_1_2024')


LABELS = [
    "none",
    "little_attracting",
    "little_NOT_attracting",
    "long_attracting",
    "strong_hooking",
    "strong_NOT_hooking",
    "subtle"
]

MODEL_INPUT_SIZE = 100 * 3  # 100 data of the 3 axes
WINDOW_SIZE = 20 * 3
BUFFER_MAX_SIZE = MODEL_INPUT_SIZE + WINDOW_SIZE

buffer = []

while True:
  try:
    data, addr = receive_sock.recvfrom(1024) # buffer size is 1024 bytes
  except BlockingIOError:
     data = None

  if(data is not None):
    msg = data.decode('utf-8')
    #print("RECEIVE: %s" % msg)

    raw = msg.split('/')[1]
    values = raw.split(':')[1]
    if raw.startswith('acc'):
      max = 32800
      x = int(values.split(';')[0]) / max
      y = int(values.split(';')[1]) / max 
      z = int(values.split(';')[2]) / max
      buffer += [x, y, z]

    if(len(buffer) == BUFFER_MAX_SIZE):
      del buffer[:WINDOW_SIZE] # remove the oldest data from the buffer
      inputs = np.array(buffer)
      inputs = inputs[None, :] # add the batch dimension 
      output = model.predict(inputs)
      # if the prediction is less then a certain value of probability, the event is considered as NONE
      if np.max(output) < 0.7:  
        prediction = 0 # NONE
      else: 
        prediction = np.argmax(output)
      send_data = "tinyML/event:"+LABELS[prediction]
      print('SEND:\t', send_data)
      #MESSAGE = bytes(send_data, 'utf-8')
      #send_sock.sendto(MESSAGE, (PROCESSING_IP, PROCESSING_PORT))