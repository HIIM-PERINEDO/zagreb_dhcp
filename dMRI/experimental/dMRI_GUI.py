import tkinter as tk
import subprocess
import threading
import time
from tkinter import ttk


class App:
    def __init__(self, master):
        self.master = master
        master.title("My Application")
        self.process = None # to keep track of the running process

        # Set the style to the 'clam' theme
        style = ttk.Style()
        style.theme_use("clam")

        # Create dropdown menu
        self.selected_command_label = ttk.Label(master, text="Select command:")
        self.selected_command_label.pack()
        self.selected_command = tk.StringVar(master)
        self.selected_command.set("RUN PREPROCESS") # default value
        self.selected_command_dropdown = ttk.OptionMenu(master, self.selected_command, "RUN PREPROCESS", "RUN_PROCESS", "QC")
        self.selected_command_dropdown.pack()

        # Create pmr field
        self.pmr_label = ttk.Label(master, text="Enter PMR:")
        self.pmr_label.pack()
        self.pmr = ttk.Entry(master)
        self.pmr.pack()

        # Create run and stop buttons
        self.run_button = ttk.Button(master, text="Run", command=self.run_script)
        self.run_button.pack(side="left")
        self.stop_button = ttk.Button(master, text="Stop", command=self.stop_script, state="disabled")
        self.stop_button.pack(side="left")

        # Create text widget for output
        self.output_label = ttk.Label(master, text="Output:")
        self.output_label.pack()
        self.output = tk.Text(master, height=20)
        self.output.pack()
        

    def run_script(self):
        print("Run script")
        if self.process is not None:
            return # don't run if a script is already running
        selected_command = self.selected_command.get()
        pmr = self.pmr.get()
        if selected_command == "RUN PREPROCESS":
            #script = ["python", "preprocess.py", pmr]
            print("RUN PREPROCESS")
        elif selected_command == "RUN_PROCESS":
            #script = ["python", "process.py", pmr]
            print("RUN_PROCESS")
        elif selected_command == "QC":
            #script = ["python", "qc.py", pmr]
            print("QC")
        #self.process = subprocess.Popen(script, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.run_button.config(state="disabled")
        self.stop_button.config(state="normal")
        print("Waiting for 10 seconds...")
        #time.sleep(10)
        #self.update_output() # start thread to update output in real-time

    def update_output(self):
        """for line in iter(self.process.stdout.readline, b''):
            self.output.insert(tk.END, line.decode("utf-8"))
        self.process.communicate()"""
        self.run_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.process = None
        print("Update output")

    def stop_script(self):
        #self.process.terminate()
        self.run_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.process = None
        print("Stop")

root = tk.Tk()
app = App(root)
root.mainloop()
