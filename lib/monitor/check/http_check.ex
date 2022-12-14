defmodule Monitor.Check.HttpCheck do
  @behaviour Monitor.Check
  use Monitor.InstrumentationHelper

  @method_map %{
    "get" => :get,
    "post" => :post,
    "put" => :put,
    "head" => :head,
    "delete" => :delete
  }

  def run(check) do
    %{"host" => host, "scheme" => scheme, "method" => method_string, "path" => path} =
      check.config

    url = scheme <> "://" <> host <> path
    method = @method_map[String.downcase(method_string)]
    handle_resp(http_client().request(method, url))
  end

  defp handle_resp({:ok, %HTTPoison.Response{status_code: status, body: body}}) do
    case status do
      x when x in 200..299 -> {:ok, body}
      _ -> {:error, body}
    end
  end

  defp handle_resp({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp http_client do
    Application.get_env(:monitor, :http_client)
  end
end
