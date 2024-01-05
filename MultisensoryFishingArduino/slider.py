import tkinter as tk
import socket
import ipaddress

client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ip_server = ""

def is_valid_ip(ip_str):
    try:
        ipaddress.ip_address(ip_str)
        return True
    except ValueError:
        return False

def update_value(value):
    label2.config(text=f"Valore: {value}")

# Funzione chiamata quando si sposta lo slider
def slider_changed(value):
    update_value(value)
    if ip_server != "":
        client.sendto(bytes(f"set/act:{value}\n", 'utf-8'), (ip_server, 6969))
    else:
        entry.config(bg="orange")

def button_clicked():
    global ip_server
    if is_valid_ip(entry.get()):
        ip_server = entry.get()
        entry.config(bg="green")
    else:
        entry.config(bg="red")

# Creazione della finestra principale
root = tk.Tk()
root.title("Vibration motors control")
root.geometry("300x600")

# Creazione di uno slider con valori compresi tra 0 e 255
slider = tk.Scale(root, from_=255, to=0, orient="vertical", length=400, width=25, command=slider_changed)
slider.grid(row=0, column=1, padx=0, pady=20)
slider.set(0)

# Creazione di una textbox per inserire l'indirizzo IP del server
label = tk.Label(root, text="IP:")
label.grid(row=2, column=0, padx=10, pady=20)
entry = tk.Entry(root, width=30)
entry.grid(row=2, column=1, padx=10, pady=20)

# Creazione di un pulsante per confermare l'IP del server
button = tk.Button(root, text="Enter", command=button_clicked)
button.grid(row=2, column=2, padx=10, pady=20)

# Etichetta per visualizzare il valore corrente dello slider
label2 = tk.Label(root, text="Valore: 0")
label2.grid(row=1, column=1, padx=0, pady=20)

# Aggiorna il valore iniziale
update_value(slider.get())

# Avvia il loop principale della finestra
root.mainloop()
