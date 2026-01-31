import urllib.request
import json

try:
    with urllib.request.urlopen("http://127.0.0.1:5000/api/cases") as response:
        data = json.loads(response.read().decode('utf-8'))
        if data['data']:
            first_case = data['data'][0]
            image_path = first_case['image']
            print("Image path from API:", image_path)
            
            static_url = f"http://127.0.0.1:5000/static/{image_path}"
            print("Testing URL:", static_url)
            
            with urllib.request.urlopen(static_url) as img_response:
                print("SUCCESS! Status:", img_response.status)
                print("Content-Type:", img_response.headers.get('Content-Type'))
        else:
            print("No cases found")
except Exception as e:
    print("Error:", str(e))
