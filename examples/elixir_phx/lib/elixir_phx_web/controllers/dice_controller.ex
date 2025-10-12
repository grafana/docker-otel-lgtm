defmodule ElixirPhxWeb.DiceController do
  use ElixirPhxWeb, :controller
  require OpenTelemetry.Tracer, as: Tracer

  def roll(conn, params) do
    IO.inspect(params, label: "/rolldice params")
    result = roll_dice(6)

    conn
    |> put_status(:ok)
    |> json(%{result: result, sides: 6})
  end

  def roll_with_sides(conn, %{"sides" => sides}) do
    sides_int = String.to_integer(sides)

    # Add custom span with attributes
    Tracer.with_span "dice.roll_with_sides" do
      Tracer.set_attributes([
        {"dice.sides", sides_int},
        {"dice.type", "custom"}
      ])

      result = roll_dice(sides_int)
      sleep_time = Enum.take_every(100..1000, 100) |> Enum.random()

      Tracer.set_attribute("dice.result", result)
      Tracer.set_attribute("process.sleep", sleep_time)

      # Simulate some processing time
      Process.sleep(sleep_time)

      conn
      |> put_status(:ok)
      |> json(%{result: result, sides: sides_int})
    end
  rescue
    ArgumentError ->
      Tracer.record_exception(%ArgumentError{message: "Invalid sides parameter"})

      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid sides parameter"})
  end

  defp roll_dice(sides) when sides > 0 do
    Tracer.with_span "dice.generate_random" do
      Tracer.set_attributes([
        {"dice.sides", sides},
        {"operation.type", "random_generation"}
      ])

      result = Enum.random(1..sides)

      # Add some custom events
      Tracer.add_event("dice.rolled", [
        {"result", result},
        {"timestamp", System.system_time(:millisecond)}
      ])

      result
    end
  end

  defp roll_dice(_), do: raise(ArgumentError, "Sides must be greater than 0")
end
