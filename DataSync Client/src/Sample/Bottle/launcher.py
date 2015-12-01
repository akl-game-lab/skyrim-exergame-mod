#!/usr/bin/env python
import webbrowser
import threading
import sys
import os

# Argument used to open in a new tab, if possible.
new_tab = 2 
# Open a public URL, in this case, the web browser docs
url = "http://127.0.0.1:8000"

#Thread used to start the DataSync client
class BottleThread (threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
 
    def run(self):
        os.system("python Runkeeper_client.py")

#Thread used to open a new tab in browser on the URL defined above
class BrowserThread (threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        
    def run(self):
        webbrowser.open(url, new = new_tab)

def main():
    thread1 = BottleThread()
    thread2 = BrowserThread()

    thread1.start() 
    thread2.start()

if __name__ == "__main__":
    main()
