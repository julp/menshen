defmodule Menshen.Test do
  require ExUnit.Assertions

  if true do
    def assert_granted(user, action, subject) do
      ^subject = Menshen.authorize!(subject, action, user)
    end

    def assert_denied(user, action, subject) do
      ExUnit.Assertions.assert_raise Menshen.AccessDeniedError, fn ->
        Menshen.authorize!(subject, action, user)
      end
    end

    if {:module, _module} = Code.ensure_compiled(Phoenix.ConnTest) do
      @content_type_header "content-type"

      defp check_content_type_header(falsy, _) when falsy in [false, nil], do: true
      defp check_content_type_header(:json, {@content_type_header, "application/json; charset=utf-8"}), do: true
      defp check_content_type_header(:html, {@content_type_header, "text/html; charset=utf-8"}), do: true
      defp check_content_type_header(_, _), do: false

      @spec assert_http_forbidden(expected_body_or_pattern :: String.t | Regex.t | nil, operator :: (String.t, String.t | Regex.t -> boolean), content_type :: atom, fun :: (-> Plug.Conn.t)) :: true | no_return
      def assert_http_forbidden(expected_body_or_pattern \\ "Accès refusé", operator \\ &Kernel.=~/2, content_type \\ :html, fun)
        when is_function(fun, 0)
      do
        response = Phoenix.ConnTest.assert_error_sent 403, fun
        {403, headers, body} = response
        if expected_body_or_pattern do
          ExUnit.Assertions.assert operator.(body, expected_body_or_pattern)
        end
        ExUnit.Assertions.assert check_content_type_header(content_type, :lists.keyfind(@content_type_header, 1, headers))
      end
    end
  else
    defmacro assert_granted(user, action, subject) do
      quote do
        ^unquote(subject) = Menshen.authorize!(unquote(subject), unquote(action), unquote(user))
      end
    end

    defmacro assert_denied(user, action, subject) do
      quote do
        assert_raise Menshen.AccessDeniedError, fn ->
          Menshen.authorize!(unquote(subject), unquote(action), unquote(user))
        end
      end
    end
  end
end
