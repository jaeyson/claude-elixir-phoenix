# LiveView Template

Convention-aware LiveView scaffold. Customize app name, module prefix, and patterns from project scan.

## Template

```elixir
defmodule {AppWeb}.{Name} do
  use {AppWeb}, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Iron Law #1: No DB queries in disconnected mount
    socket =
      socket
      |> assign(:page_title, "{Title}")
      |> assign_async(:data, fn -> load_data() end)

    # Iron Law #3: Check connected? before PubSub
    if connected?(socket) do
      Phoenix.PubSub.subscribe({App}.PubSub, "{topic}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("action", params, socket) do
    # Iron Law #11: Authorize in EVERY handle_event
    # TODO: Add authorization check
    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated, _payload}, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "{Title}")
  end

  defp load_data do
    # Replace with actual data loading
    {:ok, %{data: []}}
  end
end
```

## Test Template

```elixir
defmodule {AppWeb}.{Name}Test do
  use {AppWeb}.ConnCase

  import Phoenix.LiveViewTest

  describe "{name}" do
    test "renders page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/{path}")
      assert html =~ "{Title}"
    end
  end
end
```

## Customization Points

| Placeholder | Source |
|-------------|--------|
| `{AppWeb}` | `mix.exs` `:app` + "Web" |
| `{App}` | `mix.exs` `:app` |
| `{Name}` | User argument |
| `{Title}` | Derived from name |
| `{topic}` | Derived from resource |
| `{path}` | Derived from router conventions |
