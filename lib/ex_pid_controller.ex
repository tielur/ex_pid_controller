defmodule ExPidController do
  @moduledoc """
  A discrete [PID controller](https://pidexplained.com/pid-controller-explained/) for feedback control loops.

  ## Concepts

  | Term | Description |
  |------|-------------|
  | **Set Point (SP)** | The target value (e.g. desired speed or temperature) |
  | **Process Value (PV)** | The current measured value being controlled |
  | **Error** | `SP - PV` — the difference between target and current |
  | **Output** | The correction signal sent to the actuator (e.g. throttle, valve) |

  The output is the sum of three terms:

  - **Proportional (P)** — reacts to the current error: `kP × Err`
  - **Integral (I)** — accumulates past error over time: `kI × Err × dt`
  - **Derivative (D)** — reacts to the rate of error change: `kD × (pErr - Err) / dt`

  ## Example

  Simulate a car cruise control loop targeting 60 mph from a starting speed of 40 mph:

      # Target speed and starting speed (mph)
      set_point = 60
      initial_speed = 40.0

      # vehicle_response simulates how much the throttle moves the car each cycle
      # (a simplified stand-in for real-world inertia and friction)
      vehicle_response = 0.5

      controller = ExPidController.new(kp: 0.8, ki: 0.2, kd: 0.1, cycle_time: 1)

      # Simulate 10 one-second control cycles
      {_controller, _speed} =
        Enum.reduce(1..10, {controller, initial_speed}, fn cycle, {controller, speed} ->
          controller = ExPidController.step(controller, set_point, speed)
          speed = speed + controller.output * vehicle_response
          IO.puts("Cycle \#{cycle}: speed=\#{Float.round(speed, 1)}, output=\#{Float.round(controller.output, 2)}")
          {controller, speed}
        end)

      # Cycle 1: speed=49.0, output=18.0
      # Cycle 2: speed=57.0, output=15.9
      # Cycle 3: speed=62.0, output=10.04
      # Cycle 4: speed=64.6, output=5.34
      # Cycle 5: speed=65.7, output=2.04
      # Cycle 6: speed=65.6, output=-0.07
      # Cycle 7: speed=65.0, output=-1.27
      # Cycle 8: speed=64.1, output=-1.82
      # Cycle 9: speed=63.1, output=-1.94
      # Cycle 10: speed=62.2, output=-1.79
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

  def step(%ExPidController{} = controller, set_point, process_value) do
    error = error(set_point, process_value)
    proportional = proportional(controller.kp, set_point, process_value)
    integral = integral(controller.ki, set_point, process_value, controller.cycle_time)
    integral_total = controller.integral_total + integral
    derivative = derivative(controller.kd, set_point, process_value, controller.previous_error, controller.cycle_time)
    output = proportional + integral_total + derivative

    %{controller | previous_error: error, integral_total: integral_total, error: error, output: output}
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
