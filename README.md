# Tarearbol

[![Build Status](https://travis-ci.org/am-kantox/tarearbol.svg?branch=master)](https://travis-ci.org/am-kantox/tarearbol)
**Lightweight task manager, allowing retries, callbacks, assurance that the task succeeded, and more…**

## Installation

```elixir
def deps do
  [
    {:tarearbol, "~> 0.1"}
  ]
end
```

## Features

### Task supervision tree for granted

Add `:tarearbol` to the list of applications and you are all set.

### Infinite retries

```elixir
Tarearbol.ensure fn ->
  unless Enum.random(1..100) == 42, do: raise "Incorrect answer"
  {:ok, 42}
end

# some bad-case logging
{:ok, 42}
```

### Limited amount of retries

```elixir
Tarearbol.ensure fn ->
  raise "Incorrect answer"
end, attempts: 10

# some bad-case logging
{:error,
 %{job: #Function<20.87737649/0 in :erl_eval.expr/5>,
   outcome: {%RuntimeError{message: "Incorrect answer"},
    [{:erl_eval, :do_apply, 6, [file: 'erl_eval.erl', line: 668]},
     {Task.Supervised, :do_apply, 2,
      [file: 'lib/task/supervised.ex', line: 85]},
     {Task.Supervised, :reply, 5, [file: 'lib/task/supervised.ex', line: 36]},
     {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 247]}]}}}
```

### Delay between retries

```elixir
Tarearbol.ensure fn ->
  unless Enum.random(1..100) == 42, do: raise "Incorrect answer"
  {:ok, 42}
end, delay: 1000

# some slow bad-case logging
{:ok, 42}
```

### Callbacks

```elixir
Tarearbol.ensure fn ->
  unless Enum.random(1..100) == 42, do: raise "Incorrect answer"
  {:ok, 42}
end, on_success: fn data -> IO.inspect(data, label: "★") end,
     on_retry: fn data -> IO.inspect(data, label: "☆") end  

# some slow bad-case logging
# ⇓⇓⇓⇓ one or more of ⇓⇓⇓⇓
☆: %{cause: :on_raise,
  data: {%RuntimeError{message: "Incorrect answer"},
   [{:erl_eval, :do_apply, 6, [file: 'erl_eval.erl', line: 670]},
    {:erl_eval, :exprs, 5, [file: 'erl_eval.erl', line: 122]},
    {Task.Supervised, :do_apply, 2, [file: 'lib/task/supervised.ex', line: 85]},
    {Task.Supervised, :reply, 5, [file: 'lib/task/supervised.ex', line: 36]},
    {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 247]}]}}
# ⇑⇑⇑⇑ one or more of ⇑⇑⇑⇑
★: 42
{:ok, 42}
```

### Allowed options

- `attempts` integer, an amount of attempts before giving up, `0` for forever; default: `:infinity`
- `delay` the delay between attempts, default: `:none`;
- `raise`: when `true`, will raise after all attempts were unsuccessful, or return `{:error, outcome}` tuple otherwise, default: `false`;
- `accept_not_ok`: when `true`, any result save for `{:error, _}` will be accepted as correct, otherwise only `{:ok, _}` is treated as correct, default: `true`;
- `on_success`: callback when the task returned a result, default: `nil`;
- `on_retry`: callback when the task failed and scheduled for retry, default: `:debug`;
- `on_fail`: callback when the task completely failed, default: `:warn`.

for `:attempts` and `:delay` keys one might specify the following values:

- `integer` → amount to be used as is (milliseconds for `delay`, number for attempts);
- `float` → amount of thousands, rounded (seconds for `delay`, thousands for attempts);
- `:none` → `0`;
- `:tiny` → `10`;
- `:medium` → `100`;
- `:infinity` → `-1`, `:attempts` only.

### Task spawning

```elixir
Tarearbol.run_in fn -> IO.puts(42) end, 1_000 # 1 sec
Tarearbol.spawn fn -> IO.puts(42) end # immediately
```

### Increasing delay as in [`sidekiq`](https://github.com/mperham/sidekiq)

**pending**

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tarearbol](https://hexdocs.pm/tarearbol).
