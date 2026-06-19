# Architectural Decision Records

Append-only log of architectural trade-offs. See `.cursor/rules/adr.mdc` for format rules.

---

## ADR-001 — Single-region deployment (us-east-1)
**Date:** 2026-06-19
**Decision:** Deploy all AWS resources to us-east-1 only.
**Reason:** Cost and complexity; single-region is sufficient for the academic demo scope.
**Trade-off:** Availability ceiling is ~99.9% (single-region SLA composite); a regional outage would cause full downtime. Architecture supports adding Route 53 latency routing + replica in us-west-2 when needed.
**Status:** Accepted

---

## ADR-002 — DynamoDB on-demand over provisioned capacity
**Date:** 2026-06-19
**Decision:** Use DynamoDB on-demand billing mode.
**Reason:** Traffic is unpredictable at demo scale (1–50 concurrent users); on-demand eliminates capacity planning and throttling risk.
**Trade-off:** Per-request cost is higher than provisioned at sustained high throughput (>~40k RCU/hr); would switch to provisioned + auto-scaling at production scale.
**Status:** Accepted

---

## ADR-003 — AWS Lambda over ECS Fargate for API compute
**Date:** 2026-06-19
**Decision:** Use Lambda (Node.js 22) for all API handlers behind API Gateway.
**Reason:** Serverless removes server management overhead; scales to zero between demo sessions (cost = $0 at rest); no container registry or task definition maintenance.
**Trade-off:** Cold starts add ~200–400ms latency on first invocation; mitigated with provisioned concurrency on the browse endpoint (hot path). Long-running workloads (>15 min) would require Fargate.
**Status:** Accepted

---

## ADR-007 — Terraform over AWS CDK for IaC
**Date:** 2026-06-19
**Decision:** Use Terraform (HCL) instead of AWS CDK (TypeScript) for all infrastructure definition.
**Reason:** Terraform is cloud-agnostic, widely adopted in industry, and produces a portable state file; stronger for demonstrating IaC mastery in an academic context.
**Trade-off:** Terraform requires managing remote state (S3 backend + DynamoDB lock table); CDK would have abstracted this. No native L2 construct shortcuts — every resource is explicitly declared (more verbose, but more transparent).
**Status:** Accepted

---

## ADR-004 — CloudFront in front of API Gateway for GET /routines
**Date:** 2026-06-19
**Decision:** Add a CloudFront distribution with 30s TTL caching in front of the browse endpoint.
**Reason:** Required to meet p99 < 300ms latency target; cache-hits bypass Lambda entirely (<50ms globally).
**Trade-off:** Newly published routines may not appear for up to 30s (eventual consistency). Publish endpoint sends a cache invalidation to mitigate staleness on demand.
**Status:** Accepted

---

## ADR-005 — Cognito User Pool with Sign in with Apple (federated OIDC)
**Date:** 2026-06-19
**Decision:** Use Amazon Cognito User Pool with Apple as a federated OIDC identity provider; no email/password auth.
**Reason:** iOS users already have an Apple ID; native `ASAuthorizationAppleIDProvider` requires no extra SDK and provides the smoothest UX. Cognito `UserPoolIdentityProviderApple` handles token exchange and user record creation.
**Trade-off:** Requires an Apple Developer account (Services ID + private key) configured outside AWS. If Apple revokes the key or changes OIDC metadata, the integration breaks until re-configured. Email/password fallback deliberately omitted to reduce attack surface.
**Status:** Accepted

---

## ADR-006 — Amazon Bedrock (Claude 3 Haiku) for routine tagging
**Date:** 2026-06-19
**Decision:** Use Bedrock Claude 3 Haiku to auto-generate tags and descriptions on routine publish.
**Reason:** Satisfies the AI service requirement (5411 rubric); Haiku is the lowest-latency/cost Bedrock model suitable for short structured outputs.
**Trade-off:** Adds 3–10s latency to the publish flow; mitigated by running Bedrock call asynchronously after initial publish confirmation so the user is not blocked.
**Status:** Accepted
