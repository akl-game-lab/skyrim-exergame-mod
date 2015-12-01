import os
import sys
import subprocess
import time

def main():
	path_to_src_dir = os.path.dirname(os.getcwd()) + "\src"
	has_python_path = False
	try:
		pythonPath = sys.path
		for i in pythonPath:
			if path_to_src_dir == i:
				has_python_path = True
	except:
		has_python_path = False

	if (not has_python_path):
		command = "setx PYTHONPATH \"%PYTHONPATH%;" + path_to_src_dir
		subprocess.call(command)
		print("Added " + path_to_src_dir + " to your PYTHONPATH. You are now good to go with the mod!")
	else:
		print("Already has " + path_to_src_dir + " installed. You are good to go with the mod!")


if __name__ == "__main__":
	main()
	exit = raw_input("Press enter to exit")
