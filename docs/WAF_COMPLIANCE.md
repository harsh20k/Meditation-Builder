# Community Library — AWS Well-Architected Framework Compliance

> Maps each of the 6 WAF pillars to concrete architectural decisions in the Community Library backend.
> ADR references point to `docs/ADR.md`.
> Last updated: 2026-06-22.

---

## 1. Operational Excellence

**Definition:** The ability to run and monitor systems to deliver business value, and to continually improve supporting processes and procedures.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| GitHub Actions | CI/CD pipeline — automated plan on PR, apply on merge |
| Terraform (workspaces) | IaC — 100% of resources declared; zero manual console changes |
| CloudWatch Dashboards | Real-time error rate, latency p50/p95/p99, throttle counts |
| CloudWatch Alarms | Alert on Lambda error rate >1%, p99 latency breach, DLQ depth >0 |
| X-Ray Active Tracing | Distributed trace map across API Gateway → Lambda → DynamoDB → Redis |
| Structured JSON Logs | Lambda emits `{level, requestId, duration, error}` — searchable in Log Insights |
| SQS Dead-Letter Queue | Captures failed tagging Lambda invocations for investigation |
| Terraform S3 Backend | State file in versioned S3 bucket + DynamoDB lock table |

### Architectural Decisions

- **ADR-007:** Terraform chosen over CDK — explicit, readable HCL with deterministic `plan` output before every `apply`.
- Runbooks stored in `docs/` alongside IaC — operational procedures are version-controlled with the code.
- Deployment time target: `terraform apply` completes in <5 min from clean state (measured in CI).
- All Lambdas emit structured JSON logs; `requestId` is propagated from API Gateway → Lambda → all downstream calls for end-to-end trace correlation.

### Trade-off

Typesense on EC2 breaks the "use managed services" principle of Operational Excellence. OS patching, crash detection, and restart are manual. Mitigated with a CloudWatch alarm on the EC2 status check and a documented 30-min recovery runbook.

### What Would Be Added in Production

- AWS Systems Manager Session Manager for secure EC2 access (no SSH key management).
- Automated rollback via CloudWatch Alarm → Lambda → `terraform apply` previous revision.
- Chaos engineering (AWS Fault Injection Service) to validate runbooks under simulated failures.
- On-call rotation and escalation policy (PagerDuty or OpsGenie).

---

## 2. Security

**Definition:** The ability to protect information, systems, and assets while delivering business value through risk assessments and mitigation strategies.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| Cognito User Pool + Apple OIDC | Identity — federated, no password database to protect |
| API Gateway Cognito Authorizer | JWT validation at the edge; Lambda never sees unauthenticated requests on protected routes |
| AWS KMS (CMKs) | Encryption at rest for DynamoDB and S3; automatic key rotation enabled |
| VPC + Security Groups | Network isolation — ElastiCache only reachable from Lambda security group; no public inbound |
| IAM least-privilege roles | Each Lambda has a dedicated role with exactly the permissions it uses |
| AWS Organizations SCPs | Prevent disabling CloudTrail, enabling public S3 buckets, creating IAM admin users |
| CloudTrail + S3 Object Lock | Immutable audit log of all AWS API calls |
| TLS 1.2+ enforcement | API Gateway and CloudFront enforce HTTPS; HTTP redirected |
| API Gateway request validation | JSON Schema validation on request bodies before Lambda invocation |
| Cognito token expiry | Access token: 1hr; refresh token: 30 days |

### Architectural Decisions

- **ADR-005:** Sign in with Apple only — no email/password reduces attack surface (no credential stuffing, no phishing via weak passwords).
- Lambda handlers validate the `sub` claim for ownership checks on DELETE /routines/{id} — prevents users from deleting others' routines even if a valid JWT is present.
- S3 bucket policy: `Block Public Access` enabled; audio assets served exclusively via CloudFront with signed URLs (pre-signed URL expiry: 1hr).
- Principle of least privilege: publish Lambda has `dynamodb:PutItem` on the routines table but not `dynamodb:DeleteItem`; delete Lambda is a separate function with only `dynamodb:TransactWriteItems`.

### Trade-off

ElastiCache Redis has no TLS enabled by default in the demo configuration (in-transit encryption is an ElastiCache config option that requires a TLS-capable Redis client). For demo scope, Redis is fully inside the VPC (no public exposure), so unencrypted in-transit is acceptable. In production, `transit_encryption_enabled = true` would be set in Terraform.

### What Would Be Added in Production

- AWS WAF in front of CloudFront: rate-limiting rules, SQL injection / XSS detection, geo-blocking.
- Secrets Manager for Typesense API key and any third-party credentials (currently in SSM Parameter Store SecureString).
- GuardDuty for threat detection on CloudTrail and VPC flow logs.
- Cognito advanced security features (compromised credential checks, adaptive authentication).
- Penetration testing and security review before public launch.

---

## 3. Reliability

**Definition:** The ability of a workload to perform its intended function correctly and consistently when it's expected to.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| Lambda (serverless) | Auto-scales; no instance health to manage; per-invocation isolation |
| DynamoDB Multi-AZ | Built-in; data replicated across 3 AZs in us-east-1 |
| DynamoDB PITR | 24hr RPO; point-in-time restore for data corruption events |
| S3 versioning | Immutable object history; accidental deletes recoverable |
| SQS + DLQ | Tagging pipeline retries automatically; failures captured in DLQ |
| CloudFront | Origin failover config: if API Gateway returns 5xx, CloudFront can be configured with an origin group (reserved for production) |
| Provisioned concurrency | browse-routines and get-routine Lambdas: 2 warm instances; eliminates cold-start-induced latency spikes |
| API Gateway throttling | Prevents runaway clients from cascading Lambda failures |
| ElastiCache VPC | Redis node failure triggers cold-cache fallback to DynamoDB (degraded, not down) |

### Architectural Decisions

- **ADR-001:** Single-region (us-east-1) with architecture documented for future multi-region extension via Route 53 latency routing. 99.9% availability target matches the composite Lambda + API Gateway SLA.
- **ADR-008:** Provisioned concurrency on hot-path Lambdas to prevent cold-start cascades under load.
- **ADR-010:** Redis cache failure is non-fatal — Lambda catch block falls through to DynamoDB on Redis connection timeout (50ms timeout before fallback).
- RTO targets:
  - Lambda/API Gateway: near-zero (serverless auto-recovers within seconds of an AZ failure).
  - DynamoDB PITR restore: 1–4 hrs depending on data volume (documented in REQUIREMENTS_MARKETPLACE.md §2.4).
  - Typesense EC2: 30 min (AMI snapshot restore + full re-index).

### Trade-off

Single-region deployment means a full us-east-1 outage (extremely rare — <0.1% historically) causes complete downtime. Multi-region active-active would bring availability to 99.99%+ but requires DynamoDB Global Tables (~2× data cost), multi-region Cognito, and active-active CloudFront origins. Deferred for cost reasons (ADR-001).

### What Would Be Added in Production

- DynamoDB Global Tables with a warm standby in us-west-2; Route 53 health-check failover.
- ElastiCache replication group with 1 replica for Redis Multi-AZ.
- Typesense on ECS Fargate (managed, auto-restart) or migration to OpenSearch Service.
- AWS Health dashboard alerts for service disruptions.
- Load testing (k6 or Artillery) in CI against staging to validate latency targets before production deploy.

---

## 4. Performance Efficiency

**Definition:** The ability to use computing resources efficiently to meet system requirements, and to maintain that efficiency as demand changes and technologies evolve.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| CloudFront (30s + 5min TTL) | Browse and detail cache-hits at <50ms globally; Lambda not invoked |
| ElastiCache Redis | Sub-millisecond cache layer for browse, detail, recommendations, like counters |
| Provisioned concurrency | Eliminates cold starts on p99 paths for browse and detail |
| DynamoDB single-table | Single GetItem/Query for most access patterns; no cross-table joins |
| Typesense | Purpose-built search engine — sub-50ms full-text search, typo-tolerant |
| Bedrock Claude 3 Haiku | Lowest-latency/cost Bedrock model for tagging; async via SQS so not on critical path |
| Lambda ARM (Graviton2) | Node.js 22 on `arm64` architecture — ~20% better price/performance vs x86 |
| DynamoDB GSIs | Pre-computed sort orders for browse-newest and author-routines; no table scan |

### Architectural Decisions

- **ADR-004:** CloudFront caching on browse endpoint. Cache-hit rate target: >80% for browse (most users see the same top-20 results).
- **ADR-008:** Provisioned concurrency on get-routine Lambda; CloudFront 5-min TTL means only ~2% of requests reach Lambda (cache misses).
- **ADR-010:** Redis L1 cache serves recommendations at p50 <50ms vs 800ms Bedrock cold path.
- **ADR-009:** Embedding similarity cached per user (1hr TTL) — Bedrock InvokeModel called at most once per user per hour.
- DynamoDB GSI1 projection is `INCLUDE` (not `ALL`) — reduces projection cost by excluding the `blocks` blob from the browse index; blocks are only fetched on detail view.

### Trade-off

Embedding-based recommendations are computationally straightforward but less accurate than collaborative filtering (Personalize). At demo scale this is acceptable. The Redis cache absorbs the Bedrock latency, but if Redis is cold and Bedrock is slow (p99 ~15s for embeddings), GET /recommendations p99 could miss the 150ms target — mitigated by serving a stale cached result for up to 5 min (stale-while-revalidate pattern in Lambda).

### What Would Be Added in Production

- DynamoDB Auto Scaling (provisioned mode with application auto scaling) at sustained >10k RPS to reduce per-request cost vs on-demand.
- ElastiCache cluster mode (sharding) for Redis horizontal scaling beyond a single node.
- CloudFront Functions (edge compute) for lightweight auth header stripping and cache key normalization.
- Right-sizing analysis of Lambda memory (currently 512MB default) using Lambda Power Tuning.

---

## 5. Cost Optimization

**Definition:** The ability to run systems to deliver business value at the lowest price point.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| Lambda (scale-to-zero) | No cost between demo sessions; pay only per invocation |
| DynamoDB on-demand | No idle capacity cost; pay per read/write unit |
| S3 Standard | Cheapest durable object storage; lifecycle policy moves old exports to S3-IA after 30 days |
| Typesense on EC2 t4g.nano | ~$3.50/month vs ~$350/month (OpenSearch Serverless) |
| ElastiCache cache.t4g.micro | ~$12/month single node; absorbs DynamoDB RCU cost at high traffic |
| CloudFront caching | Reduces Lambda invocations and DynamoDB reads on hot paths |
| Terraform staging teardown | `terraform destroy` on staging after demo eliminates ongoing cost |
| Graviton2 Lambdas (arm64) | ~20% cheaper per GB-second than x86 |
| Bedrock on-demand | Pay-per-token; demo-scale tagging + recommendations <$1/month |

### Architectural Decisions

- **ADR-002:** DynamoDB on-demand chosen over provisioned — avoids paying for idle capacity during the academic demo phase.
- **ADR-003:** Lambda over Fargate — Fargate minimum cost is ~$15–30/month even at zero traffic.
- **ADR-011:** Typesense on t4g.nano — 100× cheaper than OpenSearch Serverless for demo scale.
- Staging Terraform workspace is destroyed after the demo (`terraform destroy`) — no ongoing cost for staging resources post-submission.
- CloudFront caching reduces Lambda invocations on browse by >80% (cache-hit scenario), translating to direct Lambda cost savings.

### Estimated Monthly Cost (demo scale, staging destroyed post-demo)

| Component | Est. Cost/Month |
|---|---|
| Lambda (browse, detail, publish, etc.) | <$1 |
| API Gateway (REST) | <$1 |
| DynamoDB (on-demand, ~100k req/day) | <$1 |
| ElastiCache cache.t4g.micro (1 node) | ~$12 |
| EC2 t4g.nano (Typesense) | ~$3.50 |
| S3 (audio assets, <10 GB) | <$1 |
| CloudFront (<10 GB transfer) | <$1 |
| NAT Gateway (VPC egress) | ~$4.50 |
| Bedrock (Claude 3 Haiku, embeddings) | <$1 |
| **Total (production, always-on)** | **~$25–30/month** |

### Trade-off

ElastiCache and NAT Gateway together account for ~60% of the monthly cost ($16.50). Without Redis, all Lambda invocations hit DynamoDB — acceptable for demo scale but fails latency targets. Without NAT Gateway, Lambdas in the VPC cannot reach Bedrock or Cognito. These are required costs to meet NFRs.

### What Would Be Added in Production

- AWS Cost Anomaly Detection (alerts on unexpected spend spikes).
- DynamoDB provisioned capacity + auto scaling at sustained load >10k RPS (lower per-unit cost than on-demand).
- S3 Intelligent-Tiering for audio assets after 30 days.
- Reserved Instances for ElastiCache and EC2 Typesense at production scale (1-year RI ~40% savings).
- Compute Savings Plans for Lambda at production scale.

---

## 6. Sustainability

**Definition:** The ability to continually improve sustainability impacts by reducing energy consumption and increasing efficiency across all components of a workload.

### Services / Features Used

| AWS Service / Feature | Role |
|---|---|
| Lambda (scale-to-zero) | Zero compute consumption between requests; no idle server energy |
| Graviton2 (arm64) Lambdas | AWS Graviton2 processors are ~60% more energy-efficient than comparable x86 |
| EC2 t4g.nano (Graviton2) | Typesense runs on Graviton2 — same efficiency benefit |
| ElastiCache cache.t4g.micro (Graviton2) | AWS cache.t4g instances use Graviton2 |
| DynamoDB + S3 (multi-tenant managed) | AWS operates shared infrastructure at high utilization — more efficient per request than dedicated hardware |
| CloudFront caching | Fewer origin requests = less Lambda compute per user request |
| us-east-1 | AWS Northern Virginia region uses a high percentage of renewable energy as part of AWS's net-zero commitment |

### Architectural Decisions

- All EC2/ElastiCache instances use Graviton2 (t4g family) — chosen partly for cost but also for lower power consumption per compute unit.
- CloudFront and Redis caching reduce total compute invocations for the same workload — this directly reduces energy per API call.
- Serverless Lambda means no idle CPU cycles between requests (unlike a persistent EC2 or ECS task running at 5% utilization).
- DynamoDB Streams-based Typesense indexing is event-driven (no polling) — avoids wasted compute on empty scans.

### Trade-off

A single-region deployment in us-east-1 does not minimize network latency for all global users (higher latency → clients retry → more compute per user session). Multi-region would improve both UX and sustainability but is deferred for cost. The single-region architecture uses AWS's shared infrastructure which is more carbon-efficient than a comparable self-hosted deployment.

### What Would Be Added in Production

- AWS Customer Carbon Footprint Tool to track and report kgCO₂e per month.
- Multi-region deployment in AWS regions with higher renewable energy percentage (e.g., eu-west-1 Dublin, us-west-2 Oregon).
- S3 lifecycle policies to delete stale routine exports and unused audio assets (reduce storage energy).
- EventBridge Scheduler for non-urgent Lambda jobs (like-counter flush, recommendation pre-computation) during off-peak hours to shift compute to low-utilization periods.
