from openai import OpenAI


client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input="Скажи 'привет' одним словом.",
)

print(response.output_text)
