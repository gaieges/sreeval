"""
© Evin Callahan

This is a simple script that will listen on a UDP port expecting a message in the format:

[17/06/2016 12:30] Time to leave

And will respond with a message in the following format:

{
  "message": "Time to leave",
  "container": "typhoid.gaieges.jedimasters.net",
  "hostname": "127.0.0.1",
  "timestamp": 1466184600
}
"""

import socket
import os
import json
import re

from dateutil.parser import parse

# overridable global vars
BIND_HOST = os.getenv('BIND_HOST', '0.0.0.0')
BIND_PORT = int(os.getenv('BIND_PORT', 1234))
MESSAGE_FORMAT = re.compile(r'\[([^\]]+)\]\s*(.*)')

# start listening on desired port
sock = socket.socket(socket.AF_INET,    # internet (use AF_INET6 for IPv6)
                     socket.SOCK_DGRAM) # udp
sock.bind((BIND_HOST, BIND_PORT))

# start doing work
print('waiting for messages..')
while True:
  data, addr = sock.recvfrom(1024) # buffer size

  if not data or data == 'X':
    continue

  msg = data.decode('utf-8')
  print(f'from {addr[0]} got: {msg}')

  try: # to get datestamp from message
    msg_match = MESSAGE_FORMAT.search(msg)
    msg_time = parse(msg_match.group(1))
    msg_content = msg_match.group(2)

    output = json.dumps({
      'message': msg_content,
      'container': socket.gethostname(),
      'hostname': addr[0],
      'timestamp': int(msg_time.strftime('%s')),
    })

    print(f'responding with: {output}\n')
    sock.sendto(bytes(f'{output}\n', 'utf-8'), addr)
  except Exception as e:
    err = json.dumps({'error': f'cant parse message: {e}'})
    print(err)
    sock.sendto(bytes(f'{err}\n', 'utf-8'), addr)



