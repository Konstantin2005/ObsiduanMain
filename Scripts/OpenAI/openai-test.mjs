import OpenAI from "openai";

const client = new OpenAI();

const response = await client.responses.create({
  model: "gpt-5",
  input: "Скажи 'привет' одним словом.",
});

console.log(response.output_text);
