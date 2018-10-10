defmodule DogExceptexTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  require Logger

  test "sends an event to Dogstatsd when error is logged" do
    {:ok, socket} = :gen_udp.open(60000, [:binary, {:active, true}])
    Application.put_env(:logger, :dog_exceptex, [statsd_host: "127.0.0.1", statsd_port: 60000])

    try do
      Logger.add_backend(DogExceptex.Logger)

      capture_log(fn -> Logger.error("A horrendous error occurred") end)

      assert_receive {:udp, _port, {127, 0, 0, 1}, _port_n, message}, 1000
      assert message =~ ~r/A horrendous error occurred/

    after
      :gen_udp.close(socket)
    end
  end
end
