import socket
import pandas as pd
import os
import tensorflow as tf
import numpy as np
import time


# Prepare Socket for transmission
print('\nPREPARING SOCKET FOR TRANSMISSION...')
SERVER_IP = "127.0.0.1"
SERVER_PORT = 5000
receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
receive_sock.bind((SERVER_IP, SERVER_PORT))

PROCESSING_IP = "127.0.0.1"
PROCESSING_PORT = 6969
send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 

# Load the TinyML model
print('LOADING TINYML MODEL...\n')
MODEL_PATH = 'model_16_1_2024'
model = tf.keras.models.load_model(MODEL_PATH)
print('\nSOCKET:\tREADY\nMODEL:\tREADY\nWAITING FOR DATA...\n')


LABELS = [
    "little_attracting",
    "long_attracting",
    "strong_hooking",
    "none",
    "long_NOT_attracting"
]

MODEL_INPUT_SIZE = 30 * 3  # before it was 30 * 3 
WINDOW_SIZE = 10 * 3
BUFFER_MAX_SIZE = MODEL_INPUT_SIZE + WINDOW_SIZE

BUFFER_MAX_SIZE_STRONG_HOOK = 3 * 3
MIN_DELAY_BETWEEN_TWO_DIFFERENT_STRONG_HOOKS = 0.3  # in seconds


buffer = []
buffer_for_strong_hook = []
prediction_buffer = []
time_last_strong_hook = 0



def sendPrediction(prediction):
    send_data = "tinyML/event:"+LABELS[prediction] #+"/variance: +str(variance)
    print('SEND:\t', send_data, "     Variance: ", variance)
    MESSAGE = bytes(send_data, 'utf-8')   
    send_sock.sendto(MESSAGE, (PROCESSING_IP, PROCESSING_PORT))



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
      max_acc = 32800
      x = int(values.split(';')[0]) / max_acc
      y = int(values.split(';')[1]) / max_acc 
      z = int(values.split(';')[2]) / max_acc
      buffer += [x, y, z]
      buffer_for_strong_hook += [y]


    if(len(buffer_for_strong_hook) == BUFFER_MAX_SIZE_STRONG_HOOK):
        Y = np.mean(buffer_for_strong_hook)
        if(y < 0.1 and ((time.time() - time_last_strong_hook) > MIN_DELAY_BETWEEN_TWO_DIFFERENT_STRONG_HOOKS)):       
            sendPrediction(2)
            time_last_strong_hook = time.time()
        del buffer_for_strong_hook[:1]
    

    if(len(buffer) == BUFFER_MAX_SIZE):
      del buffer[:WINDOW_SIZE] # remove the oldest data from the buffer
      inputs = np.array(buffer)

      # DATA ANALYSIS
      var_x = np.var(inputs[0::3]) # array[start:stop:step]
      var_y = np.var(inputs[1::3])
      var_z = np.var(inputs[2::3])
      variance = var_x + var_y + var_z

      early_var_x = np.var(inputs[(3 * 25)::3]) # array[start:stop:step]
      early_var_y = np.var(inputs[(3 * 25)+1::3])
      early_var_z = np.var(inputs[(3 * 25)+2::3])
      early_variance = early_var_x + early_var_y + early_var_z

      if early_variance < 0.003:
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
          if prediction == 1 and variance > 0.1: 
            prediction = 4 # long_NOT_attracting
          if prediction == 2:
            prediction = 0

      prediction_buffer.append(prediction)
      
      # OUTPUTs
      if len(prediction_buffer) == 1:
        # return the most frequent prediction from the last n predictions
        prediction = max(set(prediction_buffer), key=prediction_buffer.count)

        if((time.time() - time_last_strong_hook) > MIN_DELAY_BETWEEN_TWO_DIFFERENT_STRONG_HOOKS):
            sendPrediction(prediction)

        prediction_buffer.clear()


