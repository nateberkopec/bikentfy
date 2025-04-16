#!/usr/bin/env ruby

require "minitest/autorun"
require "minitest/mock"
require_relative "check_rain"

class TestCheckRain < Minitest::Test
  def setup
    @current_time = Time.new(2025, 4, 14, 9, 0, 0, "+09:00")
    @weather_data = {
      "hourly" => {
        "time" => [
          "2025-04-14T00:00", "2025-04-14T01:00", "2025-04-14T02:00", "2025-04-14T03:00",
          "2025-04-14T04:00", "2025-04-14T05:00", "2025-04-14T06:00", "2025-04-14T07:00",
          "2025-04-14T08:00", "2025-04-14T09:00", "2025-04-14T10:00", "2025-04-14T11:00",
          "2025-04-14T12:00", "2025-04-14T13:00", "2025-04-14T14:00", "2025-04-14T15:00",
          "2025-04-14T16:00", "2025-04-14T17:00", "2025-04-14T18:00", "2025-04-14T19:00",
          "2025-04-14T20:00", "2025-04-14T21:00", "2025-04-14T22:00", "2025-04-14T23:00"
        ],
        "precipitation" => [
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        ]
      }
    }
  end

  def test_no_rain_expected
    Time.stub :now, @current_time do
      result = rain_info(@weather_data)
      refute result
    end
  end

  def test_rain_expected_in_future
    Time.stub :now, @current_time do
      # Modify the test data to have rain at 17:00
      @weather_data["hourly"]["precipitation"][17] = 1.0

      result = rain_info(@weather_data)

      assert result
      assert_equal 8, result[:hours_until]
      assert_equal Time.parse("2025-04-14T17:00"), result[:start_time]
    end
  end

  def test_rain_expected_soon
    Time.stub :now, @current_time do
      # Modify the test data to have rain at 10:00 (next hour)
      @weather_data["hourly"]["precipitation"][10] = 1.0

      result = rain_info(@weather_data)

      assert result
      assert_equal 1, result[:hours_until]
      assert_equal Time.parse("2025-04-14T10:00"), result[:start_time]
    end
  end

  def test_rain_expected_now
    Time.stub :now, @current_time do
      # Modify the test data to have rain at current time (09:00)
      @weather_data["hourly"]["precipitation"][9] = 1.0

      result = rain_info(@weather_data)

      assert result
      assert_equal 0, result[:hours_until]
      assert_equal Time.parse("2025-04-14T09:00"), result[:start_time]
    end
  end

  def test_find_rain_start_no_rain
    precip = [0.0] * 24
    times = (0..23).map { |h| "2025-04-14T#{h.to_s.rjust(2, '0')}:00" }

    assert_nil find_rain_start(precip, times, 0)
  end

  def test_find_rain_start_rain_in_future
    precip = [0.0] * 24
    precip[17] = 1.0  # Rain at 17:00
    times = (0..23).map { |h| "2025-04-14T#{h.to_s.rjust(2, '0')}:00" }

    assert_equal 17, find_rain_start(precip, times, 0)
  end

  def test_find_rain_start_rain_soon
    precip = [0.0] * 24
    precip[1] = 1.0  # Rain in next hour
    times = (0..23).map { |h| "2025-04-14T#{h.to_s.rjust(2, '0')}:00" }

    assert_equal 1, find_rain_start(precip, times, 0)
  end

  def test_find_rain_start_rain_now
    precip = [0.0] * 24
    precip[0] = 1.0  # Rain now
    times = (0..23).map { |h| "2025-04-14T#{h.to_s.rjust(2, '0')}:00" }

    assert_equal 0, find_rain_start(precip, times, 0)
  end

  def test_find_rain_start_multiple_rain_periods
    precip = [0.0] * 24
    precip[2] = 1.0  # First rain at 2:00
    precip[5] = 1.0  # Second rain at 5:00
    times = (0..23).map { |h| "2025-04-14T#{h.to_s.rjust(2, '0')}:00" }

    assert_equal 2, find_rain_start(precip, times, 0)  # Should find first rain
  end
end
