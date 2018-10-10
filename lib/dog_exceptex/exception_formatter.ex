defmodule DogExceptex.ExceptionFormatter do
  def format_error(msg, meta) do
    case Keyword.get(meta, :crash_reason) do
      {reason, stacktrace} ->
        title = crash_title(reason, stacktrace)
        body = crash_body(stacktrace)
        aggregation_key = aggregation_key(title, {:stacktrace, stacktrace})
        %{title: title, body: body, key: aggregation_key}

      _reason ->
        if is_binary(msg) do
          title = msg
          body = inspect(meta)
          aggregation_key = aggregation_key(title, {:meta, Enum.into(meta, %{})})
          %{title: title, body: body, key: aggregation_key}
        else
          %{}
        end
    end
  end

  def crash_title(reason, stacktrace) do
    reason = Exception.normalize(:error, reason, stacktrace)

    :error
    |> Exception.format_banner(reason)
    |> String.trim("*")
    |> String.trim()
  end

  def crash_body(stacktrace) do
    Exception.format_stacktrace(stacktrace)
    |> String.split("\n")
    |> Stream.map(&String.trim(&1, "*"))
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&is_nil/1)
    |> Stream.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  def aggregation_key(title, {:stacktrace, stacktrace}) do
    String.slice(title, 0..40) <> (stacktrace |> List.first() |> inspect())
  end

  def aggregation_key(title, {:meta, %{file: file, line: line}}) do
    String.slice(title, 0..40) <> file <> to_string(line)
  end

  def aggregation_key(title, _) do
    String.slice(title, 0..40)
  end
end
