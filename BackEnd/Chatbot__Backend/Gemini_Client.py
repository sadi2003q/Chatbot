import requests


def Model_Response(user_query):
    url = "http://127.0.0.1:8000/model_response"
    payload = {"user_query": user_query}
    headers = {'Content-Type': 'application/json'}

    try:
        model_response = requests.post(url, json=payload, headers=headers)
        result = model_response.json()
        return result.get("response", "No response found")
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
        return None


if __name__ == "__main__":

    while True:
        question = input("Enter your question: ")
        if question == "x":
            break
        response = Model_Response(question)
        if response:
            print(f"Result: {response}")

#  which is bigger 2 olr 5?
# multiply the bigger number by 10 and tell me what is this
