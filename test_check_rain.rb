require "minitest/autorun"
require "minitest/mock"
require_relative "bike_notifier"

class TestCheckRain < Minitest::Test
  def setup
    @notifier = BikeNotifier.new
    weather_data = {
      "hourly" => {
        "precipitation" => Array.new(36) { 0.0 }
      }
    }
    @notifier.weather_data = weather_data
    @notifier.now = Time.new(2025, 4, 14, 9, 0, 0, "+09:00")
    def @notifier.fetch_weather
      true
    end

    def @notifier.notify(body)
      true
    end

    def @notifier.ping_snitch
      true
    end
  end

  def test_no_rain_expected
    result = @notifier.run
    refute result
  end

  def test_rain_expected_in_future
    # Modify the test data to have rain at 17:00
    @notifier.weather_data["hourly"]["precipitation"][17] = 1.0

    assert_equal "Rain expected in 8 hours at 5pm. Cover the bike!", @notifier.run
  end

  def test_rain_expected_soon
    @notifier.weather_data["hourly"]["precipitation"][10] = 1.0
    assert_equal "Rain expected in 1 hour at 10am. Cover the bike!", @notifier.run
  end

  def test_rain_expected_now
    @notifier.weather_data["hourly"]["precipitation"][9] = 1.0

    assert_equal "Rain expected now. Cover the bike!", @notifier.run
  end

  def test_rain_past
    @notifier.weather_data["hourly"]["precipitation"][8] = 1.0

    refute @notifier.run
  end
end
