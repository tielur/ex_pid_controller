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
  """

  @doc """
  The Proportional math:
  P = Proportional | kP = Proportional Gain | SP = Set point | PV = Process Value | Err = Error

  Err = SP – PV
  P = kP x Err
  """
  defp proportional(proportional_gain, set_point, process_value) do
    error = error(set_point, process_value)
    proportional_gain * error
  end

  @doc """
  Integral math:
  I = Integral | kI = Integral Gain | dt = cycle time of the controller | It = Integral Total

  I = kI x Err x dt
  It = It + I
  """
  defp integral(integral_gain, set_point, process_value, cycle_time) do
    integral_gain * error(set_point, process_value) * cycle_time
  end

  @doc """
  The Derivative Math:
  D = Derivative | kD = Derivative Gain | dt = cycle time of the controller | pErr = Previous Error

  D = kD x (Err – pErr) / dt
  """
  defp derivative(derivative_gain, set_point, process_value, previous_error, cycle_time) do
    derivative_gain * (error(set_point, process_value) - previous_error) / cycle_time
  end

  @doc """
  returns:

  {previous_error, integral_total, output}
  """
  def output(
        set_point: set_point,
        process_value: process_value,
        integral_total: integral_total,
        cycle_time: cycle_time,
        previous_error: previous_error,
        gains: {proportional_gain, integral_gain, derivative_gain}
      ) do
    error = error(set_point, process_value)
    proportional = proportional(proportional_gain, set_point, process_value)
    integral = integral(integral_gain, set_point, process_value, cycle_time)
    integral_total = integral_total + integral
    derivative = derivative(derivative_gain, set_point, process_value, previous_error, cycle_time)
    {error, integral_total, proportional + integral_total + derivative}
  end

  defp error(set_point, process_value) do
    set_point - process_value
  end
end
