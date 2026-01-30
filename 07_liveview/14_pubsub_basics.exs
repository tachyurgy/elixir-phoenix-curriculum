# ============================================================================
# Lesson 14: Phoenix.PubSub - Real-Time Communication
# ============================================================================
#
# Phoenix.PubSub provides a publish-subscribe mechanism for real-time
# communication between processes in Elixir applications. It's the foundation
# for building real-time features like live notifications, chat systems,
# collaborative editing, and live dashboards.
#
# In this lesson, you'll learn:
# - How PubSub works conceptually
# - Subscribing to topics
# - Broadcasting messages
# - Integrating PubSub with LiveView
# - Building real-time features
#
# ============================================================================

# ============================================================================
# Section 1: Understanding PubSub Concepts
# ============================================================================

# PubSub follows the publish-subscribe pattern:
# - Publishers send messages to a "topic" (a named channel)
# - Subscribers listen to topics and receive messages
# - The PubSub system routes messages from publishers to all subscribers
#
# Key concepts:
# - Topic: A string identifier for a channel (e.g., "chat:lobby", "user:123")
# - Subscriber: A process that listens to a topic
# - Publisher: Any process that sends messages to a topic
# - Message: The data being transmitted

# ============================================================================
# Section 2: Basic PubSub Setup
# ============================================================================

# Phoenix projects come with PubSub configured by default.
# Check your application's supervision tree in lib/my_app/application.ex:

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # PubSub is typically started with your app
      {Phoenix.PubSub, name: MyApp.PubSub},
      # ... other children
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# The PubSub system is now available as MyApp.PubSub

# ============================================================================
# Section 3: Subscribing to Topics
# ============================================================================

# Subscribing allows a process to receive messages from a topic

defmodule PubSubExamples do
  @moduledoc """
  Examples of subscribing to PubSub topics.
  """

  # Basic subscription
  def subscribe_to_topic do
    # Subscribe the current process to a topic
    Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications")

    # Now this process will receive messages broadcast to "notifications"
    # Messages arrive as regular Erlang messages: {:pubsub_message, payload}
  end

  # Dynamic topic subscription (common pattern)
  def subscribe_to_user(user_id) do
    # Create a user-specific topic
    topic = "user:#{user_id}"
    Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
  end

  # Subscribing to multiple topics
  def subscribe_to_multiple_topics(topics) when is_list(topics) do
    Enum.each(topics, fn topic ->
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
    end)
  end

  # Unsubscribing from a topic
  def unsubscribe_from_topic(topic) do
    Phoenix.PubSub.unsubscribe(MyApp.PubSub, topic)
  end
end

# ============================================================================
# Section 4: Broadcasting Messages
# ============================================================================

defmodule BroadcastExamples do
  @moduledoc """
  Examples of broadcasting messages to PubSub topics.
  """

  # Basic broadcast - sends to all subscribers
  def broadcast_notification(message) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "notifications", {:new_notification, message})
  end

  # Broadcast with structured data
  def broadcast_chat_message(room_id, user, content) do
    message = %{
      user: user,
      content: content,
      timestamp: DateTime.utc_now()
    }

    Phoenix.PubSub.broadcast(MyApp.PubSub, "chat:#{room_id}", {:new_message, message})
  end

  # Broadcast from the current process (excluding self)
  # Useful when you want to notify others but not yourself
  def broadcast_from_self(topic, message) do
    Phoenix.PubSub.broadcast_from(MyApp.PubSub, self(), topic, message)
  end

  # Local broadcast (only to subscribers on this node)
  # Useful in distributed systems when you only want local delivery
  def broadcast_local(topic, message) do
    Phoenix.PubSub.local_broadcast(MyApp.PubSub, topic, message)
  end

  # Direct send to a specific subscriber (not common, but possible)
  def direct_broadcast(topic, message) do
    Phoenix.PubSub.direct_broadcast(node(), MyApp.PubSub, topic, message)
  end
end

# ============================================================================
# Section 5: PubSub in LiveView
# ============================================================================

defmodule MyAppWeb.NotificationLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe when the LiveView mounts
    # Only subscribe if the socket is connected (not during initial static render)
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "notifications")
    end

    {:ok, assign(socket, notifications: [])}
  end

  # Handle incoming PubSub messages
  @impl true
  def handle_info({:new_notification, notification}, socket) do
    # Prepend the new notification to the list
    updated_notifications = [notification | socket.assigns.notifications]

    {:noreply, assign(socket, notifications: updated_notifications)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="notifications">
      <h2>Live Notifications</h2>

      <ul id="notification-list">
        <%= for notification <- @notifications do %>
          <li class="notification-item">
            <span class="message"><%= notification.message %></span>
            <span class="time"><%= notification.timestamp %></span>
          </li>
        <% end %>
      </ul>

      <%= if @notifications == [] do %>
        <p class="empty-state">No notifications yet</p>
      <% end %>
    </div>
    """
  end
end

# ============================================================================
# Section 6: Real-Time Chat Example
# ============================================================================

defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  alias MyApp.Chat

  @impl true
  def mount(%{"room_id" => room_id}, session, socket) do
    if connected?(socket) do
      # Subscribe to the chat room
      Phoenix.PubSub.subscribe(MyApp.PubSub, "chat:#{room_id}")
    end

    # Load existing messages
    messages = Chat.list_messages(room_id)

    socket =
      socket
      |> assign(:room_id, room_id)
      |> assign(:current_user, session["current_user"])
      |> assign(:messages, messages)
      |> assign(:message_form, to_form(%{"content" => ""}))

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    %{room_id: room_id, current_user: user} = socket.assigns

    # Create the message
    {:ok, message} = Chat.create_message(%{
      room_id: room_id,
      user_id: user.id,
      content: content
    })

    # Broadcast to all subscribers (including self)
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "chat:#{room_id}",
      {:new_message, message}
    )

    # Clear the form
    {:noreply, assign(socket, message_form: to_form(%{"content" => ""}))}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Append the new message
    updated_messages = socket.assigns.messages ++ [message]

    {:noreply, assign(socket, messages: updated_messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="chat-container">
      <h1>Chat Room: <%= @room_id %></h1>

      <div id="messages" class="messages-list" phx-update="append">
        <%= for message <- @messages do %>
          <div id={"message-#{message.id}"} class="message">
            <strong><%= message.user.name %>:</strong>
            <span><%= message.content %></span>
            <small><%= format_time(message.inserted_at) %></small>
          </div>
        <% end %>
      </div>

      <.form for={@message_form} phx-submit="send_message" class="message-form">
        <input
          type="text"
          name="content"
          value={@message_form[:content].value}
          placeholder="Type a message..."
          autocomplete="off"
        />
        <button type="submit">Send</button>
      </.form>
    </div>
    """
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M")
  end
end

# ============================================================================
# Section 7: Broadcast from Context Modules
# ============================================================================

# It's a good practice to broadcast from your context modules (business logic)
# rather than directly from LiveViews. This keeps your LiveViews focused on
# presentation.

defmodule MyApp.Chat do
  @moduledoc """
  The Chat context - handles chat-related business logic.
  """

  alias MyApp.Repo
  alias MyApp.Chat.Message

  # Broadcast function that can be called from anywhere
  def broadcast_message(room_id, message) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "chat:#{room_id}", {:new_message, message})
  end

  # Subscribe helper
  def subscribe_to_room(room_id) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "chat:#{room_id}")
  end

  # Create message and broadcast
  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} = result ->
        # Broadcast after successful creation
        broadcast_message(message.room_id, message)
        result

      error ->
        error
    end
  end

  def list_messages(room_id) do
    # Query messages for the room
    Repo.all(from m in Message, where: m.room_id == ^room_id, order_by: m.inserted_at)
  end
end

# ============================================================================
# Section 8: Topic Naming Conventions
# ============================================================================

# Good topic naming makes your PubSub system organized and maintainable

defmodule TopicNaming do
  @moduledoc """
  Examples of topic naming conventions.
  """

  # Resource-based topics
  def user_topic(user_id), do: "user:#{user_id}"
  def post_topic(post_id), do: "post:#{post_id}"
  def chat_room_topic(room_id), do: "chat:room:#{room_id}"

  # Action-based topics
  def notifications_topic, do: "notifications"
  def system_alerts_topic, do: "system:alerts"

  # Scoped topics (for multi-tenant apps)
  def tenant_topic(tenant_id, resource), do: "tenant:#{tenant_id}:#{resource}"

  # Wildcard-like patterns (manually implemented)
  def all_user_topics, do: "users:*"  # You'd need custom logic to fan out

  # Composite topics
  def user_notifications_topic(user_id), do: "user:#{user_id}:notifications"
  def user_messages_topic(user_id), do: "user:#{user_id}:messages"
end

# ============================================================================
# Section 9: Handling Multiple Event Types
# ============================================================================

defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to multiple topics
      Phoenix.PubSub.subscribe(MyApp.PubSub, "metrics")
      Phoenix.PubSub.subscribe(MyApp.PubSub, "alerts")
      Phoenix.PubSub.subscribe(MyApp.PubSub, "orders")
    end

    {:ok, assign(socket, metrics: %{}, alerts: [], recent_orders: [])}
  end

  # Handle different message types with pattern matching
  @impl true
  def handle_info({:metric_update, metric_name, value}, socket) do
    metrics = Map.put(socket.assigns.metrics, metric_name, value)
    {:noreply, assign(socket, metrics: metrics)}
  end

  def handle_info({:new_alert, alert}, socket) do
    alerts = [alert | socket.assigns.alerts] |> Enum.take(10)  # Keep last 10
    {:noreply, assign(socket, alerts: alerts)}
  end

  def handle_info({:new_order, order}, socket) do
    orders = [order | socket.assigns.recent_orders] |> Enum.take(5)
    {:noreply, assign(socket, recent_orders: orders)}
  end

  def handle_info({:order_updated, order}, socket) do
    orders = Enum.map(socket.assigns.recent_orders, fn o ->
      if o.id == order.id, do: order, else: o
    end)
    {:noreply, assign(socket, recent_orders: orders)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <section class="metrics">
        <h2>Live Metrics</h2>
        <%= for {name, value} <- @metrics do %>
          <div class="metric">
            <span class="name"><%= name %></span>
            <span class="value"><%= value %></span>
          </div>
        <% end %>
      </section>

      <section class="alerts">
        <h2>Recent Alerts</h2>
        <%= for alert <- @alerts do %>
          <div class={"alert alert-#{alert.severity}"}>
            <%= alert.message %>
          </div>
        <% end %>
      </section>

      <section class="orders">
        <h2>Recent Orders</h2>
        <%= for order <- @recent_orders do %>
          <div class="order">
            Order #<%= order.id %> - <%= order.status %>
          </div>
        <% end %>
      </section>
    </div>
    """
  end
end

# ============================================================================
# Section 10: PubSub with GenServer
# ============================================================================

# PubSub isn't just for LiveViews - it works with any Erlang process

defmodule MyApp.MetricsCollector do
  use GenServer

  @moduledoc """
  A GenServer that collects metrics and broadcasts them via PubSub.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Start collecting metrics periodically
    schedule_collection()

    {:ok, %{metrics: %{}}}
  end

  def handle_info(:collect_metrics, state) do
    metrics = collect_system_metrics()

    # Broadcast each metric
    Enum.each(metrics, fn {name, value} ->
      Phoenix.PubSub.broadcast(MyApp.PubSub, "metrics", {:metric_update, name, value})
    end)

    schedule_collection()
    {:noreply, %{state | metrics: metrics}}
  end

  defp schedule_collection do
    Process.send_after(self(), :collect_metrics, 5_000)  # Every 5 seconds
  end

  defp collect_system_metrics do
    %{
      memory_usage: :erlang.memory(:total),
      process_count: length(Process.list()),
      uptime: System.monotonic_time(:second)
    }
  end
end

# ============================================================================
# Section 11: Error Handling and Edge Cases
# ============================================================================

defmodule PubSubErrorHandling do
  @moduledoc """
  Best practices for error handling with PubSub.
  """

  # Always check if connected before subscribing in LiveView
  def safe_subscribe(socket, topic) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
    end
    socket
  end

  # Handle unknown messages gracefully
  def handle_info(unknown_message, socket) do
    # Log unexpected messages for debugging
    require Logger
    Logger.warning("Received unexpected message: #{inspect(unknown_message)}")

    {:noreply, socket}
  end

  # Cleanup on terminate (optional - PubSub handles this automatically)
  def terminate(_reason, socket) do
    # Subscriptions are automatically cleaned up when the process dies,
    # but you might want to do additional cleanup
    :ok
  end
end

# ============================================================================
# Section 12: Testing PubSub
# ============================================================================

defmodule MyApp.ChatTest do
  use MyApp.DataCase

  alias MyApp.Chat

  describe "broadcasting" do
    test "create_message/1 broadcasts to subscribers" do
      room_id = "test-room"

      # Subscribe to the topic
      Phoenix.PubSub.subscribe(MyApp.PubSub, "chat:#{room_id}")

      # Create a message
      {:ok, message} = Chat.create_message(%{
        room_id: room_id,
        user_id: 1,
        content: "Hello!"
      })

      # Assert we received the broadcast
      assert_receive {:new_message, ^message}
    end

    test "subscribers receive messages" do
      topic = "test:topic"
      Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

      # Broadcast a message
      Phoenix.PubSub.broadcast(MyApp.PubSub, topic, {:test, "data"})

      # Assert we received it
      assert_receive {:test, "data"}
    end
  end
end

# ============================================================================
# Section 13: Distributed PubSub
# ============================================================================

# Phoenix.PubSub works across nodes in a distributed Elixir cluster!

defmodule DistributedPubSub do
  @moduledoc """
  Notes on distributed PubSub.

  By default, Phoenix.PubSub uses the Phoenix.PubSub.PG2 adapter,
  which automatically distributes messages across all connected nodes.

  Configuration in config/config.exs:

      config :my_app, MyApp.PubSub,
        adapter: Phoenix.PubSub.PG2,
        pool_size: 1

  When nodes are connected (via Node.connect/1 or libcluster),
  PubSub messages are automatically propagated to all nodes.
  """

  # Broadcast to all nodes
  def broadcast_globally(topic, message) do
    # This automatically goes to all connected nodes
    Phoenix.PubSub.broadcast(MyApp.PubSub, topic, message)
  end

  # Broadcast only to local node
  def broadcast_locally(topic, message) do
    Phoenix.PubSub.local_broadcast(MyApp.PubSub, topic, message)
  end

  # Broadcast to a specific node
  def broadcast_to_node(node, topic, message) do
    Phoenix.PubSub.direct_broadcast(node, MyApp.PubSub, topic, message)
  end
end

# ============================================================================
# Practice Exercises
# ============================================================================

# Exercise 1: Live Counter
# Create a LiveView that displays a counter. When any user clicks "increment",
# all connected users should see the updated count via PubSub.
#
# Hints:
# - Create a "counter" topic
# - Subscribe in mount/3
# - Broadcast on increment
# - Handle the broadcast in handle_info/2

# Exercise 2: Typing Indicator
# Create a chat feature where users can see when others are typing.
# When a user starts typing, broadcast to the room.
# When they stop (or send), clear the indicator.
#
# Hints:
# - Use phx-keyup or phx-change to detect typing
# - Broadcast {:user_typing, user_id} and {:user_stopped_typing, user_id}
# - Track typing users in assigns

# Exercise 3: Live Notifications System
# Create a notification system where:
# - Admins can broadcast notifications to all users
# - Users can dismiss notifications
# - Notifications auto-expire after 30 seconds
#
# Hints:
# - Use Process.send_after/3 for auto-expiration
# - Track notification IDs for dismissal
# - Consider using a struct for notifications

# Exercise 4: Real-time Auction
# Build a simple auction feature where:
# - Multiple users can bid on an item
# - All users see the current highest bid in real-time
# - Bidding updates are broadcast instantly
#
# Hints:
# - Create an "auction:#{item_id}" topic
# - Validate bids are higher than current
# - Broadcast {:new_bid, %{amount: ..., user: ...}}

# Exercise 5: Collaborative List
# Create a shared todo list where:
# - Multiple users can add items
# - Users can mark items complete
# - All changes sync in real-time
#
# Hints:
# - Subscribe to "list:#{list_id}"
# - Broadcast on create, update, delete
# - Handle all three event types in handle_info

# ============================================================================
# Key Takeaways
# ============================================================================

# 1. Phoenix.PubSub enables real-time, process-to-process communication
# 2. Topics are strings that identify message channels
# 3. Always check connected?(socket) before subscribing in LiveView
# 4. Broadcast from context modules, not LiveViews, for cleaner architecture
# 5. Use meaningful topic naming conventions
# 6. Pattern match on different message types in handle_info/2
# 7. PubSub works automatically across distributed Elixir nodes
# 8. Subscriptions are cleaned up automatically when processes die
# 9. Use broadcast_from/4 to exclude the sender from receiving the message
# 10. Testing PubSub is straightforward with assert_receive

# ============================================================================
# Next Steps
# ============================================================================

# In the next lesson (15_presence.exs), we'll learn about Phoenix.Presence,
# which builds on PubSub to track which users are online and what they're doing.
