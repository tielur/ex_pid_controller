defmodule ExPidController do
  @moduledoc """
  PID Controller Loop
  https://pidexplained.com/pid-controller-explained/

  The set point is normally a user entered value, in cruise control it would be the set speed, or for a heating system, it would be the set temperature.

  Process Value
  The process value is the value that is being controlled. For cruise control this would be the actual vehicle speed, or in a heating system, this would be the current temperature of the system.

  Output
  The output is the controlled value of a PID controller. In cruise control, the output would be the throttle valve, in a heating system, the output might be a 3 way valve in a heating loop, or the amount of fuel applied to a boiler.

  Error
  The error value is the value used by the PID controller to determine the how to manipulate the output to bring the process value to the set point.

  Error = Setpoint – Process Value

  ## Example

  Simulate a cruise control loop targeting 60 mph from a starting speed of 40 mph:

      pid = ExPidController.new(kp: 0.8, ki: 0.2, kd: 0.1, cycle_time: 1)

      {_pid, _speed} =
        Enum.reduce(1..10, {pid, 40.0}, fn step, {pid, speed} ->
          pid = ExPidController.step(pid, 60, speed)
          speed = speed + pid.output * 0.5
          IO.puts("Step \#{step}: speed=\#{Float.round(speed, 1)}, output=\#{Float.round(pid.output, 2)}")
          {pid, speed}
        end)

      # Step 1: speed=49.0, output=18.0
      # Step 2: speed=57.0, output=15.9
      # Step 3: speed=62.0, output=10.04
      # Step 4: speed=64.6, output=5.34
      # Step 5: speed=65.7, output=2.04
      # Step 6: speed=65.6, output=-0.07
      # Step 7: speed=65.0, output=-1.27
      # Step 8: speed=64.1, output=-1.82
      # Step 9: speed=63.1, output=-1.94
      # Step 10: speed=62.2, output=-1.79
  """

  defstruct kp: 0,
            ki: 0,
            kd: 0,
            cycle_time: 1,
            previous_error: 0,
            integral_total: 0,
            error: 0,
            output: 0

  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  def step(%ExPidController{} = pid, set_point, process_value) do
    error = error(set_point, process_value)
    proportional = proportional(pid.kp, set_point, process_value)
    integral = integral(pid.ki, set_point, process_value, pid.cycle_time)
    integral_total = pid.integral_total + integral
    derivative = derivative(pid.kd, set_point, process_value, pid.previous_error, pid.cycle_time)
    output = proportional + integral_total + derivative

    %{pid | previous_error: error, integral_total: integral_total, error: error, output: output}
  end

  # The Proportional math:
  # P = Proportional | kP = Proportional Gain | SP = Set point | PV = Process Value | Err = Error
  #
  # Err = SP – PV
  # P = kP x Err
  defp proportional(proportional_gain, set_point, process_value) do
    error = error(set_point, process_value)
    proportional_gain * error
  end

  # Integral math:
  # I = Integral | kI = Integral Gain | dt = cycle time of the controller | It = Integral Total
  #
  # I = kI x Err x dt
  # It = It + I
  defp integral(integral_gain, set_point, process_value, cycle_time) do
    integral_gain * error(set_point, process_value) * cycle_time
  end

  # The Derivative Math:
  # D = Derivative | kD = Derivative Gain | dt = cycle time of the controller | pErr = Previous Error
  #
  # D = kD x (pErr – Err) / dt
  defp derivative(derivative_gain, set_point, process_value, previous_error, cycle_time) do
    derivative_gain * (previous_error - error(set_point, process_value)) / cycle_time
  end

  defp error(set_point, process_value) do
    set_point - process_value
  end
end
