defmodule ExPidControllerTest do
  use ExUnit.Case
  doctest ExPidController

  # Helpers to call step with only the fields we care about for a given test
  defp call(opts) do
    defaults = [
      set_point: 100,
      process_value: 100,
      integral_total: 0,
      cycle_time: 1,
      previous_error: 0,
      kp: 1,
      ki: 1,
      kd: 1
    ]

    merged = Keyword.merge(defaults, opts)

    controller = ExPidController.new(
      kp: merged[:kp],
      ki: merged[:ki],
      kd: merged[:kd],
      cycle_time: merged[:cycle_time],
      previous_error: merged[:previous_error],
      integral_total: merged[:integral_total]
    )

    ExPidController.step(controller, merged[:set_point], merged[:process_value])
  end

  describe "error" do
    test "is set_point minus process_value" do
      result = call(set_point: 100, process_value: 90)
      assert result.error == 10
    end

    test "is negative when process_value exceeds set_point" do
      result = call(set_point: 100, process_value: 110)
      assert result.error == -10
    end

    test "is zero when on target" do
      result = call(set_point: 100, process_value: 100)
      assert result.error == 0
    end
  end

  describe "proportional term" do
    test "scales error by kP" do
      # P = kP * Err = 2 * 10 = 20; kI=0, kD=0, integral_total=0
      result = call(
        process_value: 90,
        integral_total: 0,
        previous_error: 0,
        kp: 2, ki: 0, kd: 0
      )

      assert result.output == 20
    end

    test "is zero when error is zero" do
      result = call(
        process_value: 100,
        kp: 5, ki: 0, kd: 0
      )

      assert result.output == 0
    end

    test "is negative when process_value exceeds set_point" do
      result = call(
        process_value: 110,
        kp: 1, ki: 0, kd: 0
      )

      assert result.output == -10
    end
  end

  describe "integral term" do
    test "increments integral_total each cycle" do
      # I_increment = kI * Err * dt = 1 * 10 * 1 = 10; It = 0 + 10 = 10
      result = call(
        process_value: 90,
        integral_total: 0,
        kp: 0, ki: 1, kd: 0
      )

      assert result.integral_total == 10
    end

    test "accumulates across calls" do
      first = call(process_value: 90, integral_total: 0, kp: 0, ki: 1, kd: 0)
      second = ExPidController.step(first, 100, 90)

      assert first.integral_total == 10
      assert second.integral_total == 20
    end

    test "scales with cycle_time" do
      # I_increment = kI * Err * dt = 1 * 10 * 0.5 = 5
      result = call(
        process_value: 90,
        integral_total: 0,
        cycle_time: 0.5,
        kp: 0, ki: 1, kd: 0
      )

      assert result.integral_total == 5
    end
  end

  describe "derivative term" do
    test "is positive when error is decreasing (approaching set_point)" do
      # D = kD * (pErr - Err) / dt = 1 * (20 - 10) / 1 = 10
      result = call(
        process_value: 90,
        previous_error: 20,
        kp: 0, ki: 0, kd: 1
      )

      assert result.output == 10
    end

    test "is negative when error is increasing (moving away from set_point)" do
      # D = kD * (pErr - Err) / dt = 1 * (5 - 10) / 1 = -5
      result = call(
        process_value: 90,
        previous_error: 5,
        kp: 0, ki: 0, kd: 1
      )

      assert result.output == -5
    end

    test "is zero when error is unchanged" do
      # D = kD * (pErr - Err) / dt = 1 * (10 - 10) / 1 = 0
      result = call(
        process_value: 90,
        previous_error: 10,
        kp: 0, ki: 0, kd: 1
      )

      assert result.output == 0
    end

    test "scales with cycle_time" do
      # D = kD * (pErr - Err) / dt = 1 * (20 - 10) / 0.5 = 20
      result = call(
        process_value: 90,
        previous_error: 20,
        cycle_time: 0.5,
        kp: 0, ki: 0, kd: 1
      )

      assert result.output == 20
    end
  end

  describe "combined output" do
    test "sums P + integral_total + D" do
      # Err = 100 - 90 = 10
      # P   = 1 * 10 = 10
      # I   = 1 * 10 * 0.5 = 5; It = 5 + 5 = 10
      # D   = 1 * (15 - 10) / 0.5 = 10
      # out = 10 + 10 + 10 = 30
      result = call(
        process_value: 90,
        integral_total: 5,
        cycle_time: 0.5,
        previous_error: 15,
        kp: 1, ki: 1, kd: 1
      )

      assert result.integral_total == 10
      assert result.output == 30
    end

    test "returns zero output when on target with no accumulated integral" do
      result = call(
        process_value: 100,
        integral_total: 0,
        previous_error: 0,
        kp: 1, ki: 1, kd: 1
      )

      assert result.error == 0
      assert result.integral_total == 0
      assert result.output == 0
    end
  end
end
