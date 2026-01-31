import urllib.request
import urllib.error

try:
    with urllib.request.urlopen("http://127.0.0.1:5000/api/cases") as response:
        print(f"Status: {response.status}")
        print(f"Response: {response.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}: {e.reason}")
    print(f"Response body: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
