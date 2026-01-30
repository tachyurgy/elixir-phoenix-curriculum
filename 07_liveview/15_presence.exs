# ============================================================================
# Lesson 15: Phoenix.Presence - User Tracking and Online Status
# ============================================================================
#
# Phoenix.Presence is a powerful module for tracking ephemeral process state
# across a distributed cluster. It's built on top of PubSub and CRDTs
# (Conflict-free Replicated Data Types) to provide eventually consistent
# presence tracking.
#
# In this lesson, you'll learn:
# - Setting up Phoenix.Presence
# - Tracking users in channels and LiveViews
# - Handling presence_diff events
# - Building "who's online" features
# - Advanced presence patterns
#
# ============================================================================

# ============================================================================
# Section 1: Understanding Presence
# ============================================================================

# Presence solves the problem of tracking ephemeral state like:
# - Who's online in a chat room
# - Who's viewing a document
# - What users are doing (typing, idle, etc.)
#
# Key features:
# - Automatic cleanup when processes die
# - Works across distributed nodes
# - Conflict-free synchronization (CRDTs)
# - Efficient delta updates (presence_diff)

# ============================================================================
# Section 2: Setting Up Presence
# ============================================================================

# Step 1: Create a Presence module for your app

defmodule MyAppWeb.Presence do
  @moduledoc """
  The Presence module for tracking users across the application.
  """

  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  # Optional: Override fetch/2 to add user data to presence info
  # This is called when presence data is requested
  def fetch(_topic, presences) do
    # You can enrich presence data here
    # For example, fetch user details from the database

    users = presences
    |> Map.keys()
    |> MyApp.Accounts.get_users_by_ids()
    |> Map.new(fn user -> {to_string(user.id), user} end)

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[key]}}
    end
  end
end

# Step 2: Add Presence to your supervision tree (application.ex)

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Presence,  # Add this line
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# ============================================================================
# Section 3: Basic Presence Tracking
# ============================================================================

defmodule PresenceBasics do
  @moduledoc """
  Basic presence tracking operations.
  """

  alias MyAppWeb.Presence

  # Track a user's presence
  def track_user(topic, user_id, meta \\ %{}) do
    # track(pid, topic, key, meta)
    # - pid: The process to track (usually self())
    # - topic: The PubSub topic
    # - key: Unique identifier (usually user_id)
    # - meta: Additional metadata

    Presence.track(self(), topic, user_id, %{
      online_at: System.system_time(:second),
      status: "online"
    } |> Map.merge(meta))
  end

  # Update a user's presence metadata
  def update_presence(topic, user_id, new_meta) do
    Presence.update(self(), topic, user_id, fn existing_meta ->
      Map.merge(existing_meta, new_meta)
    end)
  end

  # List all presences for a topic
  def list_presences(topic) do
    Presence.list(topic)
  end

  # Get a specific user's presence
  def get_user_presence(topic, user_id) do
    topic
    |> Presence.list()
    |> Map.get(to_string(user_id))
  end
end

# ============================================================================
# Section 4: Presence in LiveView
# ============================================================================

defmodule MyAppWeb.ChatRoomLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.Presence

  @impl true
  def mount(%{"room_id" => room_id}, session, socket) do
    topic = "room:#{room_id}"

    if connected?(socket) do
      # Subscribe to presence changes
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # Track this user's presence
      {:ok, _} = Presence.track(self(), topic, session["user_id"], %{
        name: session["user_name"],
        joined_at: DateTime.utc_now(),
        status: "online"
      })
    end

    # Get initial presence list
    presences = Presence.list(topic)

    socket =
      socket
      |> assign(:room_id, room_id)
      |> assign(:topic, topic)
      |> assign(:current_user_id, session["user_id"])
      |> assign(:presences, presences)
      |> assign(:user_count, map_size(presences))

    {:ok, socket}
  end

  # Handle presence_diff events
  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    # diff contains %{joins: ..., leaves: ...}
    presences =
      socket.assigns.presences
      |> handle_joins(diff.joins)
      |> handle_leaves(diff.leaves)

    socket =
      socket
      |> assign(:presences, presences)
      |> assign(:user_count, map_size(presences))

    {:noreply, socket}
  end

  # Handle joins - add new presences
  defp handle_joins(presences, joins) do
    Enum.reduce(joins, presences, fn {user_id, %{metas: metas}}, acc ->
      Map.put(acc, user_id, %{metas: metas})
    end)
  end

  # Handle leaves - remove or update presences
  defp handle_leaves(presences, leaves) do
    Enum.reduce(leaves, presences, fn {user_id, %{metas: metas}}, acc ->
      case acc[user_id] do
        # User still has other sessions
        %{metas: remaining} when length(remaining) > length(metas) ->
          Map.put(acc, user_id, %{metas: remaining -- metas})
        # User completely left
        _ ->
          Map.delete(acc, user_id)
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="chat-room">
      <aside class="sidebar">
        <h3>Online (<%= @user_count %>)</h3>
        <ul class="user-list">
          <%= for {user_id, %{metas: [meta | _]}} <- @presences do %>
            <li class={"user-item #{meta.status}"}>
              <span class="status-indicator"></span>
              <span class="user-name"><%= meta.name %></span>
              <%= if user_id == to_string(@current_user_id) do %>
                <span class="you-badge">(you)</span>
              <% end %>
            </li>
          <% end %>
        </ul>
      </aside>

      <main class="chat-area">
        <!-- Chat content here -->
      </main>
    </div>
    """
  end
end

# ============================================================================
# Section 5: Handling Multiple Connections Per User
# ============================================================================

# A single user might have multiple browser tabs or devices connected.
# Presence tracks each connection separately via "metas".

defmodule MultiConnectionExample do
  @moduledoc """
  Examples of handling users with multiple connections.
  """

  alias MyAppWeb.Presence

  # Track with device info
  def track_with_device(topic, user_id, device_type) do
    Presence.track(self(), topic, user_id, %{
      device: device_type,
      connected_at: DateTime.utc_now()
    })
  end

  # Get all connections for a user
  def get_user_connections(topic, user_id) do
    case Presence.list(topic)[to_string(user_id)] do
      %{metas: metas} -> metas
      nil -> []
    end
  end

  # Check if user is online (has at least one connection)
  def user_online?(topic, user_id) do
    Map.has_key?(Presence.list(topic), to_string(user_id))
  end

  # Count total connections for a user
  def connection_count(topic, user_id) do
    topic
    |> get_user_connections(user_id)
    |> length()
  end

  # Process presence data for display
  def format_presences_for_display(presences) do
    Enum.map(presences, fn {user_id, %{metas: metas}} ->
      %{
        user_id: user_id,
        # Take the most recent connection's data
        current_status: List.first(metas).status,
        # Show all devices
        devices: Enum.map(metas, & &1.device),
        connection_count: length(metas)
      }
    end)
  end
end

# ============================================================================
# Section 6: Presence Status Updates
# ============================================================================

defmodule MyAppWeb.PresenceStatusLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.Presence

  @impl true
  def mount(_params, session, socket) do
    topic = "app:presence"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      Presence.track(self(), topic, session["user_id"], %{
        name: session["user_name"],
        status: "online",
        last_activity: DateTime.utc_now()
      })
    end

    {:ok, assign(socket,
      topic: topic,
      user_id: session["user_id"],
      current_status: "online",
      presences: Presence.list(topic)
    )}
  end

  # User changes their status
  @impl true
  def handle_event("change_status", %{"status" => new_status}, socket) do
    %{topic: topic, user_id: user_id} = socket.assigns

    # Update presence with new status
    Presence.update(self(), topic, user_id, fn meta ->
      %{meta | status: new_status, last_activity: DateTime.utc_now()}
    end)

    {:noreply, assign(socket, current_status: new_status)}
  end

  # Track activity for "away" detection
  def handle_event("user_activity", _params, socket) do
    %{topic: topic, user_id: user_id, current_status: status} = socket.assigns

    # Only update if not already "online"
    if status != "online" do
      Presence.update(self(), topic, user_id, fn meta ->
        %{meta | status: "online", last_activity: DateTime.utc_now()}
      end)
    end

    {:noreply, assign(socket, current_status: "online")}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    presences = sync_presences(socket.assigns.presences, diff)
    {:noreply, assign(socket, presences: presences)}
  end

  defp sync_presences(presences, %{joins: joins, leaves: leaves}) do
    presences
    |> Map.merge(joins)
    |> Map.drop(Map.keys(leaves))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="presence-demo" phx-keydown="user_activity" phx-window-focus="user_activity">
      <h2>Your Status</h2>
      <div class="status-selector">
        <button
          phx-click="change_status"
          phx-value-status="online"
          class={"status-btn #{if @current_status == "online", do: "active"}"}
        >
          Online
        </button>
        <button
          phx-click="change_status"
          phx-value-status="away"
          class={"status-btn #{if @current_status == "away", do: "active"}"}
        >
          Away
        </button>
        <button
          phx-click="change_status"
          phx-value-status="busy"
          class={"status-btn #{if @current_status == "busy", do: "active"}"}
        >
          Busy
        </button>
      </div>

      <h2>Users Online</h2>
      <ul class="presence-list">
        <%= for {user_id, %{metas: [meta | _]}} <- @presences do %>
          <li class={"presence-item status-#{meta.status}"}>
            <span class="status-dot"></span>
            <span class="name"><%= meta.name %></span>
            <span class="status-text">(<%= meta.status %>)</span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end

# ============================================================================
# Section 7: Typing Indicators with Presence
# ============================================================================

defmodule MyAppWeb.ChatWithTypingLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.Presence

  @impl true
  def mount(%{"room_id" => room_id}, session, socket) do
    topic = "chat:#{room_id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      Presence.track(self(), topic, session["user_id"], %{
        name: session["user_name"],
        typing: false
      })
    end

    {:ok, assign(socket,
      topic: topic,
      room_id: room_id,
      user_id: session["user_id"],
      user_name: session["user_name"],
      presences: Presence.list(topic),
      message: ""
    )}
  end

  # User starts typing
  @impl true
  def handle_event("typing", %{"value" => value}, socket) do
    %{topic: topic, user_id: user_id} = socket.assigns
    is_typing = String.length(value) > 0

    Presence.update(self(), topic, user_id, fn meta ->
      %{meta | typing: is_typing}
    end)

    {:noreply, assign(socket, message: value)}
  end

  # User sends message (stops typing)
  def handle_event("send_message", %{"message" => message}, socket) do
    %{topic: topic, user_id: user_id} = socket.assigns

    # Reset typing status
    Presence.update(self(), topic, user_id, fn meta ->
      %{meta | typing: false}
    end)

    # Broadcast the message (separate from presence)
    Phoenix.PubSub.broadcast(MyApp.PubSub, topic, {:new_message, %{
      user_id: user_id,
      user_name: socket.assigns.user_name,
      content: message
    }})

    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    presences = sync_presences(socket.assigns.presences, diff)
    {:noreply, assign(socket, presences: presences)}
  end

  def handle_info({:new_message, message}, socket) do
    # Handle incoming messages
    {:noreply, socket}
  end

  defp sync_presences(presences, %{joins: joins, leaves: leaves}) do
    presences
    |> Map.merge(joins)
    |> Map.drop(Map.keys(leaves))
  end

  # Get users who are currently typing (excluding self)
  defp typing_users(presences, current_user_id) do
    presences
    |> Enum.filter(fn {user_id, %{metas: [meta | _]}} ->
      user_id != to_string(current_user_id) && meta.typing
    end)
    |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta.name end)
  end

  @impl true
  def render(assigns) do
    typing = typing_users(assigns.presences, assigns.user_id)

    assigns = assign(assigns, :typing_users, typing)

    ~H"""
    <div class="chat-with-typing">
      <div class="typing-indicator">
        <%= case @typing_users do %>
          <% [] -> %>
            <!-- No one typing -->
          <% [name] -> %>
            <span><%= name %> is typing...</span>
          <% [name1, name2] -> %>
            <span><%= name1 %> and <%= name2 %> are typing...</span>
          <% names -> %>
            <span><%= length(names) %> people are typing...</span>
        <% end %>
      </div>

      <form phx-submit="send_message">
        <input
          type="text"
          name="message"
          value={@message}
          phx-keyup="typing"
          placeholder="Type a message..."
          autocomplete="off"
        />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end
end

# ============================================================================
# Section 8: Document Collaboration (Who's Viewing)
# ============================================================================

defmodule MyAppWeb.DocumentLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.Presence

  @colors ~w(red blue green purple orange pink teal)

  @impl true
  def mount(%{"doc_id" => doc_id}, session, socket) do
    topic = "document:#{doc_id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # Assign a random color for cursor display
      color = Enum.random(@colors)

      Presence.track(self(), topic, session["user_id"], %{
        name: session["user_name"],
        color: color,
        cursor_position: nil,
        selection: nil
      })
    end

    {:ok, assign(socket,
      topic: topic,
      doc_id: doc_id,
      user_id: session["user_id"],
      presences: Presence.list(topic)
    )}
  end

  # Track cursor movement
  @impl true
  def handle_event("cursor_move", %{"x" => x, "y" => y}, socket) do
    update_presence(socket, %{cursor_position: %{x: x, y: y}})
    {:noreply, socket}
  end

  # Track text selection
  def handle_event("selection_change", %{"start" => start_pos, "end" => end_pos}, socket) do
    update_presence(socket, %{selection: %{start: start_pos, end: end_pos}})
    {:noreply, socket}
  end

  defp update_presence(socket, updates) do
    %{topic: topic, user_id: user_id} = socket.assigns

    Presence.update(self(), topic, user_id, fn meta ->
      Map.merge(meta, updates)
    end)
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    presences = sync_presences(socket.assigns.presences, diff)
    {:noreply, assign(socket, presences: presences)}
  end

  defp sync_presences(presences, %{joins: joins, leaves: leaves}) do
    presences
    |> Map.merge(joins)
    |> Map.drop(Map.keys(leaves))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="document-editor">
      <div class="collaborators">
        <h4>Viewing now:</h4>
        <%= for {user_id, %{metas: [meta | _]}} <- @presences do %>
          <span
            class="collaborator-badge"
            style={"background-color: #{meta.color}"}
            title={meta.name}
          >
            <%= String.first(meta.name) %>
          </span>
        <% end %>
      </div>

      <div
        class="editor-area"
        phx-hook="CursorTracker"
        id="document-editor"
      >
        <!-- Document content -->
        <!-- Remote cursors would be rendered here -->
        <%= for {user_id, %{metas: [meta | _]}} <- @presences do %>
          <%= if user_id != to_string(@user_id) && meta.cursor_position do %>
            <div
              class="remote-cursor"
              style={"left: #{meta.cursor_position.x}px; top: #{meta.cursor_position.y}px; border-color: #{meta.color}"}
            >
              <span class="cursor-label" style={"background-color: #{meta.color}"}>
                <%= meta.name %>
              </span>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end

# ============================================================================
# Section 9: Presence with Custom Data Fetching
# ============================================================================

defmodule MyAppWeb.EnrichedPresence do
  @moduledoc """
  Presence module that fetches additional user data.
  """

  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  alias MyApp.Accounts

  @doc """
  Fetch callback enriches presence data with user information.
  This is called when Presence.list/1 is invoked.
  """
  def fetch(_topic, presences) do
    # Get all user IDs from presences
    user_ids =
      presences
      |> Map.keys()
      |> Enum.map(&String.to_integer/1)

    # Batch fetch users from database
    users =
      user_ids
      |> Accounts.get_users_map()  # Returns %{user_id => user}

    # Enrich each presence with user data
    for {key, %{metas: metas}} <- presences, into: %{} do
      user_id = String.to_integer(key)
      user = Map.get(users, user_id)

      enriched_metas = Enum.map(metas, fn meta ->
        Map.merge(meta, %{
          avatar_url: user && user.avatar_url,
          display_name: user && user.display_name,
          role: user && user.role
        })
      end)

      {key, %{metas: enriched_metas, user: user}}
    end
  end
end

# ============================================================================
# Section 10: Presence Synchronization Helpers
# ============================================================================

defmodule PresenceSync do
  @moduledoc """
  Helper module for synchronizing presence state.
  """

  @doc """
  Synchronize presence list with a diff.
  Use this in handle_info when receiving presence_diff.
  """
  def sync_state(current_presences, %{joins: joins, leaves: leaves}) do
    current_presences
    |> sync_joins(joins)
    |> sync_leaves(leaves)
  end

  defp sync_joins(presences, joins) when joins == %{}, do: presences
  defp sync_joins(presences, joins) do
    Enum.reduce(joins, presences, fn {user_id, %{metas: new_metas}}, acc ->
      case Map.get(acc, user_id) do
        nil ->
          Map.put(acc, user_id, %{metas: new_metas})

        %{metas: existing_metas} ->
          Map.put(acc, user_id, %{metas: existing_metas ++ new_metas})
      end
    end)
  end

  defp sync_leaves(presences, leaves) when leaves == %{}, do: presences
  defp sync_leaves(presences, leaves) do
    Enum.reduce(leaves, presences, fn {user_id, %{metas: left_metas}}, acc ->
      case Map.get(acc, user_id) do
        nil ->
          acc

        %{metas: existing_metas} ->
          remaining = existing_metas -- left_metas
          if remaining == [] do
            Map.delete(acc, user_id)
          else
            Map.put(acc, user_id, %{metas: remaining})
          end
      end
    end)
  end

  @doc """
  Count unique users from presences.
  """
  def count_users(presences) do
    map_size(presences)
  end

  @doc """
  Count total connections (a user might have multiple tabs).
  """
  def count_connections(presences) do
    Enum.reduce(presences, 0, fn {_user_id, %{metas: metas}}, acc ->
      acc + length(metas)
    end)
  end

  @doc """
  Get a simple list of online user IDs.
  """
  def online_user_ids(presences) do
    Map.keys(presences)
  end
end

# ============================================================================
# Section 11: Testing Presence
# ============================================================================

defmodule MyAppWeb.PresenceTest do
  use MyAppWeb.ConnCase

  alias MyAppWeb.Presence

  setup do
    topic = "test:presence:#{System.unique_integer()}"
    {:ok, topic: topic}
  end

  describe "tracking presence" do
    test "tracks a user", %{topic: topic} do
      # Track a user
      {:ok, _ref} = Presence.track(self(), topic, "user:1", %{name: "Alice"})

      # Verify they appear in the list
      presences = Presence.list(topic)
      assert Map.has_key?(presences, "user:1")
      assert hd(presences["user:1"].metas).name == "Alice"
    end

    test "updates presence metadata", %{topic: topic} do
      {:ok, _ref} = Presence.track(self(), topic, "user:1", %{status: "online"})

      # Update the status
      {:ok, _ref} = Presence.update(self(), topic, "user:1", fn meta ->
        %{meta | status: "away"}
      end)

      presences = Presence.list(topic)
      assert hd(presences["user:1"].metas).status == "away"
    end

    test "removes presence when process dies", %{topic: topic} do
      # Spawn a process that tracks presence
      pid = spawn(fn ->
        {:ok, _ref} = Presence.track(self(), topic, "user:temp", %{})
        receive do
          :stop -> :ok
        end
      end)

      # Give it time to track
      Process.sleep(50)
      assert Map.has_key?(Presence.list(topic), "user:temp")

      # Kill the process
      send(pid, :stop)
      Process.sleep(50)

      # Presence should be removed
      refute Map.has_key?(Presence.list(topic), "user:temp")
    end
  end

  describe "presence_diff" do
    test "broadcasts joins and leaves", %{topic: topic} do
      # Subscribe to presence updates
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # Track a user
      {:ok, _ref} = Presence.track(self(), topic, "user:1", %{name: "Alice"})

      # Should receive a presence_diff with the join
      assert_receive %Phoenix.Socket.Broadcast{
        event: "presence_diff",
        payload: %{joins: joins, leaves: leaves}
      }

      assert Map.has_key?(joins, "user:1")
      assert leaves == %{}
    end
  end
end

# ============================================================================
# Practice Exercises
# ============================================================================

# Exercise 1: Online Users Counter
# Create a component that shows "X users online" and updates in real-time.
# The count should increase when users join and decrease when they leave.
#
# Hints:
# - Track users in mount/3
# - Update count in presence_diff handler
# - Display count in the template

# Exercise 2: User Activity Status
# Implement an automatic "away" status:
# - User starts as "online"
# - After 5 minutes of inactivity, status changes to "away"
# - Any user activity returns them to "online"
#
# Hints:
# - Use Process.send_after/3 for the timeout
# - Track mouse/keyboard events
# - Update presence on activity

# Exercise 3: Chat Room Roster
# Build a chat room roster that shows:
# - Online users with green indicator
# - Away users with yellow indicator
# - Typing users with animated indicator
#
# Hints:
# - Combine status and typing in presence meta
# - Style based on status
# - Filter typing users for indicator

# Exercise 4: Live Viewers Count
# Create a "X people viewing this page" feature for a blog post.
# Show anonymous viewers as "X guests" and logged-in users by name.
#
# Hints:
# - Track with user_id or "guest:random_id"
# - Differentiate in meta: %{type: :guest} vs %{type: :user, name: "..."}
# - Count and display separately

# Exercise 5: Collaborative Editing Awareness
# Build a "who's editing where" feature:
# - Track which section each user is editing
# - Show colored highlights for each user's section
# - Update in real-time as users move between sections
#
# Hints:
# - Track current_section in presence meta
# - Assign unique colors to users
# - Render highlights based on presence data

# ============================================================================
# Key Takeaways
# ============================================================================

# 1. Phoenix.Presence tracks ephemeral state across distributed systems
# 2. Presence automatically cleans up when processes terminate
# 3. Users can have multiple connections (metas) - one per tab/device
# 4. Use presence_diff events for efficient updates (not full list refreshes)
# 5. Override fetch/2 to enrich presence data from the database
# 6. Presence uses CRDTs for conflict-free distributed synchronization
# 7. Always check connected?(socket) before tracking in LiveView
# 8. Combine Presence with PubSub for complete real-time features
# 9. Use meaningful metadata: status, typing, cursor position, etc.
# 10. Test presence by spawning processes and verifying join/leave behavior

# ============================================================================
# Next Steps
# ============================================================================

# In the next lesson (16_live_uploads.exs), we'll learn about handling
# file uploads in LiveView with progress tracking and validation.
