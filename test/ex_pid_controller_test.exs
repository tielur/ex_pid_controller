defmodule ExPidControllerTest do
  use ExUnit.Case
  doctest ExPidController

  # Helpers to call output with only the gains we care about for a given test
  defp call(opts) do
    defaults = [
      set_point: 100,
      process_value: 100,
      integral_total: 0,
      cycle_time: 1,
      previous_error: 0,
      gains: {1, 1, 1}
    ]

    merged = Keyword.merge(defaults, opts)

    ExPidController.output(
      set_point: merged[:set_point],
      process_value: merged[:process_value],
      integral_total: merged[:integral_total],
      cycle_time: merged[:cycle_time],
      previous_error: merged[:previous_error],
      gains: merged[:gains]
    )
  end

  describe "error" do
    test "is set_point minus process_value" do
      {error, _it, _out} = call(set_point: 100, process_value: 90)
      assert error == 10
    end

    test "is negative when process_value exceeds set_point" do
      {error, _it, _out} = call(set_point: 100, process_value: 110)
      assert error == -10
    end

    test "is zero when on target" do
      {error, _it, _out} = call(set_point: 100, process_value: 100)
      assert error == 0
    end
  end

  describe "proportional term" do
    test "scales error by kP" do
      # P = kP * Err = 2 * 10 = 20; kI=0, kD=0, integral_total=0
      {_err, _it, output} = call(
        process_value: 90,
        integral_total: 0,
        previous_error: 0,
        gains: {2, 0, 0}
      )

      assert output == 20
    end

    test "is zero when error is zero" do
      {_err, _it, output} = call(
        process_value: 100,
        gains: {5, 0, 0}
      )

      assert output == 0
    end

    test "is negative when process_value exceeds set_point" do
      {_err, _it, output} = call(
        process_value: 110,
        gains: {1, 0, 0}
      )

      assert output == -10
    end
  end

  describe "integral term" do
    test "increments integral_total each cycle" do
      # I_increment = kI * Err * dt = 1 * 10 * 1 = 10; It = 0 + 10 = 10
      {_err, integral_total, _out} = call(
        process_value: 90,
        integral_total: 0,
        gains: {0, 1, 0}
      )

      assert integral_total == 10
    end

    test "accumulates across calls" do
      first = call(process_value: 90, integral_total: 0, gains: {0, 1, 0})
      {_err, it_after_first, _out} = first

      {_err, it_after_second, _out} = call(
        process_value: 90,
        integral_total: it_after_first,
        gains: {0, 1, 0}
      )

      assert it_after_first == 10
      assert it_after_second == 20
    end

    test "scales with cycle_time" do
      # I_increment = kI * Err * dt = 1 * 10 * 0.5 = 5
      {_err, integral_total, _out} = call(
        process_value: 90,
        integral_total: 0,
        cycle_time: 0.5,
        gains: {0, 1, 0}
      )

      assert integral_total == 5
    end
  end

  describe "derivative term" do
    test "is positive when error is decreasing (approaching set_point)" do
      # D = kD * (pErr - Err) / dt = 1 * (20 - 10) / 1 = 10
      {_err, _it, output} = call(
        process_value: 90,
        previous_error: 20,
        gains: {0, 0, 1}
      )

      assert output == 10
    end

    test "is negative when error is increasing (moving away from set_point)" do
      # D = kD * (pErr - Err) / dt = 1 * (5 - 10) / 1 = -5
      {_err, _it, output} = call(
        process_value: 90,
        previous_error: 5,
        gains: {0, 0, 1}
      )

      assert output == -5
    end

    test "is zero when error is unchanged" do
      # D = kD * (pErr - Err) / dt = 1 * (10 - 10) / 1 = 0
      {_err, _it, output} = call(
        process_value: 90,
        previous_error: 10,
        gains: {0, 0, 1}
      )

      assert output == 0
    end

    test "scales with cycle_time" do
      # D = kD * (pErr - Err) / dt = 1 * (20 - 10) / 0.5 = 20
      {_err, _it, output} = call(
        process_value: 90,
        previous_error: 20,
        cycle_time: 0.5,
        gains: {0, 0, 1}
      )

      assert output == 20
    end
  end

  describe "combined output" do
    test "sums P + integral_total + D" do
      # Err = 100 - 90 = 10
      # P   = 1 * 10 = 10
      # I   = 1 * 10 * 0.5 = 5; It = 5 + 5 = 10
      # D   = 1 * (15 - 10) / 0.5 = 10
      # out = 10 + 10 + 10 = 30
      {_err, integral_total, output} = call(
        process_value: 90,
        integral_total: 5,
        cycle_time: 0.5,
        previous_error: 15,
        gains: {1, 1, 1}
      )

      assert integral_total == 10
      assert output == 30
    end

    test "returns zero output when on target with no accumulated integral" do
      {error, integral_total, output} = call(
        process_value: 100,
        integral_total: 0,
        previous_error: 0,
        gains: {1, 1, 1}
      )

      assert error == 0
      assert integral_total == 0
      assert output == 0
    end
  end
end
