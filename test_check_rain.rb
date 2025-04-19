require "minitest/autorun"
require "minitest/mock"
require_relative "bike_notifier"

class TestCheckRain < Minitest::Test
  def setup
    @current_time = Time.new(2025, 4, 14, 9, 0, 0, "+09:00")
    @weather_data = {
      "hourly" => {
        "precipitation" => Array.new(36) { 0.0 }
      }
    }
    @notifier = BikeNotifier.new
  end

  def test_no_rain_expected
    Time.stub :now, @current_time do
      result = @notifier.hours_until_rain(@weather_data)
      refute result
    end
  end

  def test_rain_expected_in_future
    Time.stub :now, @current_time do
      # Modify the test data to have rain at 17:00
      @weather_data["hourly"]["precipitation"][17] = 1.0

      result = @notifier.hours_until_rain(@weather_data)

      assert_equal 8, result
    end
  end

  def test_rain_expected_soon
    Time.stub :now, @current_time do
      # Modify the test data to have rain at 10:00 (next hour)
      @weather_data["hourly"]["precipitation"][10] = 1.0

      result = @notifier.hours_until_rain(@weather_data)

      assert_equal 1, result
    end
  end

  def test_rain_expected_now
    Time.stub :now, @current_time do
      # Modify the test data to have rain at current time (09:00)
      @weather_data["hourly"]["precipitation"][9] = 1.0

      result = @notifier.hours_until_rain(@weather_data)

      assert_equal 0, result
    end
  end
end
