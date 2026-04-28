import json
import urllib.request
from urllib.error import HTTPError
code = "import 'dart:io';\nvoid main() {\n  int n = int.parse(stdin.readLineSync()!);\n  int sum = 0;\n  while (n > 0) {\n    sum += n % 10;\n    n ~/= 10;\n  }\n  print(sum);\n}\n"
body = json.dumps({'code': code, 'input': '123', 'timeout': 5}).encode('utf-8')
req = urllib.request.Request('http://127.0.0.1:8080/run_dart', data=body, headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as res:
        print(res.status)
        print(res.read().decode('utf-8'))
except HTTPError as e:
    print('status', e.code)
    print(e.read().decode('utf-8'))
