# ExPidController

A PID (Proportional-Integral-Derivative) controller implementation in Elixir. PID controllers are feedback loop mechanisms used in control systems to continuously calculate an error value and apply a correction. Common use cases include cruise control, temperature regulation, and robotics.

## Concepts

| Term | Description |
|------|-------------|
| **Set Point (SP)** | The target value (e.g. desired speed or temperature) |
| **Process Value (PV)** | The current measured value being controlled |
| **Error** | `SP - PV` — the difference between target and current |
| **Output** | The correction signal sent to the actuator (e.g. throttle, valve) |

The three terms that make up the output:

- **Proportional (P)** — reacts to the current error: `kP × Err`
- **Integral (I)** — accumulates past error over time: `kI × Err × dt`
- **Derivative (D)** — reacts to the rate of error change: `kD × (pErr - Err) / dt`

Final output: `P + integral_total + D`

## Installation

Add `ex_pid_controller` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_pid_controller, "~> 0.1.0"}
  ]
end
```

## Usage

Create a controller with `ExPidController.new/1`, then call `ExPidController.step/3` on each control loop cycle. Each call returns an updated struct with all state and output fields set — pass it directly into the next cycle.

```elixir
# Initialize once
pid = ExPidController.new(
  kp: 1.0,
  ki: 0.5,
  kd: 0.25,
  cycle_time: 0.1   # seconds between cycles
)

# Each cycle:
pid = ExPidController.step(pid, 100, current_value)

# Read the output and apply to your actuator, then repeat next cycle
pid.output
```

## Example

Simulate a cruise control loop targeting 60 mph from a starting speed of 40 mph:

```elixir
pid = ExPidController.new(kp: 0.8, ki: 0.2, kd: 0.1, cycle_time: 1)

{_pid, _speed} =
  Enum.reduce(1..10, {pid, 40.0}, fn step, {pid, speed} ->
    pid = ExPidController.step(pid, 60, speed)
    speed = speed + pid.output * 0.5
    IO.puts("Step #{step}: speed=#{Float.round(speed, 1)}, output=#{Float.round(pid.output, 2)}")
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
```

## Running Tests

```bash
mix test
```
