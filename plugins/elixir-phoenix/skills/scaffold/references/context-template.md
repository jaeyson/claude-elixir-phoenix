# Context Template

Convention-aware Phoenix context scaffold with Iron Law compliance.

## Template

```elixir
defmodule {App}.{Context} do
  @moduledoc """
  The {Context} context.
  """

  import Ecto.Query, warn: false
  alias {App}.Repo
  alias {App}.{Context}.{Schema}

  @doc """
  Returns the list of {resources}.
  """
  def list_{resources} do
    Repo.all({Schema})
  end

  @doc """
  Gets a single {resource}.

  Raises `Ecto.NoResultsError` if not found.
  """
  def get_{resource}!(id), do: Repo.get!({Schema}, id)

  @doc """
  Creates a {resource}.
  """
  def create_{resource}(attrs \\ %{}) do
    %{Schema}{}
    |> {Schema}.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a {resource}.
  """
  def update_{resource}(%{Schema}{} = {resource}, attrs) do
    {resource}
    |> {Schema}.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a {resource}.
  """
  def delete_{resource}(%{Schema}{} = {resource}) do
    Repo.delete({resource})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking {resource} changes.
  """
  def change_{resource}(%{Schema}{} = {resource}, attrs \\ %{}) do
    {Schema}.changeset({resource}, attrs)
  end
end
```

## Query Patterns (Iron Law Compliant)

```elixir
# Iron Law #5: ALWAYS pin values
def get_by_email(email) do
  Repo.get_by({Schema}, email: email)
end

# Iron Law #6: Separate queries for has_many
def list_with_posts(user_id) do
  user = Repo.get!({Schema}, user_id)
  posts = Repo.all(from p in Post, where: p.user_id == ^user_id)
  %{user | posts: posts}
end

# Iron Law #15: No implicit cross joins
def list_with_role(role_name) do
  from(u in {Schema},
    join: r in assoc(u, :role),
    where: r.name == ^role_name,
    preload: [role: r]
  )
  |> Repo.all()
end
```

## Test Template

```elixir
defmodule {App}.{Context}Test do
  use {App}.DataCase

  alias {App}.{Context}

  describe "{resources}" do
    # TODO: Add factory or fixture setup

    test "list_{resources}/0 returns all {resources}" do
      # {resource} = insert(:{resource})
      # assert {Context}.list_{resources}() == [{resource}]
    end

    test "create_{resource}/1 with valid data" do
      valid_attrs = %{}  # TODO: Add valid attributes
      assert {:ok, %{Schema}{}} = {Context}.create_{resource}(valid_attrs)
    end

    test "create_{resource}/1 with invalid data" do
      assert {:error, %Ecto.Changeset{}} = {Context}.create_{resource}(%{})
    end
  end
end
```
