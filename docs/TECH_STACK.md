# Community Library — Tech Stack Justification

> Rationale, alternatives considered, and risks for every major component.
> Last updated: 2026-06-22.

---

## 1. AWS Lambda (Node.js 22)

**Role:** API compute — all HTTP request handlers behind API Gateway.

| Factor | Detail |
|---|---|
| **Why chosen** | Scales to zero between demo sessions (cost = $0 at rest). No container registry, no server management. Node.js 22 has native async/await and first-class AWS SDK v3 support. Cold starts ~200–400ms, mitigated by provisioned concurrency on hot paths. |
| **Alternative considered** | **ECS Fargate** — containers provide more control and better cold-start characteristics. Rejected because Fargate has a minimum ~$8–15/month per task (no scale-to-zero), requires container image builds in CI, and task-definition management adds operational overhead unnecessary at demo scale. |
| **Limitations/risks** | 15-min execution limit (not relevant here; no long-running tasks). VPC attachment adds ~10ms cold-start. Per-invocation cost becomes higher than Fargate at sustained >500k req/day (not a concern for demo). See ADR-003. |

---

## 2. DynamoDB

**Role:** Primary persistence — routines, users, likes, import records, user activity.

| Factor | Detail |
|---|---|
| **Why chosen** | Serverless NoSQL with single-digit-millisecond latency at any scale. On-demand billing eliminates capacity planning for unpredictable demo traffic. Multi-AZ by default. PITR satisfies 24hr RPO. Native DynamoDB Streams feed the Typesense indexing pipeline without a separate CDC connector. |
| **Alternative considered** | **Aurora Serverless v2 (PostgreSQL)** — relational model would simplify ad-hoc queries and enforce referential integrity. Rejected because Aurora Serverless v2 has a minimum ACU floor (~$43/month idle) and per-connection limits that conflict with stateless Lambda invocations. The Community Library access patterns are key-value and fit DynamoDB's strengths; no complex joins needed. |
| **Limitations/risks** | Single-table design is operationally opaque (hard to inspect in console without filtering on `EntityType`). Schema migrations require careful backwards compatibility. Hot partition risk if all browse traffic reads `GSI1PK = "PUBLIC"` at once — mitigated by CloudFront and Redis caching the result. See ADR-002, ADR-012. |

---

## 3. Amazon S3

**Role:** Object storage — audio assets (M4A/MP3) and routine export JSON archives.

| Factor | Detail |
|---|---|
| **Why chosen** | 11-nines durability; effectively infinite storage; versioning eliminates accidental deletion risk. Pay-per-GB-stored with no minimum. Pre-signed URL pattern keeps binary data out of Lambda memory. CloudFront in front of S3 achieves global low-latency audio delivery. |
| **Alternative considered** | **EFS (Elastic File System)** — shared filesystem accessible to Lambdas inside the VPC. Rejected: EFS is designed for concurrent file-system workloads, not object storage. Higher per-GB cost, no versioning, no native CDN integration. S3 is the canonical AWS object store; no reason to deviate. |
| **Limitations/risks** | S3 is eventually consistent on overwrite (although since 2020 S3 provides strong read-after-write consistency). Pre-signed URL expiry management must be handled in Lambda. Object Lock (WORM) would add deletion protection but is not enabled for demo to keep Terraform simpler. |

---

## 4. ElastiCache for Redis (single node)

**Role:** Lambda-side hot cache — browse results (60s TTL), routine detail objects (5min TTL), per-user recommendation results (1hr TTL), like counter absorber (flush every 30s).

| Factor | Detail |
|---|---|
| **Why chosen** | Sub-millisecond read latency eliminates DynamoDB reads on the hottest paths. Redis `INCR` is atomic — safely absorbs like-counter write bursts without DynamoDB hot-key throttling. Satisfies the ≥2 storage solutions requirement with a third distinct tier. |
| **Alternative considered** | **DAX (DynamoDB Accelerator)** — in-memory DynamoDB read cache, seamlessly integrates with DynamoDB API. Rejected because DAX has a minimum 3-node cluster (~$100/month), caches only DynamoDB GetItem/Query responses, and cannot store arbitrary values (like counters, recommendation vectors). Redis is more flexible and cheaper at demo scale. |
| **Limitations/risks** | Requires Lambdas inside a VPC (adds complexity: subnets, security groups, NAT Gateway). Single node has no Multi-AZ failover — a node failure causes a cold-cache period. A Redis node failure means all requests fall through to DynamoDB (degraded but not down). Replication group with 1 replica would add ~$30/month. Deferred for demo. See ADR-010. |

---

## 5. Typesense v27 (self-hosted on EC2 t4g.nano)

**Role:** Full-text search with typo tolerance and relevance ranking across routine name, description, and tags.

| Factor | Detail |
|---|---|
| **Why chosen** | Sub-50ms search latency out of the box. Typo tolerance (Jaro-Winkler distance) handles user spelling errors. Open-source with a permissive license. t4g.nano (~$3.50/month) is far cheaper than any managed search service at demo scale. Widely production-tested (Perplexity, GitLab). |
| **Alternative considered** | **Amazon OpenSearch Serverless** — fully managed, no EC2 to maintain. Rejected: 4 OCU minimum floor = ~$350/month idle cost; prohibitive for a demo project. OpenSearch provisioned is ~$50–100/month minimum. The operational overhead of managing a single EC2 instance is acceptable given the cost differential. |
| **Limitations/risks** | Self-managed: OS patching, crash recovery, and backup are manual responsibilities. Single point of failure — if the t4g.nano becomes unavailable, search returns 503 (browse and recommendations still work). Recovery requires AMI snapshot restore + full re-index (~30min). At production scale (>100k documents or >100 QPS), migrate to OpenSearch Service. Daily S3 snapshot mitigates data loss. See ADR-011. |

---

## 6. Amazon Bedrock (Claude 3 Haiku + Embeddings)

**Role:** (a) Async routine tagging and description generation on publish. (b) Text embeddings for user activity → routine similarity in recommendations.

| Factor | Detail |
|---|---|
| **Why chosen** | Satisfies CSCI 5411 AI service requirement without managing ML infrastructure. Haiku is the lowest-cost/latency Bedrock model suitable for short structured outputs (<5s p95 for tagging). Bedrock embeddings reuse the same API, same IAM role, same VPC egress — no new service to manage. Pay-per-token: demo-scale usage is <$1/month. |
| **Alternative considered** | **Amazon Personalize** — purpose-built recommendation service with collaborative filtering. Rejected: minimum ~1,000 interactions required to train; demo has ~100 users. Training pipeline complexity (dataset groups, solution versions, campaigns) is excessive for the scope. Also considered **OpenAI API** — rejected because it requires a third-party API key, adds external dependency, and AWS Bedrock keeps all data within AWS. See ADR-006, ADR-009. |
| **Limitations/risks** | Bedrock calls require Lambda to be inside a VPC (same NAT Gateway as Redis). Haiku is fast but still 3–10s for a structured JSON output — mitigated by running async via SQS. Embedding model is not fine-tuned on meditation domain; general-purpose embeddings may conflate unrelated wellness tags. At production scale, fine-tuned embeddings or Personalize would improve recommendation quality. |

---

## 7. Amazon Cognito + Sign in with Apple

**Role:** Authentication (user identity) and authorization (JWT issuance for API access).

| Factor | Detail |
|---|---|
| **Why chosen** | iOS users already have an Apple ID; native `ASAuthorizationAppleIDProvider` requires no extra SDK. Cognito `UserPoolIdentityProviderApple` handles OIDC token exchange, user record creation, and JWT issuance transparently. API Gateway Cognito Authorizer validates JWTs without Lambda code. No custom auth UI; no password database to protect. |
| **Alternative considered** | **Firebase Auth** — excellent Apple Sign-In support, simpler setup. Rejected because the rest of the stack is AWS-native; adding Firebase creates a cross-cloud dependency for identity, complicating IAM integration (Lambda → Cognito is IAM-native; Lambda → Firebase requires custom validation). Also considered **Auth0** — rejected for the same cross-cloud reason and per-MAU pricing at scale. |
| **Limitations/risks** | Requires an Apple Developer account (paid, $99/year) with a Services ID and private key registered outside AWS. If Apple rotates OIDC metadata or changes the sub format, the integration requires manual re-configuration. Cognito hosted UI is not used (native Apple flow only) — any future addition of email/password auth requires Cognito User Pool reconfiguration. See ADR-005. |

---

## 8. API Gateway (REST)

**Role:** HTTP front-door — routing, request validation, Cognito authorization, throttling, and Lambda proxy integration.

| Factor | Detail |
|---|---|
| **Why chosen** | First-class Cognito Authorizer support (zero Lambda code needed for JWT validation). Request/response schema validation via JSON Schema models. Stage-level throttling (burst/steady-state RPS). Native X-Ray integration. Pay-per-request (no idle cost). REST API (not HTTP API) chosen for the request validation feature and usage plans. |
| **Alternative considered** | **API Gateway HTTP API** — faster, cheaper (~70% less per request), supports JWT auth natively. Rejected because HTTP API lacks full request body validation (only header/query) and usage plans. The cost saving is negligible at demo scale (<$1/month difference). Also considered **AWS AppSync (GraphQL)** — rejected because the iOS client already targets a REST design and GraphQL adds unnecessary complexity. |
| **Limitations/risks** | REST API has a 29-second integration timeout (Lambda must respond within 29s — not an issue here). Payload limit is 10MB (well above our use case). Stage variables for environment separation require careful Terraform management. |

---

## 9. CloudFront

**Role:** CDN — caches unauthenticated GET /routines and GET /routines/{id} responses; delivers S3 audio assets globally.

| Factor | Detail |
|---|---|
| **Why chosen** | Edge caching reduces API Gateway and Lambda invocations on the hottest read paths to near-zero. Sub-50ms globally for cache hits. Free HTTPS termination with ACM certificate. Cache invalidation API allows precise staleness control on publish/update/delete. |
| **Alternative considered** | **Nginx on EC2 as reverse proxy** — gives more control over caching rules. Rejected: adds a server to manage (no scale-to-zero), requires ELB for HA, and eliminates global PoP distribution. CloudFront is the canonical AWS CDN; no reason to introduce EC2 for this role. |
| **Limitations/risks** | CloudFront adds ~2–5ms to first-byte latency compared to direct API Gateway for non-cached responses (acceptable). Cache invalidation takes up to 5min globally in edge cases (targeted path invalidation is typically seconds). `Vary: Authorization` causes CloudFront to not cache authenticated responses — by design. |

---

## 10. SQS

**Role:** Messaging — decouples publish Lambda from Bedrock tagging Lambda. Routine publish enqueues a message; tagging Lambda consumes it asynchronously.

| Factor | Detail |
|---|---|
| **Why chosen** | Standard queue provides at-least-once delivery with visibility timeout — if the tagging Lambda fails, the message becomes visible again and is retried. Dead-letter queue (DLQ) captures permanently failed messages. Decoupling means a Bedrock timeout/outage does not affect the publish API response time. |
| **Alternative considered** | **EventBridge** — more expressive event bus with pattern matching and multiple targets. Rejected for this use case because the publish → tagging flow is a simple point-to-point queue; EventBridge's flexibility is unused overhead. SQS is simpler and has a lower per-message cost. |
| **Limitations/risks** | Standard SQS guarantees at-least-once delivery (not exactly-once). The tagging Lambda must be idempotent (upsert DynamoDB tags, not append). Message visibility timeout must be set > Bedrock p99 latency (~15s) to avoid duplicate processing. |

---

## 11. SNS

**Role:** Fan-out push notifications — like event → SNS topic → Lambda → APNs (Apple Push Notification service) → author's device.

| Factor | Detail |
|---|---|
| **Why chosen** | SNS supports APNs as a native platform endpoint — no custom iOS push infrastructure needed. Decouples the like Lambda from APNs delivery (SNS retries APNs failures). Pay-per-notification (negligible cost at demo scale). |
| **Alternative considered** | **Direct Lambda → APNs HTTP/2 call** — simpler, no SNS dependency. Rejected because direct calls require managing APNs certificate/key rotation in Lambda environment variables, and there is no automatic retry on APNs delivery failure. SNS abstracts this cleanly. |
| **Limitations/risks** | APNs device tokens must be registered in SNS as platform endpoints (requires an additional `/device/register` API endpoint — planned but out of demo scope). Without endpoint registration, SNS push cannot reach devices. Workaround for demo: log the like event; push notification is a nice-to-have for US-6. |

---

## 12. Terraform (HCL)

**Role:** IaC — defines all AWS resources; state stored in S3 + DynamoDB lock table; two workspaces: `staging` and `production`.

| Factor | Detail |
|---|---|
| **Why chosen** | Cloud-agnostic, industry-standard, readable HCL syntax. Strong academic precedent for demonstrating IaC mastery. Produces a deterministic plan before apply (`terraform plan`). Workspace support provides clean environment separation without duplicate code. |
| **Alternative considered** | **AWS CDK (TypeScript)** — shares the same language as Lambda handlers (TypeScript); L2 constructs abstract boilerplate. Rejected because CDK generates CloudFormation under the hood (less transparent), state management is handled by CloudFormation stacks (harder to inspect), and CDK's abstraction hides the infrastructure details that the CSCI 5411 rubric expects. See ADR-007. |
| **Limitations/risks** | Terraform state stored in S3 must be bootstrapped manually (chicken-and-egg: the S3 bucket for state must exist before `terraform init`). Mitigated with a one-time `terraform apply` from local for the state bucket. HCL is verbose compared to CDK L2 constructs — every VPC subnet and security group is explicit (acceptable trade-off for transparency). |

---

## 13. GitHub Actions

**Role:** CI/CD — runs `terraform plan` on PRs, `terraform apply` to staging on merge to `main`, manual approval gate for production deploy.

| Factor | Detail |
|---|---|
| **Why chosen** | Free for public repos; native integration with GitHub PR workflow. OIDC-based AWS credentials (no long-lived keys in secrets). Matrix builds for plan/apply across workspaces. |
| **Alternative considered** | **AWS CodePipeline + CodeBuild** — fully AWS-native; no external CI vendor dependency. Rejected because the source repo is on GitHub, requiring GitHub → CodePipeline webhook integration (extra setup). GitHub Actions is simpler and the team is already familiar with it. |
| **Limitations/risks** | GitHub-hosted runners have limited compute (2 vCPU, 7GB RAM) — sufficient for Terraform operations but would need self-hosted runners for large test suites. OIDC trust configuration must be kept in sync with the Terraform IAM role ARN. |

---

## 14. CloudWatch + X-Ray

**Role:** Observability — metrics, dashboards, alarms, and distributed request tracing.

| Factor | Detail |
|---|---|
| **Why chosen** | CloudWatch is the native AWS monitoring plane — all Lambda, API Gateway, DynamoDB, and ElastiCache metrics flow there automatically with zero configuration. X-Ray provides end-to-end trace visualization across API Gateway → Lambda → DynamoDB → Redis → Typesense, making latency bottleneck identification straightforward. Both are integrated via Lambda active tracing (single env var). |
| **Alternative considered** | **Datadog** — richer dashboards, better anomaly detection, strong APM. Rejected because Datadog adds per-host/per-GB cost and requires a Datadog agent (Lambda extension), which increases cold-start time. For demo scale, CloudWatch + X-Ray provides sufficient observability at zero additional cost. |
| **Limitations/risks** | CloudWatch metrics have 1-minute granularity by default (high-resolution metrics cost extra). X-Ray does not trace into Typesense (self-hosted EC2) — Typesense latency is measured via Lambda timing instrumentation only. CloudWatch Log Insights queries are powerful but have a per-query cost that can accumulate during incident investigation. |
