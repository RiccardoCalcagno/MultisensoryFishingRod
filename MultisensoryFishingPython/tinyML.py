import socket
import pandas as pd
import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
import tensorflow as tf
import numpy as np


   


# Prepare Socket for transmission
SERVER_IP = "127.0.0.1"
SERVER_PORT = 5000

receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
receive_sock.bind((SERVER_IP, SERVER_PORT))
receive_sock.setblocking(0)

PROCESSONG_IP = '127.0.0.1'
PROCESSING_PORT = 6969
send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


# # Load the TinyML model
model = tf.keras.models.load_model('model_16_1_2024')


LABELS = [
    "little_attracting",
    "long_attracting",
    "strong_hooking",
    "none",
    "long_NOT_attracting"
]

MODEL_INPUT_SIZE = 30 * 3  # 100 data of the 3 axes
WINDOW_SIZE = 15 * 3
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

      # DATA ANALYSIS
      var_x = np.var(inputs[0::3])
      var_y = np.var(inputs[1::3])
      var_z = np.var(inputs[2::3])
      variance = var_x + var_y + var_z
      if variance < 0.01:
        prediction = 3

      # MACHINE LEARNING
      else:
        inputs_ml = inputs[None, :] # add the batch dimension 
        output = model.predict(inputs_ml)
        # if the prediction is less then a certain value of probability, the event is considered as NONE
        if np.max(output) < 0.7:  
          prediction = 3 # NONE
        else: 
          prediction = np.argmax(output)
          if prediction == 1 and variance > 0.1: # long_NOT_attracting
            prediction = 4 
      
      # OUTPUTs
      send_data = "tinyML/event:"+LABELS[prediction] #+"/variance: +str(variance)
      print('SEND:\t', send_data)
      MESSAGE = bytes(send_data, 'utf-8')   
      send_sock.sendto(MESSAGE, (PROCESSONG_IP, PROCESSING_PORT))