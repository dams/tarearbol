defmodule Tarearbol.Job do
  @moduledoc false

  require Logger

  @default_ensure_opts [
    attempts: 0, delay: 0, raise: false, accept_not_ok: true,
    on_success: nil, on_retry: :debug, on_fail: :debug]
  @ensure_opts Application.get_env(:tarearbol, :ensure_opts, @default_ensure_opts)

  @task_retry Application.get_env(:tarearbol, :retry_log_prefix, "⚐")
  @task_fail Application.get_env(:tarearbol, :fail_log_prefix, "⚑")

  def ensure(job, opts \\ []) do
    attempts = Keyword.get(opts, :attempts, -1)
    opts = Keyword.delete(opts, :attempts)
    do_retry(job, Keyword.merge(@ensure_opts, opts), attempts)
  end
  def ensure!(job, opts \\ []) do
    with {:ok, result} <- ensure(job, opts) do
      result
    else
      data -> return_or_raise(job, data, true)
    end
  end

  ##############################################################################

  defmacrop on_problem(value, data, log_prefix) do
    quote do
      case unquote(value) do
        nil -> :ok
        level when is_atom(level) ->
          do_log(level, "[#{unquote(log_prefix)}] #{inspect unquote(data)}")
        fun when is_function(fun, 0) -> fun.()
        fun when is_function(fun, 1) -> fun.(unquote(data))
        _ -> :ok
      end
    end
  end

  defp do_log(level, message), do: Logger.log level, message

  defp return_or_raise(job, data, true),
    do: raise Tarearbol.TaskFailedError, outcome: data, job: job
  defp return_or_raise(job, data, false),
    do: {:error, %{outcome: data, job: job}}

  defp retry_or_die(cause, job, opts, data, retries_left) when retries_left == 0 do
    on_problem(opts[:on_fail], %{cause: cause, data: data}, @task_fail)
    return_or_raise(job, data, opts[:raise])
  end
  defp retry_or_die(cause, job, opts, data, retries_left) do
    on_problem(opts[:on_retry], %{cause: cause, data: data}, @task_retry)
    do_retry(job, opts, retries_left - 1)
  end

  defp do_retry(job, opts, retries_left) do
    case {opts[:accept_not_ok], job |> Tarearbol.Application.task!() |> Task.yield()} do
      {_, {:exit, data}} ->
        if is_integer(opts[:delay]), do: Process.sleep(opts[:delay])
        retry_or_die(:on_raise, job, opts, data, retries_left)
      {_, {:error, data}} ->
        if is_integer(opts[:delay]), do: Process.sleep(opts[:delay])
        retry_or_die(:on_error, job, opts, data, retries_left)
      {_, {:ok, {:error, data}}} ->
        if is_integer(opts[:delay]), do: Process.sleep(opts[:delay])
        retry_or_die(:on_error, job, opts, data, retries_left)
      {_, {:ok, {:ok, data}}} ->
        if is_function(opts[:on_success], 1), do: opts[:on_success].(data)
        {:ok, data}
      {true, {:ok, data}} ->
        if is_function(opts[:on_success], 1), do: opts[:on_success].(data)
        {:ok, data}
      {false, {:ok, data}} ->
        if is_integer(opts[:delay]), do: Process.sleep(opts[:delay])
        retry_or_die(:not_ok, job, opts, data, retries_left)
    end
  end

  # TODO: curry function passed, then start a task
  # def run(fun, args \\ []) when is_function(mod, length(args)),
  #   do: Tasl.Supervisor.start_child(Tarearbol.Application, mod, fun, args)

end