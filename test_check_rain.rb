require "minitest/autorun"
require "minitest/mock"
require_relative "bike_notifier"

class TestCheckRain < Minitest::Test
  def setup
    @weather_data = {
      "hourly" => {
        "precipitation" => Array.new(36) { 0.0 }
      }
    }
    @notifier = BikeNotifier.new
    def @notifier.now
      Time.new(2025, 4, 14, 9, 0, 0, "+09:00")
    end
  end

  def test_no_rain_expected
    result = @notifier.hours_until_rain(@weather_data)
    refute result
  end

  def test_rain_expected_in_future
    # Modify the test data to have rain at 17:00
    @weather_data["hourly"]["precipitation"][17] = 1.0

    result = @notifier.hours_until_rain(@weather_data)

    assert_equal 8, result
  end

  def test_rain_expected_soon
    # Modify the test data to have rain at 10:00 (next hour)
    @weather_data["hourly"]["precipitation"][10] = 1.0

    result = @notifier.hours_until_rain(@weather_data)

    assert_equal 1, result
  end

  def test_rain_expected_now
    # Modify the test data to have rain at current time (09:00)
    @weather_data["hourly"]["precipitation"][9] = 1.0

    result = @notifier.hours_until_rain(@weather_data)

    assert_equal 0, result
  end

  def test_notification_body_now
    assert_equal "Rain expected now. Cover the bike!", @notifier.notification_body(0)
  end

  def test_notification_body_one_hour
    assert_equal "Rain expected in 1 hour at 10am. Cover the bike!", @notifier.notification_body(1)
  end

  def test_notification_body_two_hours
    assert_equal "Rain expected in 2 hours at 11am. Cover the bike!", @notifier.notification_body(2)
  end
end
