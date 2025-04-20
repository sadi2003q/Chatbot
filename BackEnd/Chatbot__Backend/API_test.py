# client.py

import requests


# Runnable with massage history

def get_square_from_server(number: int):
    url = "http://127.0.0.1:8000/square"
    payload = {"number": number}
    response = requests.post(url, json=payload)

    if response.status_code == 200:
        result = response.json()["result"]
        print(f"The square of {number} is {result}")
    else:
        print(f"Error: {response.status_code} - {response.text}")


if __name__ == "__main__":
    try:
        num = int(input("Enter a number: "))
        get_square_from_server(num)
    except ValueError:
        print("Please enter a valid integer.")
