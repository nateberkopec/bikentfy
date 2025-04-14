# Bike Rain Alert

A simple Ruby script that checks for rain in the next 24 hours and sends a push notification via ntfy.sh if rain is expected. Perfect for reminding you to cover your bike!

## Features

- Checks Open-Meteo weather API for precipitation forecasts
- Sends push notifications via ntfy.sh
- Configurable location and timezone
- Runs daily via GitHub Actions

## Setup

1. Clone this repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Set up environment variables:
   ```bash
   export LATITUDE=45.000
   export LONGITUDE=100.000
   export NTFY_TOPIC=your-topic-name
   export TIMEZONE=Asia/Tokyo
   export WEATHER_MODEL=best_fit
   ```

## Usage

Run the script:
```bash
ruby check_rain.rb
```

For debug output:
```bash
DEBUG=true ruby check_rain.rb
```

## GitHub Actions

The script runs automatically every day at 17:00 JST via GitHub Actions. To customize:

1. Fork this repository
2. Update the environment variables in `.github/workflows/rain_alert.yml`
3. Enable GitHub Actions in your repository settings

## Configuration

- `LATITUDE`: Your location's latitude
- `LONGITUDE`: Your location's longitude
- `NTFY_TOPIC`: Your ntfy.sh topic name
- `TIMEZONE`: IANA timezone name (e.g., 'Asia/Tokyo')
- `WEATHER_MODEL`: Open-Meteo weather model (default: 'best_fit')
- `DEBUG`: Set to 'true' for debug output

## License

MIT License - see [LICENSE](LICENSE) for details.
