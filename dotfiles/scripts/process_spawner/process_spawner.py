import subprocess
import sys

command = sys.argv[1]

if __name__ == "__main__":
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = process.communicate()[0]
    exitCode = process.returncode

    if (exitCode == 0):
        print(output.decode('utf-8').strip())
    else:
        raise ProcessException(command, exitCode, output)
