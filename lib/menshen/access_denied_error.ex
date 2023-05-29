defmodule Menshen.AccessDeniedError do
  defexception ~W[message result user action subject]a

  def exception(options) do
    result = Keyword.fetch!(options, :result)
    user  = Keyword.fetch!(options, :user)
    action = Keyword.fetch!(options, :action)
    subject = Keyword.fetch!(options, :subject)
    message = with(
      stacktrace <- Keyword.fetch!(options, :stacktrace),
      {module, function, arity, [file: file, line: line]} <- Menshen.extract_rule_from_stacktrace(stacktrace)
    ) do
      """
      access #{result.status} to #{inspect(subject)} by #{inspect(user)} for #{inspect(action)} by #{result.file} at line #{result.line}

      Rule: #{Exception.format_mfa(module, function, arity)} from #{file} at line #{line}
      """
    else
      _ ->
        """
        access #{result.status} to #{inspect(subject)} by #{inspect(user)} for #{inspect(action)} by #{result.file} at line #{result.line}
        """
    end

    %__MODULE__{
      message: message,
      user: user,
      result: result,
      action: action,
      subject: subject,
    }
  end

  defimpl Plug.Exception do
    def status(_), do: 403
    def actions(_), do: []
  end
end
