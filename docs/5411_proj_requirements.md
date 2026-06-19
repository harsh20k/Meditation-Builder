# CSCI 5411 — Advanced Cloud Architecting (Summer 2026)
## Term Project Requirements — Graduate Track

**Report Due:** June 30, 2026, 11:59 PM
**One-on-One Meeting:** Scheduled by TA (around the report deadline)

**Required reading:** [AWS Well-Architected Framework documentation](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) — must be read and applied independently.

---

## 1. Project Overview

- Design, architect, and implement a **production-quality, cloud-native application** on AWS or an equivalent public cloud platform.
- Must demonstrate mastery of modern system design principles.
- Must comply with **all six pillars** of the AWS Well-Architected Framework.
- **Deployment environment:** Personal AWS account (professor-approved). No Learner Lab restrictions — all IAM, KMS, Organizations, and security controls are fully implementable.
- Go beyond surface-level descriptions:
  - In-depth trade-off analysis
  - Well-reasoned justification for every major design decision
  - Rigorous evaluation of system quality attributes

---

## 2. Domain Selection

- No restrictions — choose any problem space.
- Example domains (not exhaustive): distributed data pipeline, recommendation engine backend, real-time analytics platform, multi-tenant SaaS API, video processing service, healthcare data exchange, fintech payment gateway.
- Design and develop independently once domain is chosen.

---

## 3. Coding & Cloud Service Requirements

| Requirement | Detail |
|---|---|
| **Non-trivial scope** | Robust enough to support all functionality for the use case. AI-assisted coding tools allowed — **must disclose % of code that is AI-generated** (no grade penalty regardless of %). |
| **No copied code** | Cannot directly copy from public repos, tutorials, or open-source projects. All code must be your own design/implementation/debugging. Third-party libraries/frameworks are permitted — but application logic must be original. |
| **Cloud-native** | Use ≥3 cloud services spanning these categories: compute, networking, messaging, AI (e.g., SageMaker, Bedrock), application integration (e.g., API Gateway, Load Balancer), monitoring. |
| **Persistent state** | Use ≥2 different storage solutions (e.g., relational DB, object storage, NoSQL DB, cache). |
| **Real workload** | Must handle real HTTP/protocol traffic, event-driven triggers, or a scheduled pipeline. |
| **CI/CD** | Must demonstrate full CI/CD pipeline of the implementation. |
| **Operational** | Fully deployable via Infrastructure-as-Code (IaC) with minimal manual intervention. |

---

## 4. System Design Requirements

Report must rigorously address all 5 dimensions, with critical discussion of trade-offs and alternatives throughout.

### 4.1 Functional Requirements Analysis
- Define what the system does (user + business perspective).
- List **all functionalities** of the application.
- List **≥4 user stories or use cases**, organized by priority (must-have vs. nice-to-have).
- **Rubric note:** all actors must be identified, and scenarios clearly explained — not just the stories themselves.

### 4.2 Non-Functional Requirements Analysis
Quantify quality attributes with **measurable targets**, and explicitly explain how each one influenced architectural decisions. Reasonable assumptions are allowed for capacity estimation, resource planning, and scaling policies — **document these assumptions**.

Example dimensions (you may add more for your use case):
- **Scalability:** expected peak RPS, projected growth over 1 year
- **Availability:** e.g., 99.95% = ~4.38 hrs downtime/year
- **Latency:** p95 and p99 response time
- **Durability and RPO:** data retention policy, acceptable data loss window
- **Security and compliance:** relevant standards/regulations (GDPR, HIPAA, PCI-DSS) if applicable
- **Maintainability and deployability:** CI/CD strategy, monitoring approach, distributed tracing

### 4.3 Architecture Design & Diagram
Provide **two complementary diagrams**, each accompanied by a written narrative walking through components and data/request flow:
1. **High-Level Architecture Diagram** — all major components/services, data flows, communication protocols, system entry points.
2. **Data Flow Diagram or Sequence Diagram** — illustrates ≥1 critical end-to-end user journey at request/response level.

- Any diagramming tool allowed (e.g., draw.io, Lucidchart, Miro, or others).

### 4.4 Tech Stack Selection & Justification
For every major component/service:
- State the technology chosen and its role.
- Provide rationale referencing concrete factors (performance, scalability, ecosystem maturity, cost). **Must reference at least one alternative considered** (e.g., why Java over alternatives, why NoSQL over relational for your access patterns).
- Honestly discuss limitations/risks of the chosen stack.

### 4.5 Implementation
Deliver a working, deployable implementation:
- Source code hosted on a **private** GitHub or GitLab repo.
- **Full IaC coverage** — every cloud resource provisioned via AWS CDK, CloudFormation, Terraform, or equivalent. **No manually created resources permitted in the demo environment.**
- **CI/CD pipeline** — minimum: automated testing + deployment to staging/production triggered on merge to main branch.
- **README** containing: architecture summary, prerequisite setup steps, complete deployment instructions.
- Screenshots may be included in the report to demonstrate implementation.
- Must be ready to **demo** IaC setup, CI/CD pipeline, and running application live during the one-on-one meeting.

---

## 5. Deliverables

- **Final report in PDF format**, submitted by **11:59 PM, June 30, 2026**.

---

## 6. Evaluation Breakdown

| Component | Weight |
|---|---|
| Final Report | 70% |
| One-on-One TA Meeting | 30% |

Report is assessed on: completeness, technical depth, quality of justifications, clarity of diagrams, and evidence of compliance with all six AWS Well-Architected pillars.

### One-on-One TA Meeting (20 minutes total)
- **Minutes 0–10:** Student presentation — walk TA through application, architecture, and key design decisions via live demo.
- **Minutes 10–20:** TA questions — expect in-depth questions on AWS Well-Architected Framework compliance, scalability design, failure scenarios, and performance results. Be prepared to **trace a request end-to-end** through the system.
- **Mandatory compliance:** Must present **student ID** at the start of the meeting and keep **face visible on camera for the entire duration**. Failure to comply with either = **0 for the meeting component**.

---

## 7. Grading Rubric

### 7.1 Final Report — 70 points total

| Component | Points | Excellent (Full marks) | Satisfactory | Insufficient |
|---|---|---|---|---|
| **Functional Requirements** | 8 | ≥4 prioritized user stories/use cases, all actors identified, scenarios explained | 1–7: stories present but actors/scenarios unclear | 0: absent or too vague |
| **Non-Functional Requirements** | 8 | All NFRs with measurable targets, each explicitly linked to an architectural decision, capacity assumptions documented | 1–7: most NFRs present but lack measurable targets, architectural linkage, or capacity reasoning | 0: absent or entirely unmeasured |
| **Architecture Diagrams** | 10 | Both diagrams present, clearly labelled, complete; each with narrative explaining components and data flow | 1–9: one diagram missing or key components/flows absent; narrative incomplete/absent | 0: no diagrams, or unreadable |
| **Tech Stack Justification** | 8 | Every major component justified with concrete rationale referencing ≥1 alternative; limitations/risks honestly acknowledged | 1–7: most choices justified but some lack rationale, alternative comparison, or risk discussion | 0: no justification provided |
| **Implementation** | 12 | Full IaC coverage, working CI/CD pipeline, clear README, deployment evidence all present | 1–11: most requirements met but IaC partial, CI/CD missing, or deployment evidence insufficient | 0: no working implementation, or repo inaccessible |
| **AWS Well-Architected Framework (all 6 pillars)** | 24 | All six pillars addressed with concrete decisions, specific AWS services/features cited, ≥1 trade-off discussed **per pillar** | 1–23: most pillars addressed but some lack depth, concrete service-level evidence, or trade-off discussion | 0: fewer than 3 pillars addressed, or compliance not evident |

### 7.2 One-on-One Meeting — 30 points total

| Component | Points | Excellent (Full marks) | Satisfactory | Insufficient |
|---|---|---|---|---|
| **Presentation Quality** | 8 | Well-organized, clear; covers architecture and key decisions with live demo/visual walkthrough | 1–7: understandable but disorganized, or key sections missing | 0: unable to present coherently |
| **Design Decision Defense** | 12 | Confidently defends all major decisions; proposes and critically evaluates alternatives when challenged | 1–11: defends most decisions but uncertain about trade-offs or unable to suggest alternatives on the spot | 0: cannot explain why decisions were made |
| **Technical Depth** | 10 | Demonstrates graduate-level mastery of cloud architecture, system design decisions, and AWS Well-Architected Framework principles/best practices | 1–9: solid foundational understanding but limited depth on trade-offs, failure scenarios, or WAF compliance | 0: cannot answer technical questions at expected graduate level |

---

## Quick Pre-Submission Checklist

- [ ] Domain chosen and justified
- [ ] ≥3 cloud services across required categories
- [ ] ≥2 storage solutions
- [ ] Real workload (HTTP/event/scheduled) implemented
- [ ] AI-generated code % disclosed
- [ ] No copied code from external sources
- [ ] ≥4 prioritized user stories with actors + scenarios
- [ ] NFRs quantified + linked to architecture decisions + capacity assumptions documented
- [ ] High-level architecture diagram + narrative
- [ ] Data flow / sequence diagram + narrative
- [ ] Tech stack justified per component, with alternatives + risks
- [ ] Private repo set up
- [ ] 100% IaC, zero manually created resources in demo env
- [ ] CI/CD: auto test + deploy on merge to main
- [ ] README: architecture summary, setup, deployment steps
- [ ] All 6 Well-Architected pillars addressed with specific AWS services + ≥1 trade-off each
- [ ] Full IAM, KMS, and security controls implemented (personal AWS account, no restrictions)
- [ ] Report exported as PDF, submitted by June 30, 11:59 PM
- [ ] Ready for live demo at TA meeting; student ID + camera on for full duration

---

## 8. AWS Well-Architected Framework — Key Points

> Source: [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) (November 2024)

The framework provides a consistent way to evaluate architectures against best practices and identify areas for improvement. It is not an audit — it is a constructive conversation about architectural decisions.

---

### Pillar 1 — Operational Excellence

**Goal:** Build software correctly while consistently delivering a great customer experience.

**Design Principles:**
- **Organize teams around business outcomes** — Align goals, KPIs, and operating model to business value at all levels.
- **Implement observability for actionable insights** — Use telemetry (metrics, logs, traces) to make informed decisions; proactively improve on performance, reliability, and cost.
- **Safely automate where possible** — Define workloads and operations as code; use guardrails (rate control, error thresholds, approvals) for automation safety.
- **Make frequent, small, reversible changes** — Loosely coupled, incremental deployments reduce blast radius and allow fast rollback.
- **Refine operations procedures frequently** — Regularly review, validate, and update runbooks; gamify to share best practices.
- **Anticipate failure** — Run chaos/failure experiments; test recovery procedures; make informed risk decisions.
- **Learn from all operational events and metrics** — Share lessons learned across the organization.
- **Use managed services** — Reduce operational burden; build procedures around managed service interactions.

---

### Pillar 2 — Security

**Goal:** Protect data, systems, and assets using cloud technologies to improve your security posture.

**Design Principles:**
- **Implement a strong identity foundation** — Least privilege, separation of duties, centralized identity management; eliminate long-term static credentials.
- **Maintain traceability** — Real-time monitoring, alerting, and auditing; integrate logs and metrics with automated response systems.
- **Apply security at all layers** — Defense in depth: edge network, VPC, load balancers, compute, OS, application, and code.
- **Automate security best practices** — Security controls defined as code in version-controlled templates; scale securely and cost-effectively.
- **Protect data in transit and at rest** — Classify data by sensitivity; use encryption, tokenization, and access control.
- **Keep people away from data** — Minimize direct access and manual processing to reduce human error and mishandling risk.
- **Prepare for security events** — Incident management policy, response simulations, and automated detection/investigation/recovery tools.

**Seven Security Areas:** Security foundations · Identity & access management · Detection · Infrastructure protection · Data protection · Incident response · Application security

---

### Pillar 3 — Reliability

**Goal:** Ensure a workload performs its intended function correctly and consistently across its total lifecycle.

**Design Principles:**
- **Automatically recover from failure** — Monitor KPIs tied to business value; automate notification, tracking, and recovery; anticipate failures before they occur.
- **Test recovery procedures** — Use automation to simulate failures and validate recovery strategies before real incidents.
- **Scale horizontally to increase availability** — Replace large resources with many smaller ones; no single point of failure.
- **Stop guessing capacity** — Monitor demand; auto-scale to meet demand without over/under-provisioning; manage service quotas.
- **Manage change through automation** — All infrastructure changes via automation; tracked and reviewed.

---

### Pillar 4 — Performance Efficiency

**Goal:** Use cloud resources efficiently to meet performance requirements as demand and technologies evolve.

**Design Principles:**
- **Democratize advanced technologies** — Consume complex technologies (NoSQL, ML, media transcoding) as managed services; free the team to focus on product.
- **Go global in minutes** — Multi-region deployment for low latency at minimal cost.
- **Use serverless architectures** — Eliminate physical server management; lower transactional cost through managed services at cloud scale.
- **Experiment more often** — Rapidly A/B test instance types, storage, and configurations with virtual resources.
- **Consider mechanical sympathy** — Match technology to the problem (e.g., select DB/storage by access patterns, not familiarity).

---

### Pillar 5 — Cost Optimization

**Goal:** Run systems to deliver business value at the lowest price point.

**Design Principles:**
- **Implement cloud financial management** — Invest in people, processes, and tools to build cost-efficiency capability as a core organizational competency.
- **Adopt a consumption model** — Pay only for what you use; stop/scale down non-production resources when idle (up to 75% savings).
- **Measure overall efficiency** — Track business output vs. cost; understand ROI of increased output or reduced cost.
- **Stop spending on undifferentiated heavy lifting** — Leverage AWS managed services to eliminate data center ops and OS/app management overhead.
- **Analyze and attribute expenditure** — Tag and trace costs to workloads/revenue streams; enable transparent ROI measurement per team/product.

---

### Pillar 6 — Sustainability

**Goal:** Minimize environmental impact — especially energy consumption — of cloud workloads.

**Design Principles:**
- **Understand your impact** — Measure emissions and resource usage per unit of work; use data to set KPIs and evaluate improvements.
- **Establish sustainability goals** — Set long-term targets (e.g., reduce compute/storage per transaction); model ROI of sustainability improvements; plan for growth that reduces impact intensity.
- **Maximize utilization** — Right-size workloads; eliminate idle resources; one host at 60% is more efficient than two at 30%.
- **Anticipate and adopt efficient hardware/software** — Monitor new offerings; design for flexibility to adopt them quickly.
- **Use managed services** — Shared infrastructure reduces per-workload impact (e.g., Fargate, Auto Scaling, S3 Lifecycle policies).
- **Reduce downstream impact** — Minimize energy required by end-users; avoid forcing device upgrades; test impact with device farms.

---

### Quick Compliance Checklist (per pillar)

| Pillar | Key Evidence in Report |
|---|---|
| Operational Excellence | IaC, CI/CD, observability (CloudWatch/X-Ray), runbooks, change management |
| Security | IAM least-privilege, customer-managed KMS CMKs, VPC security groups, WAF/Shield, CloudTrail + S3 Object Lock, SCPs |
| Reliability | Multi-AZ/multi-region, auto-scaling, health checks, tested failover, backup/restore |
| Performance Efficiency | Right-sized compute, caching (ElastiCache/CloudFront), serverless where appropriate, load testing |
| Cost Optimization | Reserved/Spot instances where applicable, resource tagging, idle resource cleanup, Cost Explorer |
| Sustainability | Managed services, auto-scaling to match demand, S3 lifecycle policies, serverless to reduce idle compute |