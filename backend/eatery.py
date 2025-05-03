import os
import requests as tapi
import json
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_dining_menus():
    url = "https://now.dining.cornell.edu/api/1.0/dining/eateries.json"
    resp = tapi.get(url)
    resp.raise_for_status()
    data = resp.json()

    menus = {}
    for eatery in data.get("data", {}).get("eateries", []):
        name = eatery.get("name")
        items = {
            entry["item"]
            for day in eatery.get("operatingHours", [])
            for event in day.get("events", [])
            for category in event.get("menu", [])
            for entry in category.get("items", [])
            if entry.get("item")
        }
        menus[name] = sorted(items)
    return menus

def ask_top_meals(menus, goal="cutting", top_n=10):
    prompt = (
        f"You are a dietary expert. Given these campus dining hall menus:\n"
        f"{json.dumps(menus, indent=2)}\n\n"
        f"List the top {top_n} meals ideal for {goal}, numbered with a brief justification each."
    )

    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    return resp.choices[0].message.content

if __name__ == "__main__":
    menus = get_dining_menus()
    print(ask_top_meals(menus, goal="cutting", top_n=10))
