---
name: confluent-cloud-setup
description: Use when setting up Confluent Cloud for any project, creating clusters, topics, or API keys, or when Kafka publishing fails with "Unknown Topic Or Partition", SASL authentication errors, or silent publish failures. Also use when onboarding contributors to stream events to Confluent Cloud.
---

# Confluent Cloud Setup

## Overview

Step-by-step setup for streaming events to Confluent Cloud from any language or framework. Covers environment, cluster, topics, API keys, and local config. Designed to avoid three common failure modes: missing topics, wrong API key type, and hardcoded credentials.

## When to Use

- New project needs to publish events to Confluent Cloud
- `Unknown Topic Or Partition` errors from a Kafka producer
- `SASL authentication error` despite valid credentials
- Events write locally but never reach Confluent Cloud
- Onboarding a contributor who needs their own cluster

## Setup Checklist

### 1. Create environment

Go to [confluent.cloud/environments](https://confluent.cloud/environments), click **+ Add cloud environment**.

- Name it after the project or team
- Select **Essentials** (free governance tier)

Skip this if reusing an existing environment.

### 2. Create cluster

On the cluster creation page:

| Setting | Value | Why |
|---------|-------|-----|
| **Type** | Basic | Free first eCKU, no ACL enforcement |
| **Provider** | Any (AWS/GCP/Azure) | Pick closest to your users |
| **Region** | Any | Latency only matters for production |

**Use Basic, not Standard.** Standard clusters enforce ACLs, which means service account API keys need explicit WRITE permissions per topic. Basic clusters skip ACL enforcement, so "My account" keys work immediately.

Note the **Bootstrap server** from the cluster overview (e.g. `pkc-xxxxx.region.provider.confluent.cloud:9092`).

### 3. Create topics

Navigate to **Topics** in the cluster sidebar. Create each topic your publisher expects with default settings (6 partitions, default retention).

Topics must be created manually. Confluent Cloud does not auto-create topics from producer requests.

Common naming patterns:
- `{project}.telemetry` for general telemetry
- `{project}.events` for application events
- `{project}.alerts` for downstream alerting

### 4. Create API key

Go to the **API keys** tab in your cluster.

**Select "My account", not "Service account".**

| Key type | ACLs needed? | Works on Basic? | Works on Standard? |
|----------|-------------|-----------------|-------------------|
| My account | No | Yes | Yes |
| Service account | Yes, per-topic | Yes | No (without explicit ACLs) |

Save the key and secret. The secret is shown only once. Download the `api-key-*.txt` backup file and add `api-key-*.txt` to `.gitignore`.

### 5. Set environment variables

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export MYPROJECT_CONFLUENT_API_KEY="<your-api-key>"
export MYPROJECT_CONFLUENT_API_SECRET="<your-api-secret>"
```

Use a project-specific prefix to avoid collisions when working with multiple clusters.

### 6. Configure the project

If your project uses a config file with credential indirection (e.g. `config.toml`, `.env`), the config should reference env var **names**, never raw credentials:

```toml
# CORRECT: references env var names
api_key_env = "MYPROJECT_CONFLUENT_API_KEY"
api_secret_env = "MYPROJECT_CONFLUENT_API_SECRET"
```

```toml
# WRONG: raw credentials in config
api_key_env = "P5J2SQ3O2ECDHQXA"
api_secret_env = "cflt..."
```

Many Kafka publisher implementations resolve credentials via `os.Getenv(config.api_key_env)`. If the config contains the raw key instead of the env var name, the code tries to look up an env var literally named after the key itself.

### 7. Verify

Publish a test event and check the topic's **Messages** tab in the Confluent Cloud UI. The "Last message" panel on the topic overview also shows recent events.

## Common Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Unknown Topic Or Partition` | Topic doesn't exist in the cluster | Create topic manually in Confluent Cloud UI |
| `SASL authentication error` | Env vars not set or not sourced | Source your shell profile, verify with `echo $VAR_NAME` |
| Events write locally but not to Kafka | Config has raw key instead of env var name | Change config to reference the env var name |
| `context deadline exceeded` | Cluster still provisioning | Wait 1-2 minutes after cluster creation |
| No errors but topic is empty | Service account key on Standard cluster | Create "My account" key, or switch to Basic cluster |
| Publisher falls back to local-only | Kafka client library not installed | Install the optional Kafka dependency for your language |

## Quick Reference

```
Environment  -->  Cluster (Basic)  -->  Topics  -->  API Key (My account)
                       |                                    |
                  note bootstrap                     save key + secret
                  server URL                         set env vars
                       |                                    |
                       +----------> project config <--------+
                                  (env var names,
                                   not raw secrets)
```
