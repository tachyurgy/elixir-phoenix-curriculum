# Section 9: Deployment and Production

Learn to deploy and operate Elixir applications in production. From releases to monitoring, this section covers everything needed to run reliable services.

## What You'll Learn

- Building releases with mix release
- Docker containerization
- Cloud deployment strategies
- Monitoring and observability
- Performance optimization
- Security best practices

## Prerequisites

- Sections 1-8 completed
- Basic DevOps knowledge helpful
- Familiarity with command line

## Lessons

### Releases
1. **[01_mix_release.exs](01_mix_release.exs)** - Building releases
2. **[02_release_config.exs](02_release_config.exs)** - Runtime configuration
3. **[03_release_commands.exs](03_release_commands.exs)** - Running migrations, custom commands

### Docker
4. **[04_dockerfile.md](04_dockerfile.md)** - Multi-stage Dockerfile
5. **[05_docker_compose.md](05_docker_compose.md)** - Local development with Docker
6. **[06_docker_production.md](06_docker_production.md)** - Production Docker setup

### Cloud Deployment
7. **[07_fly_io.md](07_fly_io.md)** - Deploying to Fly.io
8. **[08_gigalixir.md](08_gigalixir.md)** - Deploying to Gigalixir
9. **[09_aws_ecs.md](09_aws_ecs.md)** - AWS ECS deployment
10. **[10_kubernetes.md](10_kubernetes.md)** - Kubernetes basics

### Production Concerns
11. **[11_environment_config.md](11_environment_config.md)** - Managing configurations
12. **[12_logging.md](12_logging.md)** - Structured logging, Logger
13. **[13_monitoring.md](13_monitoring.md)** - Telemetry, metrics, dashboards
14. **[14_error_tracking.md](14_error_tracking.md)** - Sentry, error reporting

### Performance
15. **[15_profiling.exs](15_profiling.exs)** - Profiling tools, :observer
16. **[16_benchmarking.exs](16_benchmarking.exs)** - Benchee, performance testing
17. **[17_caching.exs](17_caching.exs)** - Caching strategies, Cachex
18. **[18_database_performance.md](18_database_performance.md)** - Query optimization, indexes

### Security
19. **[19_security_checklist.md](19_security_checklist.md)** - OWASP top 10 for Phoenix
20. **[20_ssl_tls.md](20_ssl_tls.md)** - HTTPS configuration
21. **[21_secrets_management.md](21_secrets_management.md)** - Managing secrets

### Project
- **[project_deployment/](project_deployment/)** - Complete deployment pipeline

## Release Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Release Structure                         │
│                                                              │
│  _build/prod/rel/my_app/                                    │
│  ├── bin/                                                   │
│  │   ├── my_app              # Start script                 │
│  │   └── my_app.bat          # Windows script               │
│  ├── lib/                    # Compiled BEAM files          │
│  ├── releases/                                              │
│  │   └── 0.1.0/                                            │
│  │       ├── elixir          # Elixir runtime               │
│  │       ├── iex             # IEx                          │
│  │       ├── remote.vm.args  # VM arguments                 │
│  │       └── sys.config      # System config                │
│  └── erts-X.X/               # Erlang runtime               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                            │
│                                                              │
│  Code Push ──► Tests ──► Build ──► Deploy ──► Health Check  │
│     │           │         │          │            │          │
│     │           │         │          │            │          │
│   Git        ExUnit     Docker    Platform    Monitoring    │
│   Push       mix test   Build     Deploy       Ready        │
│                         Release                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Docker Multi-Stage Build

```dockerfile
# Build stage
FROM hexpm/elixir:1.16.0-erlang-26.2-alpine-3.18.4 as build
WORKDIR /app
# Install deps, compile, build release...

# Runtime stage
FROM alpine:3.18.4 as app
WORKDIR /app
COPY --from=build /app/_build/prod/rel/my_app ./
CMD ["bin/my_app", "start"]
```

## Key Concepts

- **Release** - Self-contained package with BEAM
- **Runtime Config** - Configuration at startup
- **Telemetry** - Metrics and instrumentation
- **Health Checks** - Liveness and readiness probes
- **Blue-Green** - Zero-downtime deployments
- **Rolling Updates** - Gradual deployment

## Production Checklist

- [ ] Environment variables for secrets
- [ ] Database connection pooling configured
- [ ] Logging to stdout/stderr
- [ ] Health check endpoint
- [ ] Error tracking configured
- [ ] Metrics exposed
- [ ] SSL/TLS enabled
- [ ] Rate limiting in place
- [ ] CORS configured
- [ ] Security headers set

## Common Commands

```bash
# Build a release
MIX_ENV=prod mix release

# Start the release
_build/prod/rel/my_app/bin/my_app start

# Run migrations
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate()"

# Remote console
_build/prod/rel/my_app/bin/my_app remote
```

## Time Estimate

- Lessons: 12-16 hours
- Exercises: 5-7 hours
- Project: 6-8 hours
- **Total: 23-31 hours**

## Congratulations!

After completing this section, you've finished the curriculum! You now have the skills to build and deploy production Elixir applications.

See the [appendices](../appendices/) for additional resources and topics for further study.
