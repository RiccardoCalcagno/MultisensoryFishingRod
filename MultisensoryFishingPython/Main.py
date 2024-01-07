import time
import zmq
import subprocess
import threading
import os
import serial
import keyboard
import signal
import atexit
import psutil


def launch_exe():
    # Sostituisci 'percorso_del_tuo_file.exe' con il percorso del tuo file exe
    script_dir = os.getcwd() #os.path.dirname(os.path.abspath(__file__))
    relative_exe_dir = os.path.join(script_dir, "OpenFace_2.2.0_win_x64")
    
    try:
        os.chdir(relative_exe_dir)
        print("running: ",os.path.join(relative_exe_dir, "HeadPoseLive.exe"))
        subprocess.run("HeadPoseLive.exe", shell=True)
    except Exception as e:
        print(f"Si è verificato un errore: {e}")

def start_exe_thread():
    exe_thread = threading.Thread(target=launch_exe)
    exe_thread.start()

def close_connection(socket, ser):
    if socket:
        socket.close()
    if ser and ser.isOpen():
        ser.close()
    print("closed Connection")
    for proc in psutil.process_iter(['pid', 'name']):
        if "HeadPoseLive.exe" in proc.info['name']:
            print(f"Closing process {proc.info['name']} with PID {proc.info['pid']}")
            proc.terminate()
            break  # Termina solo il primo processo trovato, se ce ne sono più di uno

def cleanup():
    close_connection(socket, ser)
def signal_handler(sig, frame):
    cleanup()
    exit(0)

def main():

    import zmq
    port = "5000"

    context = zmq.Context()
    socket = context.socket(zmq.SUB)

    print("Collecting head pose updates...")

    isSending = False

    socket.connect ("tcp://localhost:%s" % port)
    topic_filter = b"HeadPose:"
    socket.setsockopt(zmq.SUBSCRIBE, topic_filter)

    try:
        while True:
            head_pose = socket.recv().decode('utf-8') 
            head_pose = head_pose[9:].split(',')
            X = float(head_pose[0])
            Y = float(head_pose[2])
            Z = float(head_pose[4])
            data = '%.1f,%.1f,%.1f_' % (X, Y, Z)
            if(ser.isOpen()):
                ser.write(data.encode())
                if(isSending == False):
                    isSending = True
                    print("Is sending data.. Press 'q' to kill the process..")
            if keyboard.is_pressed("q"):  
                break
        print("Exits")
    except:
        pass
    finally:
        close_connection(socket, ser)

if __name__ == '__main__':
    #print(serial.tools.list_ports.comports())
    ser = serial.Serial('COM1', baudrate=115200)
    start_exe_thread()
    atexit.register(cleanup)
    signal.signal(signal.SIGINT, signal_handler)
    main()