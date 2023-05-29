defmodule Menshen do
  @moduledoc """
  TODO (doc)
  """

  @type nilable(type) :: type | nil
  @type user :: nilable(struct)
  @type action :: atom
  @type subject :: struct | module

  @type t :: %__MODULE__{
    status: :granted | :denied,
    user_data: any,
    module: module,
    line: Macro.Env.line,
    file: Macro.Env.file,
  }

  defstruct ~W[status user_data module line file]a

  defp new(status, env, user_data \\ nil) do
    %__MODULE__{
      status: status,
      module: env.module,
      file: env.file,
      line: env.line,
      user_data: user_data,
    }
    |> Macro.escape()
  end

  defmacro __using__(which)
    when is_atom(which)
  do
    apply(__MODULE__, which, [])
  end

  def view do
    quote do
      import unquote(__MODULE__), only: [can?: 3]
    end
  end

  def controller do
    quote do
      import unquote(__MODULE__), only: [authorize!: 3]
    end
  end

  defmacro grant() do
    new(:granted, __CALLER__)
  end

  defmacro deny(user_data \\ nil) do
    new(:denied, __CALLER__, user_data)
  end

  defp log_level(:granted), do: :info
  defp log_level(:denied), do: :warning

  defp log_result(:granted), do: "granted"
  defp log_result(:denied), do: "denied"

  def color_result(:granted), do: :green
  def color_result(:denied), do: :red

  defp last_non_menshen([{__MODULE__, _, _, _} | _stacktrace], last) do
    last
  end

  defp last_non_menshen([last | stacktrace], _last) do 
    last_non_menshen(stacktrace, last)
  end

  defp last_non_menshen([], last) do
    last
  end

  @type stack_item :: {module, atom, arity | [term], [{:file, String.t}, {:line, pos_integer}]}
  @spec extract_rule_from_stacktrace([stack_item]) :: nilable(stack_item)
  def extract_rule_from_stacktrace(stacktrace)
    when is_list(stacktrace)
  do
    stacktrace
    |> Enum.reverse()
    |> last_non_menshen(nil)
  end

  defp do_log_stacktrace(nil), do: []
  defp do_log_stacktrace({module, function, arity, info}) do
    [
      IO.ANSI.light_black(),
      ?\n,
      "↳ ",
      Exception.format_mfa(module, function, arity),
      log_stacktrace_info(info)
    ]
  end

  defp log_stacktrace(stacktrace) do
    stacktrace
    |> extract_rule_from_stacktrace()
    |> do_log_stacktrace()
  end

  defp log_stacktrace_info([file: file, line: line] ++ _) do
    [", at: ", file, ?:, to_string(line)]
  end

  defp log_stacktrace_info(_) do
    []
  end

  defp log_iodata(result, subject, user, action, stacktrace) do
    [
      "access ",
      log_result(result.status),
      " to ",
      inspect(subject),
      " by ",
      inspect(user),
      " for ",
      inspect(action),
      " by rule from ",
      result.file,
      " at line ",
      result.line |> to_string(),
      log_stacktrace(stacktrace),
    ]
  end

  @spec authorize!(subject :: subject, action :: action, user :: user) :: subject | no_return
  def authorize!(subject, action, user) do
    require Logger

    result = %Menshen{status: status} = Menshen.Can.can(user, action, subject)
    {:current_stacktrace, [_process_info_call | stacktrace]} = Process.info(self(), :current_stacktrace)
    Logger.log(
      :debug,
      fn -> log_iodata(result, subject, user, action, stacktrace) end,
      ansi_color: color_result(status)
    )
    if :granted === status do
      subject
    else
      raise Menshen.AccessDeniedError, result: result, user: user, action: action, subject: subject, stacktrace: stacktrace
    end
  end

  @spec can?(user :: user, action :: action, subject :: subject) :: boolean
  def can?(user, action, subject) do
    %Menshen{status: status} = Menshen.Can.can(user, action, subject)
    :granted == status
  end
end

defprotocol Menshen.Can do
  @fallback_to_any false

  @spec can(user :: Menshen.user, action :: Menshen.action, subject :: Menshen.subject) :: Menshen.subject
  def can(user, action, subject)
end
