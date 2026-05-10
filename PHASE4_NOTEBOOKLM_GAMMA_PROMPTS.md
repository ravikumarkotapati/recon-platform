# Phase 4 - NotebookLM and Gamma Prompts

These prompts demonstrate AI-assisted architecture generation without blindly accepting generated output. Use them with the source repository, Phase 2 runbook, Phase 4 architecture document, and Phase 6 observability document.

## NotebookLM Source Set

Upload or reference these files:

```text
E:\workspace\README.md
E:\workspace\PHASE2_RESILIENCY_RUNBOOK.md
E:\workspace\PHASE2_MQRC2035_FAILURE_ANALYSIS.md
E:\workspace\PHASE4_ARCHITECTURE_DESIGN.md
E:\workspace\PHASE6_OBSERVABILITY_SRE.md
E:\workspace\aws-kubernetes\README.md
E:\workspace\aws-kubernetes\manifests
E:\workspace\recon-producer-app
E:\workspace\recon-consumer-app
E:\workspace\recon-dashboard-api
```

## NotebookLM Prompt - Architecture Review

```text
Act as a Principal Engineer reviewing a banking-grade reconciliation platform.

Using only the uploaded source documents, produce:
1. A concise system context summary.
2. A component-by-component architecture explanation.
3. Message flow explanation from producer to IBM MQ to consumer to PostgreSQL.
4. Retry, backout, DLQ, and replay explanation.
5. Kubernetes and AWS deployment explanation.
6. Security model review, including AWS Secrets Manager, IRSA, IBM MQ OAM, and network boundaries.
7. Observability review, including logs, metrics, traces, Prometheus, Grafana, and Jaeger.
8. HA/DR review.
9. Scaling strategy and likely bottlenecks.
10. Five risks an evaluator might challenge and how to answer them.

Do not invent components that are not present in the uploaded files.
Highlight any gaps separately as recommendations.
```

## NotebookLM Prompt - Failure Analysis

```text
Create an incident walkthrough for the MQRC 2035 issue observed in the EKS deployment.

Use the uploaded MQRC 2035 failure analysis and runbook.
Include:
- Symptoms
- Commands used
- Evidence from logs
- Root cause
- Why pods were still healthy
- Fix commands
- Validation commands
- Lessons learned
- How this proves production engineering maturity

Keep the explanation suitable for a technical assessment panel.
```

## NotebookLM Prompt - Architecture Q&A

```text
Generate 25 likely interview questions and strong answers for this reconciliation platform.

Cover:
- IBM MQ topology
- retry and DLQ design
- idempotency
- deadlock handling
- circuit breaker and bulkhead
- Kubernetes deployment
- AWS networking
- security and secrets
- observability
- HA/DR
- scaling and cost
- AI-assisted engineering judgement

Answers should be specific to the uploaded implementation and should not be generic.
```

## Gamma Prompt - Presentation Deck

```text
Create a professional architecture review deck for a Principal Engineer / Architect assessment.

Topic:
Banking-grade reconciliation platform using Java 17, IBM MQ, PostgreSQL, Docker, Kubernetes, AWS EKS, AWS Secrets Manager, Prometheus, Grafana, and Jaeger.

Audience:
Enterprise architecture review panel and engineering assessors.

Tone:
Concise, technical, production-focused, evidence-based.

Required slides:
1. Title: NTT Reconciliation Platform Architecture
2. Executive summary
3. System context and core components
4. End-to-end message flow
5. IBM MQ topology and queue design
6. Retry, backout, DLQ, and replay model
7. Kubernetes and AWS deployment architecture
8. Cloud networking and security boundaries
9. Secrets and identity model: AWS Secrets Manager, IRSA, MQ OAM
10. Observability stack: logs, metrics, traces, dashboards, alerts
11. Resiliency scenarios and recovery behavior
12. Real incident: MQRC 2035 diagnosis and recovery
13. HA/DR design and production recommendations
14. Scaling and capacity planning
15. Performance bottlenecks and mitigations
16. Cost optimisation
17. Design trade-offs
18. Final assessment summary

Use diagrams and tables where possible.
Do not use marketing language.
Do not claim unimplemented features as already implemented; call them production recommendations.
```

## Gamma Prompt - Visual Style

```text
Use a professional enterprise architecture style:
- Dark text on light background
- Blue and green accents
- Simple AWS/Kubernetes/MQ visual language
- Boxes, arrows, and tables
- No decorative graphics
- No cartoon imagery
- Keep each slide readable for a technical review
```

## Manual Corrections Applied to AI Output

When using AI-generated architecture content, validate and correct the following:

| AI Output Risk | Manual Correction |
|---|---|
| Claims IBM MQ Native HA is implemented | Correct to: current assessment uses one MQ StatefulSet; Native HA is a production recommendation |
| Claims dashboard is fully authenticated | Correct to: expose only for demo; production should add authentication/RBAC |
| Claims KEDA is implemented | Correct to: HPA is implemented; KEDA queue-depth scaling is a recommendation |
| Claims all traffic uses TLS | Correct to: TLS is recommended for production; verify current ingress/service configuration |
| Claims multi-region DR is implemented | Correct to: backup/restore and cross-region DR are production recommendations |
| Omits MQRC 2035 incident | Add it as evidence of MQ operations and troubleshooting capability |
| Treats invalid messages as failures only | Correct to: invalid transactions are intentionally generated and persisted as `INVALID` |

