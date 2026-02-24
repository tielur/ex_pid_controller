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

## Running Tests

```bash
mix test
```
