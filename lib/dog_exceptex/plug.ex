defmodule DogExceptex.Plug do
  @moduledoc """
  Plug to hook into Phoenix/Plug pipeline errors.
  For reporting on errors that happen during a phoenix request.
  """

  defmacro __using__(_opts) do
    # Don't report on 404s originating from phoenix or ecto
    quote location: :keep do
      use Plug.ErrorHandler

      alias DogExceptex.ExceptionFormatter

      if :code.is_loaded(Phoenix) do
        defp handle_errors(_conn, %{reason: %Phoenix.Router.NoRouteError{}}), do: nil
      end

      if :code.is_loaded(Ecto) do
        defp handle_errors(_conn, %{reason: %Ecto.NoResultsError{}}), do: nil
      end

      defp handle_errors(conn, %{reason: reason, stack: stack}) do
        error_map = ExceptionFormatter.format_error(nil, crash_reason: {reason, stack})

        :gen_event.notify(
          Logger,
          {:error, :erlang.group_leader(),
           {unquote(__MODULE__), error_map.title, DateTime.utc_now(), error_map}}
        )
      end
    end
  end
end
