from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI()


class Number(BaseModel):
    number: int = Field("0", description="Number will be there")


@app.post("/square")
def square(number: Number):
    return {"result": number.number ** 2}

