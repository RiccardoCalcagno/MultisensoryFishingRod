import matplotlib.pyplot as plt
import pandas as pd
import os
import socket
import time
import re

# Setup an UDP server on 6969 port
server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.bind(("", 6969))
server.setblocking(0)

# Setup a dataframe to store the data aX, aY, aZ
df = pd.DataFrame(columns=["aX", "aY", "aZ"])
times = []

# Stop until enter is pressed
print("Press ENTER to start recording (then CTRL+C to stop it)...")
input()
print("Start Recording")
start_time = round(time.time() * 1000)

try:
    while True:
        try:
            data, addr = server.recvfrom(1024)
            data = data.decode("utf-8")
            datatype = data.split("/")[0]
            dataval = data.split("/")[1]
            typ = dataval.split(":")[0]
            val = dataval.split(":")[1]
            if datatype == "raw" and typ == "acc":
                valsplit = val.split(";")
                df.loc[len(df)] = [int(valsplit[0]), int(valsplit[1]), int(valsplit[2])]
                times.append(round(time.time() * 1000) - start_time)
        except BlockingIOError:
            pass
except KeyboardInterrupt:
    print("Stop Recording")

# Plot the data
plt.plot(times, df["aX"], label="aX", color="red")
plt.plot(times, df["aY"], label="aY", color="green")
plt.plot(times, df["aZ"], label="aZ", color="blue")
plt.xlabel("time (ms)")
plt.ylabel("acceleration (raw)")
plt.title("Accelerometer data recorded")
plt.legend()
fig = plt.gcf()
fig.set_size_inches(15, 8)

# Save the dataframe to a CSV file
print("Enter the name of the file (without extension):")
name=input()
while not re.match("^[a-zA-Z0-9_]*$", name):
    print("Error: the name can only contain letters, numbers and underscores")
    name=input()
if not os.path.exists("samples"):
    os.makedirs("samples")
if not os.path.exists("samples/plots"):
    os.makedirs("samples/plots")
if not os.path.exists("samples/data"):
    os.makedirs("samples/data")
num = 0
while os.path.exists("samples/data/" + name + "_" + str(num) + ".csv"):
    num += 1
df.to_csv("samples/data/" + name + "_" + str(num) + ".csv", index=False)
fig.savefig("samples/plots/" + name + "_" + str(num) + ".png", dpi=100)
print("Files saved")