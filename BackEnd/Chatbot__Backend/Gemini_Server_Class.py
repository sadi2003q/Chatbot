from Gemini_Server import Gemini_Server
import json
import random
import os
import uuid
from http.client import HTTPException
from fastapi import Body
from dotenv import load_dotenv
from fastapi import FastAPI

server = Gemini_Server()
load_dotenv()
app = FastAPI()


@app.post("/instantiate")
def instantiate():
    server.instantiate_conversation()


@app.post("/model_response")
def model_response(request_data: dict):
    user_query = request_data['user_query']
    response = server.model_response(user_query)
    return {"response": response}


@app.post("/list_conversations")
def list_conversations():
    folder = "conversations"
    if not os.path.exists(folder):
        print("No 'conversations' folder found.")
        return []

    files = os.listdir(folder)
    print("Conversation Files:")
    return {"files": files}


# @app.post("/conversation_name")
# def conversation_name():


@app.post("/load_conversation")
def load_conversation(file: str = Body(..., embed=True)):  # Modify this line
    file_path = f"conversations/{file}"
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Conversation file not found")

    try:
        with open(file_path, 'r') as f:
            messages = json.load(f)
        return {"messages": messages}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading conversation: {str(e)}")


def test_rename_file(file_path: str):
    os.rename(file_path, "conversations/Random_name.json")


if __name__ == "__main__":
    test_rename_file("conversations/254fe654-7.json")

# uvicorn Gemini_Server:app --reload --host 0.0.0.0 --port 8000
