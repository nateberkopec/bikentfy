require "net/http"
require "json"
require "uri"
require "time"
require "tzinfo"

class BikeNotifier
  LATITUDE = ENV.fetch("LATITUDE")
  LONGITUDE = ENV.fetch("LONGITUDE")
  NTFY_TOPIC = ENV.fetch("NTFY_TOPIC")
  TIMEZONE = ENV.fetch("TIMEZONE")
  WEATHER_MODEL = ENV.fetch("WEATHER_MODEL")
  NOTIFY_URL = URI("https://ntfy.sh/#{NTFY_TOPIC}")
  METEO_URL = "https://api.open-meteo.com/v1/forecast"

  def debug(msg)
    puts(msg) if ENV["DEBUG"] == "true"
  end

  def weather_uri
    URI(METEO_URL).tap do |uri|
      uri.query = URI.encode_www_form(
        latitude: LATITUDE,
        longitude: LONGITUDE,
        hourly: "precipitation",
        timezone: TIMEZONE,
        models: WEATHER_MODEL,
        forecast_days: 3 # AFAIK the only options are 1 and 3, we really only need 2
      )
    end
  end

  def fetch_weather = JSON.parse(Net::HTTP.get_response(weather_uri).body)

  # returns number of hours until rain starts
  # if nil, no rain in next 24h
  def hours_until_rain(weather_data)
    current_hour = TZInfo::Timezone.get(TIMEZONE).now.hour
    debug "Current hour in #{TIMEZONE}: #{current_hour}"

    precip = weather_data.dig("hourly", "precipitation")

    debug "Precipitation for next 24 hours: #{precip[current_hour, 24]}"
    precip[current_hour, 24].find_index { |i| i > 0.0 }
  end

  def notify(time, hours)
    request = Net::HTTP::Post.new(NOTIFY_URL)

    request.body = notification_body(time, hours)

    debug "Sending: #{request.body}"
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  end

  def notification_body(hours_until)
    current_time = TZInfo::Timezone.get(TIMEZONE).now
    time_of_rain = current_time + 3600 * hours_until
    formatted_time = time_of_rain.strftime("%-I%p").downcase
    hour_word = (hours_until == 1) ? "hour" : "hours"

    "Rain expected in #{hours_until} #{hour_word} at #{formatted_time}. Cover the bike!"
  end

  def ping_snitch
    uri = URI("https://nosnch.in/#{ENV["SNITCH_ID"]}")
    debug "Pinging snitch."
    Net::HTTP.get_response(uri)
  end

  def run
    meteo_json = fetch_weather
    result = hours_until_rain(meteo_json)
    unless result
      debug "No rain expected in the next 24 hours."
      return
    end

    notify(result)
    ping_snitch if ENV["SNITCH_ID"]
  end
end
