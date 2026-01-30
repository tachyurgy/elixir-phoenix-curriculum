# Section 6: Phoenix Advanced

Take your Phoenix skills further with authentication, APIs, background jobs, and more.

## What You'll Learn

- User authentication with phx.gen.auth
- Authorization patterns
- Building JSON APIs
- Background job processing with Oban
- Email delivery with Swoosh
- File uploads

## Prerequisites

- Section 5 (Phoenix Fundamentals) completed
- Understanding of Phoenix MVC
- Database operations with Ecto

## Lessons

### Authentication
1. **[01_auth_overview.md](01_auth_overview.md)** - Authentication strategies overview
2. **[02_phx_gen_auth.exs](02_phx_gen_auth.exs)** - Using phx.gen.auth
3. **[03_session_auth.exs](03_session_auth.exs)** - Session-based authentication
4. **[04_token_auth.exs](04_token_auth.exs)** - Token/API authentication
5. **[05_oauth_basics.exs](05_oauth_basics.exs)** - OAuth integration with Ueberauth

### Authorization
6. **[06_authorization_patterns.exs](06_authorization_patterns.exs)** - Role-based access control
7. **[07_policy_modules.exs](07_policy_modules.exs)** - Building authorization policies
8. **[08_bodyguard.exs](08_bodyguard.exs)** - Using Bodyguard library

### JSON APIs
9. **[09_api_basics.exs](09_api_basics.exs)** - JSON rendering, API pipelines
10. **[10_api_versioning.exs](10_api_versioning.exs)** - API versioning strategies
11. **[11_api_documentation.exs](11_api_documentation.exs)** - OpenAPI/Swagger docs
12. **[12_graphql_intro.exs](12_graphql_intro.exs)** - Absinthe GraphQL basics

### Background Jobs
13. **[13_oban_setup.exs](13_oban_setup.exs)** - Setting up Oban
14. **[14_oban_workers.exs](14_oban_workers.exs)** - Creating workers
15. **[15_oban_scheduling.exs](15_oban_scheduling.exs)** - Scheduled jobs, cron
16. **[16_oban_testing.exs](16_oban_testing.exs)** - Testing Oban workers

### Email
17. **[17_swoosh_setup.exs](17_swoosh_setup.exs)** - Configuring Swoosh
18. **[18_email_templates.exs](18_email_templates.exs)** - Email layouts and templates
19. **[19_email_delivery.exs](19_email_delivery.exs)** - Sending emails, adapters

### File Uploads
20. **[20_upload_basics.exs](20_upload_basics.exs)** - Handling file uploads
21. **[21_direct_uploads.exs](21_direct_uploads.exs)** - Direct to S3 uploads
22. **[22_image_processing.exs](22_image_processing.exs)** - Image manipulation

### Project
- **[project_blog_advanced/](project_blog_advanced/)** - Blog with auth, comments, admin

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Authentication Flow                       │
│                                                              │
│  1. User submits credentials                                │
│           │                                                  │
│           ▼                                                  │
│  2. Controller validates with Context                       │
│           │                                                  │
│           ▼                                                  │
│  3. Context checks database                                 │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     ▼           ▼                                           │
│  Success     Failure                                        │
│     │           │                                           │
│     ▼           ▼                                           │
│  Create      Return                                         │
│  Session     Error                                          │
│     │                                                        │
│     ▼                                                        │
│  4. Redirect with session token                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## API Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      API Structure                           │
│                                                              │
│  Client ──► API Router ──► API Pipeline ──► Controller      │
│                               │                 │            │
│                          ┌────┴────┐           │            │
│                          │ Plugs   │           │            │
│                          │ - Auth  │           ▼            │
│                          │ - JSON  │       Context          │
│                          └─────────┘           │            │
│                                                ▼            │
│                                            Response          │
│                                          (JSON/Error)        │
└─────────────────────────────────────────────────────────────┘
```

## Key Dependencies

```elixir
# mix.exs
defp deps do
  [
    {:oban, "~> 2.17"},           # Background jobs
    {:swoosh, "~> 1.15"},         # Email
    {:ueberauth, "~> 0.10"},      # OAuth
    {:bodyguard, "~> 2.4"},       # Authorization
    {:open_api_spex, "~> 3.18"},  # API docs
    {:absinthe, "~> 1.7"},        # GraphQL
  ]
end
```

## Time Estimate

- Lessons: 14-18 hours
- Exercises: 6-8 hours
- Project: 8-10 hours
- **Total: 28-36 hours**

## Next Section

After completing this section, proceed to [07_liveview](../07_liveview/).
