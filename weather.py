#!/usr/bin/env python3
import html
import json
import requests
import re
import os
from colorama import Fore, Style
from datetime import datetime
from sys import stderr
from xml.etree import ElementTree


def fetch():
    url = 'http://api.openweathermap.org/data/2.5/weather?q=Hsinchui&units=metric&APPID=' + os.environ.get('OPENWEATHER_API_KEY')
    request = requests.get(url)
    return request.text

def fetch_rain():
    url = 'http://opendata.epa.gov.tw/ws/Data/RainTenMin/?$filter=SiteId%20eq%20%27C0D660%27&$select=SiteId,Rainfall1hr,Now,PublishTime&$orderby=PublishTime%20DESC&$skip=0&$top=1000&format=json'
    request = requests.get(url)
    return request.text

def search_one(pattern, string):
    match = re.search(pattern, string)
    if match is not None:
        match = match.group(1).strip()
    return match

def print_err(text, color=Style.RESET_ALL, bright=False):
    if bright:
        stderr.write(Style.BRIGHT)
    stderr.write(color)
    stderr.write(text)
    stderr.write('\n')

def parse(text, rain_text):
    data = json.loads(text)
    rain_data = json.loads(rain_text)[0]
    date = datetime.fromtimestamp(data['dt']).strftime("%Y/%m/%d %H:%M:%S")
    if not date:
        print_err('ERR: Cannot find observing time. Check service availability.', Fore.RED, bright=True)
        print_err('Original string:')
        print_err(text, Fore.WHITE, bright=True)
        print_err('\n')
        raise Exception('Parse failed')

    return {
        'query_date': datetime.now().strftime("%Y/%m/%d %H:%M:%S"),
        'date': date,
        'temperature': data['main']['temp'],      # (˚C)
        'pressure': data['main']['pressure'],         # (hPa)
        'humidity': data['main']['humidity'],      # (%)
        'wind_speed': data['wind']['speed'],       # (m/s)
        'wind_direction': data['wind']['deg'],   # (˚)
        'rain': float(rain_data['Rainfall1hr']),          # (mm/h)

        'temp_max': data['main']['temp_max'],         # (˚C)
        'temp_min': data['main']['temp_min'],         # (˚C)
        'rain_day': float(rain_data['Now']),        # (mm)

        'provider': '中央氣象局/十分鐘雨量資料, OpenWeatherMap',
    }

if __name__ == '__main__':
    from sys import stdout, exit
    text = fetch()
    rain_text = fetch_rain()
    data = parse(text, rain_text)
    json.dump(data, stdout, ensure_ascii=False, indent=2)
