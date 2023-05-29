# Menshen

## Credits

* [Plug.Debugger](https://hex.pm/packages/plug)
* [Canada](https://hex.pm/packages/canada)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `menshen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:menshen, "~> 0.0.1"},
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at <https://hexdocs.pm/menshen>.

## Usage

```elixir
# lib/your_app_web/router.ex

if Mix.env() == :dev do
  use Menshen.PlugDebugger
end
```

## Example

```elixir
# lib/your_app/ability.ex

import Menshen
alias YourApp.User

defimpl Menshen.Can, for: User do
  # an administrator can do anything
  def can(%User{admin: true}, _action, _subject), do: grant()

  # users can read posts
  def can(_user, :read, %YourApp.Blog.Post{}), do: grant()

  # users can create comments
  def can(_user, :create, YourApp.Blog.Comment), do: grant()

  # users can edit their own posts (via pattern matching on id)
  def can(%User{id: id}, :update, %YourApp.Blog.Comment{user_id: id}), do: grant()

  # users can delete their own comments but not after 5 days
  def can(%User{id: id}, :delete, post = %YourApp.Blog.Comment{user_id: id}) do
    if Timex.Comparable.diff(Timex.today, post.created_at, :days) >= 5 do
      deny("user cannot delete their comment after 5 days")
    else
      grant()
    end
  end

  # default/everything else is denied
  def can(_user, _action, _subject), do: deny("default")
end

# rules for visitors
# reminder: visitors will be known as nil which is an atom (like true and false btw)
defimpl Menshen.Can, for: Atom do
  # anonymous users can read blog posts
  def can(_nil, :read, %YourApp.Blog.Post{}), do: grant()

  # default/everything else is denied
  def can(_nil, _action, _subject), do: deny("default")
end
```

```diff
# lib/your_app_web.ex

  def controller do
    quote do
      # ...

+     use Menshen, :controller
+
+     def action(conn, _) do
+       apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns[:current_user]])
+     end
    end
  end

  # ...

  defp view_helpers do
    quote do
      # ...

+     use Menshen, :view
    end
  end
```

```elixir
# lib/your_app_web/controllers/blog/comment_controller.ex

defmodule ... do
  # ... use YourAppWeb, :controller

  def index(conn, _params, current_user) do
    authorize!(YourApp.Blog.Comment, :read, current_user)

    conn
    |> ...
    |> render(:index)
  end

  def show(conn, %{"id" => id}, current_user) do
    comment =
      id
      |> get_comment!()
      |> authorize!(:read, current_user)

    conn
    |> ...
    |> render(:show)
  end

  def new(conn, _params, current_user) do
    authorize!(YourApp.Blog.Comment, :create, current_user)

    conn
    |> ...
    |> render(:new)
  end

  def create(conn, %{"comment" => comment_params}, current_user) do
    authorize!(YourApp.Blog.Comment, :create, current_user)

    comment_params
    |> create_comment(current_user)
    |> case do
      {:ok, comment} ->
        conn
        |> put_flash(:info, "comment successfuly created")
        |> redirect(to: ...)
        |> halt()
      {:error, changeset} ->
        conn
        |> ...
        |> render(:new)
    end
  end

  def edit(conn, %{"id" => id}, current_user) do
    comment =
      id
      |> get_comment!()
      |> authorize!(:update, current_user)

    conn
    |> ...
    |> render(:edit)
  end

  def update(conn, %{"id" => id, "comment" => comment_params}, current_user) do
    comment =
      id
      |> get_comment!()
      |> authorize!(:update, current_user)

    comment_params
    |> update_comment(comment)
    |> case do
      {:ok, comment} ->
        conn
        |> put_flash(:info, "comment successfuly updated")
        |> redirect(to: ...)
        |> halt()
      {:error, changeset} ->
        conn
        |> ...
        |> render(:edit)
    end
  end

  def delete(conn, %{"id" => id}, current_user) do
    id
    |> get_comment!()
    |> authorize!(:delete, current_user)
    |> delete_comment!()

    conn
    |> put_flash(:info, "comment successfuly deleted")
    |> redirect(to: ...)
    |> halt()
  end
end
```
