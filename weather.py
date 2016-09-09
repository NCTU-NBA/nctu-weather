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
    url = 'http://opendata.cwb.gov.tw/opendataapi?dataid=O-A0002-001&authorizationkey=' + os.environ.get('CWB_API_KEY')
    request = requests.get(url)
    return request.content

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

def parse(text, rain_content):
    data = json.loads(text)
    xml_tree = ElementTree.fromstring(rain_content)
    ns = { 'cwb' : 'urn:cwb:gov:tw:cwbcommon:0.1' }
    location = xml_tree.find("./cwb:location/[cwb:stationId='C0D660']", namespaces=ns)
    rain = location.find("./cwb:weatherElement/[cwb:elementName='RAIN']/*/*", namespaces=ns).text
    now = location.find("./cwb:weatherElement/[cwb:elementName='NOW']/*/*", namespaces=ns).text
    date = datetime.fromtimestamp(data['dt']).strftime("%Y/%m/%d %H:%M:%S")
    if not date:
        print_err('ERR: Cannot find observing time. Check service availability.', Fore.RED, bright=True)
        print_err('Original string:')
        print_err(text, Fore.WHITE, bright=True)
        print_err('\n')
        raise Exception('Parse failed')

    return {
        'date': date,
        'temperature': data['main']['temp'],      # (˚C)
        'pressure': data['main']['pressure'],         # (hPa)
        'humidity': data['main']['humidity'],      # (%)
        'wind_speed': data['wind']['speed'],       # (m/s)
        'wind_direction': data['wind']['deg'],   # (˚)
        'rain': 0 if (rain == '-998.00') else float(rain),          # (mm/h)

        'temp_max': data['main']['temp_max'],         # (˚C)
        'temp_min': data['main']['temp_min'],         # (˚C)
        'rain_day': float(now),        # (mm)

        'provider': '中央氣象局, OpenWeatherMap under CC BY-SA 4.0',
    }

if __name__ == '__main__':
    from sys import stdout, exit
    text = fetch()
    rain_content = fetch_rain()
    data = parse(text, rain_content)
    json.dump(data, stdout, ensure_ascii=False, indent=2)
