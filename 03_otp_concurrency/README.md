# Section 3: OTP and Concurrency

Master Elixir's concurrency model and the OTP framework that makes Elixir applications robust and fault-tolerant.

## What You'll Learn

- Process creation and message passing
- GenServer for stateful processes
- Supervisors for fault tolerance
- Other OTP behaviours (Agent, Task, Registry)
- ETS for shared state
- Distributed Elixir basics

## Prerequisites

- Section 1 and 2 completed
- Understanding of recursion
- Basic functional programming concepts

## Lessons

### Processes
1. **[01_spawn_basics.exs](01_spawn_basics.exs)** - spawn, spawn_link, process basics
2. **[02_message_passing.exs](02_message_passing.exs)** - send, receive, mailboxes
3. **[03_process_state.exs](03_process_state.exs)** - Maintaining state with recursion
4. **[04_process_links.exs](04_process_links.exs)** - Links, monitors, trapping exits

### GenServer
5. **[05_genserver_intro.exs](05_genserver_intro.exs)** - Your first GenServer
6. **[06_genserver_callbacks.exs](06_genserver_callbacks.exs)** - init, handle_call, handle_cast, handle_info
7. **[07_genserver_state.exs](07_genserver_state.exs)** - State management patterns
8. **[08_genserver_testing.exs](08_genserver_testing.exs)** - Testing GenServers

### Supervision
9. **[09_supervisor_basics.exs](09_supervisor_basics.exs)** - Supervisor behaviour, child specs
10. **[10_supervision_strategies.exs](10_supervision_strategies.exs)** - one_for_one, one_for_all, rest_for_one
11. **[11_dynamic_supervisors.exs](11_dynamic_supervisors.exs)** - DynamicSupervisor for runtime children
12. **[12_supervision_trees.exs](12_supervision_trees.exs)** - Building supervision trees

### Other OTP Behaviours
13. **[13_agent.exs](13_agent.exs)** - Simple state with Agent
14. **[14_task.exs](14_task.exs)** - Async operations with Task
15. **[15_task_supervisor.exs](15_task_supervisor.exs)** - Supervised async tasks
16. **[16_genstatem.exs](16_genstatem.exs)** - State machines with :gen_statem
17. **[17_registry.exs](17_registry.exs)** - Process registration and discovery

### Advanced Concurrency
18. **[18_ets_basics.exs](18_ets_basics.exs)** - ETS tables for shared state
19. **[19_ets_advanced.exs](19_ets_advanced.exs)** - ETS patterns, concurrent access
20. **[20_distributed_basics.exs](20_distributed_basics.exs)** - Connecting nodes, distributed Elixir

### Project
- **[project_chat_system/](project_chat_system/)** - Multi-room chat with GenServers and supervision

## The BEAM Advantage

Elixir runs on the BEAM (Erlang VM), which provides:

- **Lightweight processes** - Millions of processes per node
- **Preemptive scheduling** - No process can block others
- **Isolation** - Process crashes don't affect others
- **Message passing** - No shared memory between processes
- **Hot code loading** - Update code without stopping

## Key Concepts

```
┌─────────────────────────────────────────────────────────────┐
│                     Supervision Tree                         │
│                                                              │
│                      ┌──────────┐                           │
│                      │   App    │                           │
│                      │Supervisor│                           │
│                      └────┬─────┘                           │
│                           │                                  │
│           ┌───────────────┼───────────────┐                 │
│           │               │               │                  │
│      ┌────┴────┐    ┌────┴────┐    ┌────┴────┐            │
│      │GenServer│    │  Task   │    │  Agent  │            │
│      │ Worker  │    │Supervisor│    │ Worker  │            │
│      └─────────┘    └────┬────┘    └─────────┘            │
│                          │                                  │
│                    ┌─────┴─────┐                           │
│                    │   Tasks   │                           │
│                    └───────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## Running Lessons

```bash
# Run a lesson
elixir 01_spawn_basics.exs

# For GenServer examples, use IEx
iex 05_genserver_intro.exs
```

## Time Estimate

- Lessons: 14-18 hours
- Exercises: 6-8 hours
- Project: 6-8 hours
- **Total: 26-34 hours**

## Next Section

After completing this section, proceed to [04_ecto](../04_ecto/).
