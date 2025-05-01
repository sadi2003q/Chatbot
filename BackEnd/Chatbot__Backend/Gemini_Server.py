import json
import random
import os
import uuid
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
        self.file_name = ""
        self.instantiate_conversation()
        self.make_name_function = True
        self.uuid_prefix = ""

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
            self.file_name = os.path.join(folder, f"{unique_id}.json")  # Step 2: File path in folder
            with open(self.file_name, 'w') as f:
                json.dump([], f, indent=4)  # Step 3: Initialize with empty list
            self.history_record = self.file_name  # Save path to instance

    def make_name(self):
        prompt = PromptTemplate(
            template="""
            Please check according to this list of conversation : {conversation}
            if it is possible to assign a name for this Conversation or not. IF yes then please assign
            a simple name for this conversation. it should not contain any space or specialCharacter.
            because i will use this name as the file name.but can have underscore for better
            readability. and the name will contain 2 words not more such as if it is about water then 'Water_Definition'  
            just write me the name not a single word or alphabet extra extra. just the name.  
            """,
            input_variables=["conversation"]
        )
        chain = prompt | self.model | StrOutputParser()
        return chain.invoke({"conversation": self.history})

    def rename_History(self, new_name: str):
        start = random.randint(0, 22)
        unique_id = str(uuid.uuid4())[start: start + 7]
        new_path = f"conversations/{new_name + '__' + unique_id}.json"
        os.rename(self.file_name, new_path)
        self.file_name = new_path
        self.history_record = new_path

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

        if len(self.history) == 4 or len(self.history) == 5:
            main_name = self.make_name()
            print(f"new name : {main_name}")
            self.rename_History(main_name)

        return ai_message.content

