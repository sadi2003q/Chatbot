import json
import os
import uuid
from http.client import HTTPException
from fastapi import Body
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from dotenv import load_dotenv
from fastapi import FastAPI

load_dotenv()
app = FastAPI()


class Gemini_Server:
    def __init__(self):
        self.model = ChatGoogleGenerativeAI(model='gemini-2.0-flash', api_key=os.getenv('GOOGLE_API_KEY'))
        self.history = [
            SystemMessage(content="""
            You are Gemini, a smart, friendly, and helpful AI assistant developed to provide accurate and thoughtful responses. 
            Your primary goal is to assist users with a wide range of topics, including programming, design, science, writing, and everyday questions, in a way that is informative, respectful, and easy to understand.

            Always communicate clearly and concisely, adapting your tone to match the user's style. If the user is casual, be friendly and informal; if the user is formal, mirror their tone.

            Avoid making assumptions or providing inaccurate information. If you are unsure about something, say so. When appropriate, ask follow-up questions to better understand the user's intent or goal.

            Do not generate harmful, unethical, or biased content. Always remain professional and prioritize the user's safety and privacy.

            Keep answers relevant, creative when needed, and engaging. Avoid overly technical jargon unless requested. If code is involved, explain it clearly and make sure it works.

            Be proactive and helpful without being overly verbose. Your mission is to make the user's life easier, smarter, and more fun.
            
            answer will not contain any table. it can have list of information but not any table
            
            """)
        ]
        self.history_record = ""
        self.instantiate_conversation()

    def load_history(self):
        if self.history_record:
            with open(self.history_record, 'r') as f:
                records = json.load(f)
            self.history = []  # Clear current history
            for msg in records:
                if msg['type'] == 'SystemMessage':
                    self.history.append(SystemMessage(content=msg['content']))
                elif msg['type'] == 'HumanMessage':
                    self.history.append(HumanMessage(content=msg['content']))
                elif msg['type'] == 'AIMessage':
                    self.history.append(AIMessage(content=msg['content']))

    def generate_record(self):
        if not self.history_record and len(self.history) == 1:
            unique_id = str(uuid.uuid4())
            folder = "conversations"
            os.makedirs(folder, exist_ok=True)  # Step 1: Create folder if it doesn't exist
            filename = os.path.join(folder, f"{unique_id}.json")  # Step 2: File path in folder
            with open(filename, 'w') as f:
                json.dump([], f, indent=4)  # Step 3: Initialize with empty list
            self.history_record = filename  # Save path to instance

    def make_name(self):
        prompt = PromptTemplate(
            template="""
            Please check according to this list of conversation : {conversation} 
            if it is possible to assign a name for this Conversation or not. IF yes then please assign
            a simple name for this conversation.  
            """,
            input_variables=["conversations"]
        )
        chain = prompt | self.model | StrOutputParser()
        return chain.invoke({"self.history": self.history})

    def instantiate_conversation(self):
        self.history = [
            SystemMessage(content="""
                    You are Gemini, a smart, friendly, and helpful AI assistant developed to provide accurate and thoughtful responses. 
                    Your primary goal is to assist users with a wide range of topics, including programming, design, science, writing, and everyday questions, in a way that is informative, respectful, and easy to understand.

                    Always communicate clearly and concisely, adapting your tone to match the user's style. If the user is casual, be friendly and informal; if the user is formal, mirror their tone.

                    Avoid making assumptions or providing inaccurate information. If you are unsure about something, say so. When appropriate, ask follow-up questions to better understand the user's intent or goal.

                    Do not generate harmful, unethical, or biased content. Always remain professional and prioritize the user's safety and privacy.

                    Keep answers relevant, creative when needed, and engaging. Avoid overly technical jargon unless requested. If code is involved, explain it clearly and make sure it works.

                    Be proactive and helpful without being overly verbose. Your mission is to make the user's life easier, smarter, and more fun.
                    """)
        ]
        self.history_record = ""
        self.generate_record()

    def model_response(self, user_query):
        human_message = HumanMessage(content=user_query)
        self.history.append(human_message)
        ai_message = self.model.invoke(self.history)
        self.history.append(ai_message)
        print(f"AI : {ai_message.content}")

        if self.history_record:
            with open(self.history_record, 'r+') as f:
                records = json.load(f)
                records.append({'type': 'HumanMessage', 'content': human_message.content})
                records.append({'type': 'AIMessage', 'content': ai_message.content})
                f.seek(0)
                json.dump(records, f, indent=4)
                f.truncate()
        return ai_message.content


server = Gemini_Server()


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


if __name__ == "__main__":
    load_conversation('b8a46fb9-0ba4-44af-ab2f-f05b3ff9f183.json')

# uvicorn Gemini_Server:app --reload --host 0.0.0.0 --port 8000
