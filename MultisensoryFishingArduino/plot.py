import matplotlib.pyplot as plt
import socket
import time
max_points = 100

ENC = 0
ACC_X = 1
ACC_Y = 2
ACC_Z = 3


def update_plot(typ, x, y):
    line[typ].set_xdata(x)
    line[typ].set_ydata(y)
    ax[typ].relim()
    ax[typ].autoscale_view()
    fig[typ].canvas.draw()
    fig[typ].canvas.flush_events()

fig = [None] * 4
ax = [None] * 4
line = [None] * 4

plt.ion()
fig[ENC], ax[ENC] = plt.subplots()
line[ENC], = ax[ENC].plot([0], [0])
ax[ENC].set_title('Encoder')
ax[ENC].set_xlabel('Time (ms)')
ax[ENC].set_ylabel('Velocity val')

fig[ACC_X], ax[ACC_X] = plt.subplots()
line[ACC_X], = ax[ACC_X].plot([0], [0])
ax[ACC_X].set_title('Accelerometer X')
ax[ACC_X].set_xlabel('Time (ms)')
ax[ACC_X].set_ylabel('Acceleration val')

fig[ACC_Y], ax[ACC_Y] = plt.subplots()
line[ACC_Y], = ax[ACC_Y].plot([0], [0])
ax[ACC_Y].set_title('Accelerometer Y')
ax[ACC_Y].set_xlabel('Time (ms)')
ax[ACC_Y].set_ylabel('Acceleration val')

fig[ACC_Z], ax[ACC_Z] = plt.subplots()
line[ACC_Z], = ax[ACC_Z].plot([0], [0])
ax[ACC_Z].set_title('Accelerometer Z')
ax[ACC_Z].set_xlabel('Time (ms)')
ax[ACC_Z].set_ylabel('Acceleration val')



server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.bind(('', 6969))
server.setblocking(0)


val_enc = []
time_enc = []
val_acc_x = []
time_acc_x = []
val_acc_y = []
time_acc_y = []
val_acc_z = []
time_acc_z = []

start_time = round(time.time() * 1000)
while True:
    try:
        data, addr = server.recvfrom(1024)
        data = data.decode('utf-8')
        data = data.split('/')[1]
        typ = data.split(':')[0]
        val = data.split(':')[1]
        if(typ == 'enc'):
            val = int(val)
            x = round(time.time() * 1000) - start_time
            time_enc.append(x)
            val_enc.append(val)
            time_enc = time_enc[-max_points:]
            val_enc = val_enc[-max_points:]
            update_plot(ENC, time_enc, val_enc)
        elif(typ == 'acx'):
            val = int(val)
            x = round(time.time() * 1000) - start_time
            time_acc_x.append(x)
            val_acc_x.append(val)
            time_acc_x = time_acc_x[-max_points:]
            val_acc_x = val_acc_x[-max_points:]
            update_plot(ACC_X, time_acc_x, val_acc_x)
        elif(typ == 'acy'):
            val = int(val)
            x = round(time.time() * 1000) - start_time
            time_acc_y.append(x)
            val_acc_y.append(val)
            time_acc_y = time_acc_y[-max_points:]
            val_acc_y = val_acc_y[-max_points:]
            update_plot(ACC_Y, time_acc_y, val_acc_y)
        elif(typ == 'acz'):
            val = int(val)
            x = round(time.time() * 1000) - start_time
            time_acc_z.append(x)
            val_acc_z.append(val)
            time_acc_z = time_acc_z[-max_points:]
            val_acc_z = val_acc_z[-max_points:]
            update_plot(ACC_Z, time_acc_z, val_acc_z)

    except BlockingIOError:
        plt.pause(0.001)