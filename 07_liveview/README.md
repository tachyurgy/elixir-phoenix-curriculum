# Section 7: Phoenix LiveView

Build rich, real-time user interfaces without writing JavaScript. LiveView brings the power of server-rendered HTML with real-time updates.

## What You'll Learn

- LiveView lifecycle and state management
- Handling events and user interaction
- Building reusable components
- Real-time features with PubSub
- File uploads in LiveView
- Testing LiveView applications

## Prerequisites

- Section 5 and 6 completed
- Phoenix fundamentals understood
- Basic JavaScript knowledge helpful

## Lessons

### LiveView Basics
1. **[01_liveview_intro.exs](01_liveview_intro.exs)** - Your first LiveView
2. **[02_lifecycle.exs](02_lifecycle.exs)** - mount, handle_event, handle_info
3. **[03_assigns.exs](03_assigns.exs)** - Managing assigns, socket state

### Events and Interactivity
4. **[04_click_events.exs](04_click_events.exs)** - phx-click, phx-submit
5. **[05_form_events.exs](05_form_events.exs)** - phx-change, form handling
6. **[06_key_events.exs](06_key_events.exs)** - phx-keydown, phx-keyup
7. **[07_focus_blur.exs](07_focus_blur.exs)** - phx-focus, phx-blur

### Components
8. **[08_function_components.exs](08_function_components.exs)** - Stateless function components
9. **[09_live_components.exs](09_live_components.exs)** - Stateful LiveComponents
10. **[10_component_slots.exs](10_component_slots.exs)** - Slots, inner blocks

### Navigation
11. **[11_live_navigation.exs](11_live_navigation.exs)** - live_patch, live_redirect
12. **[12_handle_params.exs](12_handle_params.exs)** - URL params in LiveView
13. **[13_live_sessions.exs](13_live_sessions.exs)** - Sharing data across LiveViews

### Real-time Features
14. **[14_pubsub_basics.exs](14_pubsub_basics.exs)** - Phoenix.PubSub integration
15. **[15_presence.exs](15_presence.exs)** - Phoenix.Presence for tracking users
16. **[16_live_uploads.exs](16_live_uploads.exs)** - Drag-and-drop file uploads

### Advanced LiveView
17. **[17_streams.exs](17_streams.exs)** - Efficient large list handling
18. **[18_async_operations.exs](18_async_operations.exs)** - assign_async, start_async
19. **[19_hooks.exs](19_hooks.exs)** - JavaScript hooks
20. **[20_testing_liveview.exs](20_testing_liveview.exs)** - Testing LiveViews

### Project
- **[project_collab_editor/](project_collab_editor/)** - Real-time collaborative document editor

## LiveView Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LiveView Connection                       │
│                                                              │
│  Browser                                Server               │
│  ┌──────────┐    WebSocket    ┌─────────────────┐          │
│  │          │◄───────────────►│    LiveView     │          │
│  │   DOM    │                 │    Process      │          │
│  │          │    Events       │                 │          │
│  │  ┌────┐  │───────────────►│  ┌───────────┐  │          │
│  │  │HTML│  │                 │  │  Socket   │  │          │
│  │  └────┘  │◄───────────────│  │  Assigns  │  │          │
│  │          │    Diffs        │  └───────────┘  │          │
│  └──────────┘                 └─────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## LiveView Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    LiveView Lifecycle                        │
│                                                              │
│  1. HTTP Request (Dead Render)                              │
│           │                                                  │
│           ▼                                                  │
│     mount(params, session, socket)  ◄─── connected?: false  │
│           │                                                  │
│           ▼                                                  │
│     render(assigns)  ──► Static HTML sent                   │
│           │                                                  │
│           ▼                                                  │
│  2. WebSocket Connection (Live Render)                      │
│           │                                                  │
│           ▼                                                  │
│     mount(params, session, socket)  ◄─── connected?: true   │
│           │                                                  │
│           ▼                                                  │
│     handle_params(params, uri, socket)                      │
│           │                                                  │
│           ▼                                                  │
│     render(assigns)  ──► Diff sent via WebSocket            │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     ▼           ▼                                           │
│  handle_event  handle_info                                  │
│     │           │                                           │
│     └─────┬─────┘                                           │
│           ▼                                                  │
│     render(assigns)  ──► Diff sent                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts

- **Socket** - Holds the LiveView state (assigns)
- **Assigns** - Data available in templates
- **Events** - User interactions (clicks, form submissions)
- **Diffs** - Only changed HTML is sent to browser
- **PubSub** - Broadcast updates to multiple clients
- **Presence** - Track connected users

## Event Bindings

| Binding | Description |
|---------|-------------|
| `phx-click` | Click events |
| `phx-submit` | Form submission |
| `phx-change` | Input changes |
| `phx-blur` | Focus lost |
| `phx-focus` | Focus gained |
| `phx-keydown` | Key pressed |
| `phx-keyup` | Key released |
| `phx-window-focus` | Window focused |
| `phx-window-blur` | Window lost focus |

## Time Estimate

- Lessons: 14-18 hours
- Exercises: 6-8 hours
- Project: 8-10 hours
- **Total: 28-36 hours**

## Next Section

After completing this section, proceed to [08_testing](../08_testing/).
