---
name: confluent-cloud-setup
description: Use when setting up Confluent Cloud for a project, creating clusters, topics, or API keys, or when Kafka publishing fails with "Unknown Topic Or Partition", SASL authentication errors, or silent publish failures. Also use when onboarding a new repo to stream events to Confluent Cloud.
---

# Confluent Cloud Setup

## Overview

Step-by-step setup for streaming events to Confluent Cloud. Covers environment, cluster, topics, API keys, and local config. Designed to avoid the three most common failure modes: missing topics, wrong API key type, and hardcoded credentials.

## When to Use

- New project needs Confluent Cloud telemetry
- "Unknown Topic Or Partition" errors from Kafka producer
- SASL authentication failures despite valid credentials
- Events write to local JSONL but not to Confluent Cloud
- Onboarding a contributor who needs their own cluster

## Setup Checklist

### 1. Create environment

Go to [confluent.cloud/environments](https://confluent.cloud/environments), click **+ Add cloud environment**.

- Name it after the project (e.g. `pokemon`, `sweeper`)
- Select **Essentials** (free governance tier)

Skip this if reusing an existing environment.

### 2. Create cluster

On the cluster creation page:

| Setting | Value | Why |
|---------|-------|-----|
| **Type** | Basic | Free first eCKU, no ACL enforcement |
| **Provider** | Any (AWS/GCP/Azure) | Pick closest to your users |
| **Region** | Any | Latency only matters for production |

**Use Basic, not Standard.** Standard clusters enforce ACLs, which means service account API keys need explicit WRITE permissions per topic. Basic clusters skip ACL enforcement entirely, so "My account" keys work immediately.

Note the **Bootstrap server** from the cluster overview (e.g. `pkc-xxxxx.region.provider.confluent.cloud:9092`).

### 3. Create topics

Navigate to **Topics** in the cluster sidebar. Create each topic your publisher expects with default settings (6 partitions, default retention).

Topics must be created manually. Confluent Cloud does not auto-create topics from producer requests.

Common topic patterns:
- `{project}.telemetry.raw` for LLM/agent telemetry
- `{project}.game.events` for application events
- `{project}.telemetry` for general telemetry

### 4. Create API key

Go to **API keys** tab in the cluster.

**Select "My account", not "Service account".**

| Key type | ACLs needed? | Works on Basic? | Works on Standard? |
|----------|-------------|-----------------|-------------------|
| My account | No | Yes | Yes |
| Service account | Yes, per-topic | Yes | No (without explicit ACLs) |

Save the key and secret. The secret is shown only once. Download the `api-key-*.txt` file as backup and add `api-key-*.txt` to `.gitignore`.

### 5. Set environment variables

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
export PROJECT_CONFLUENT_API_KEY="<your-api-key>"
export PROJECT_CONFLUENT_API_SECRET="<your-api-secret>"
```

Use a project-specific prefix (e.g. `CONFLUENT_API_KEY`, `SWEEPER_CONFLUENT_API_KEY`) to avoid collisions when working with multiple clusters.

### 6. Configure the project

The config file should reference env var **names**, never raw credentials:

```toml
# CORRECT: references env var names
api_key_env = "SWEEPER_CONFLUENT_API_KEY"
api_secret_env = "SWEEPER_CONFLUENT_API_SECRET"
```

```toml
# WRONG: raw credentials in config
api_key_env = "P5J2SQ3O2ECDHQXA"
api_secret_env = "cflt..."
```

The publisher code does `os.Getenv(config.api_key_env)`. If the config contains the raw key, it tries to look up an env var literally named `P5J2SQ3O2ECDHQXA`.

### 7. Verify

Run a smoke test that publishes one event and check the topic's Messages tab in the Confluent Cloud UI. The "Last message" panel on the topic overview also shows recent events.

## Common Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Unknown Topic Or Partition` | Topic not created in cluster | Create topic manually in Confluent Cloud UI |
| `SASL authentication error` | Env vars not set or not sourced | `source ~/.zshrc`, verify with `echo $VAR_NAME` |
| Events in JSONL but not Kafka | Config has raw key instead of env var name | Change `api_key_env` to reference the env var name |
| `context deadline exceeded` | Cluster still provisioning | Wait 1-2 minutes after cluster creation |
| No errors but topic empty | Service account key on Standard cluster | Create "My account" key, or switch to Basic cluster |
| Publisher falls back to JSONL only | `confluent-kafka` / `kafka-go` not installed | Install optional dependency (`uv sync --extra confluent` or `go mod tidy`) |

## Quick Reference

```
Environment  -->  Cluster (Basic)  -->  Topics  -->  API Key (My account)
                       |                                    |
                  note bootstrap                     save key + secret
                  server URL                         set env vars
                       |                                    |
                       +-----------> config.toml <----------+
                                   (env var names,
                                    not raw secrets)
```
