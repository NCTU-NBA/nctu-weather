<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" href="http://overpass-30e2.kxcdn.com/overpass.css" />
    <link rel="stylesheet" href="https://rschiang.github.io/ntu-weather/assets/normalize.min.css" />
    <link rel="stylesheet" href="https://rschiang.github.io/ntu-weather/assets/chartist.min.css" />
    <link rel="stylesheet" href="https://rschiang.github.io/ntu-weather/assets/weather.css" />
    <script src="https://rschiang.github.io/ntu-weather/assets/chartist.min.js"></script>
    <script src="https://rschiang.github.io/ntu-weather/assets/chartist-plugin-pointlabels.min.js"></script>

    <title>天氣 – 國立交通大學, 臺灣</title>
    <meta name="description" content="今天要回學校，究竟交大現在有沒有在下雨呢？讓網路福利社告訴你！" />
    <meta property="og:site_name" content="網路福利社" />
    <meta property="og:title" content="國立交通大學, 臺灣 — 網路福利社 氣象" />
    <meta property="og:image" content="https://raw.githubusercontent.com/NCTU-NBA/nctu-weather/gh-pages/assets/social.png" />
    <meta property="og:url" content="http://weather.nctu.me" />

<%
    def value(text, default='N/A'):
        try:
            float_value = float(text)
            return round(float_value)
        except ValueError:
            return default
        end
    end

    def dec_value(text, default='N/A'):
        try:
            float_value = round(float(text), 1)
            if float_value < 0.1:
                return 0
            else:
                return float_value
            end
        except ValueError:
            return default
        end
    end
%>
</head>
<body>
    <a href="https://github.com/NCTU-NBA/nctu-weather"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png" alt="Fork me on GitHub"></a>
    <header class="section">
        <img alt="網路福利社" class="vendor logo" src="https://raw.githubusercontent.com/NCTU-NBA/nctu-weather/gh-pages/assets/logo.png" />
    </header>
<%
    if not defined('error'):
        humidity = dec_value(humidity)
        rain = dec_value(rain)
        rain_day = dec_value(rain_day)

        if rain > 0:
            weather_type = 'rainy'
        elif humidity < 75 and rain_day <= 0:
            weather_type = 'skies'
        else:
            weather_type = ''
        end
    else:
        weather_type = 'error'
    end
%>
    <section class="weather {{ weather_type }}">
        <div class="section">
            <h3>國立交通大學, 臺灣</h3>
% if defined('error'):
            <div class="temperature">
                <span class="current">--</span>
                <span class="unit">--</span>
            </div>
            <div class="dashboard">
                <ul>
                    <li>資訊暫時無法使用。</li>
                </ul>
            </div>
% else:
            <div class="temperature">
                <span class="current">{{ value(temperature, default='--') }}</span>
                <span class="unit">°C</span>
            </div>
            <div class="dashboard">
                <ul>
                    <li>本日氣溫 <em>{{ value(temp_min) }} – {{ value(temp_max) }} °C</em></li>
                    <li>風向 <span class="wind" style="transform: rotate({{ dec_value(wind_direction, default=0) - 90 }}deg)">➤</span> <em>{{ dec_value(wind_speed) }} m/s</em></li>
                    <li>氣壓 <em>{{ dec_value(pressure) }} hPa</em></li>
                    <li>降雨強度 <em>{{ rain }} mm/h</em></li>
                    <li>濕度 <em>{{ humidity }}%</em></li>
                    <li>本日降雨 <em>{{ rain_day }} mm</em></li>
                </ul>
            </div>
            <div class="chart">
                <div class="ct-chart primary" id="daily-chart"></div>
                <div class="ct-chart secondary" id="humid-chart"></div>
            </div>
            <div class="source">
                資料來源：{{ provider }}（最後更新：{{ date.strftime('%m/%d %H:%M') }}）
            </div>
% end
        </div>
    </section>
    <footer class="section">
        <div class="social">
            <iframe src="https://www.facebook.com/plugins/like.php?href=https%3A%2F%2Fwww.facebook.com%2FNCTUNBA%2F&width=77&layout=button_count&action=like&size=small&show_faces=true&share=false&height=21&appId" width="77" height="21" style="border:none;overflow:hidden" scrolling="no" frameborder="0" allowTransparency="true"></iframe>
            <iframe src="https://www.facebook.com/plugins/share_button.php?href=http%3A%2F%2Fweather.nctu.me&layout=button&size=small&mobile_iframe=true&width=62&height=20&appId" width="62" height="20" style="border:none;overflow:hidden" scrolling="no" frameborder="0" allowTransparency="true"></iframe>
        </div>
        <div class="meta">
            <a href="https://www.facebook.com/NCTUNBA" rel="external nofollow">交通大學網路福利社</a>
            <span class="hide">「總是為你撐起一把傘。」</span><br />
            National Chiao Tung University Network Benefit Association, 2016
        </div>
    </footer>
% if not defined('error'):
<%
    labels = []
    temperatures, humidities = [], []
    for data in daily:
        pm = data['date'].hour >= 12
        hour = data['date'].hour % 12
        if hour == 0:
            labels.append('"12pm"' if pm else '"12am"')
        else:
            labels.append('"{}{}"'.format(hour, 'pm' if pm else 'am'))
        end

        if not 'error' in data:
            temperatures.append(str(value(data['temperature'])))
            humidities.append(str(value(data['humidity'])))
        else:
            temperatures.append('NaN')
            humidities.append('NaN')
        end
    end
%>
    <script>
        (function() {
            var data = {
                labels: [ {{! ', '.join(labels) }} ],
                series: [[ {{! ', '.join(temperatures) }} ]]
            };

            var options = {
                axisX: { labelOffset: { x: -15, y: 0 } },
                axisY: { showLabel: false, showGrid: false },
                chartPadding: { top: 15, right: 15, bottom: 5, left: -21 },
                fullWidth: true, high: 40, low: 0,
                plugins: [
                    Chartist.plugins.ctPointLabels({
                        labelClass: 'ct-datalabel',
                        labelInterpolationFnc: function(x) { return x + '°' }
                    })
                ],
                showArea: true,
            };

            return new Chartist.Line('#daily-chart', data, options);
        })();

        (function() {
            var data = {
                series: [[ {{! ', '.join(humidities) }} ]]
            };

            var options = {
                axisX: { showLabel: false, showGrid: false },
                axisY: { showLabel: false, showGrid: false },
                chartPadding: { top: 96, right: 15, bottom: 5, left: -21 },
                fullWidth: true,
                plugins: [
                    Chartist.plugins.ctPointLabels({
                        labelClass: 'ct-datalabel',
                        labelInterpolationFnc: function(x) { return x + '%'; }
                    })
                ],
            };

            return new Chartist.Line('#humid-chart', data, options);
        })();
    </script>
% end
</body>
</html>
