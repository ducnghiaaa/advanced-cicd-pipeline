# advanced-cicd-pipeline

![alt text](images/architecture_flow.gif)

# Architecture

![alt text](images/architecture.png)

# CICD Workflow

![alt text](images/cicd_workflow.png)

# Known security debt

The Trivy stages currently run in **report-only mode** (`--exit-code 0`).

This is intentional: the sample application inherited from
`DevOps-Project-06` pins `spring-boot-starter-parent` 2.2.0.RELEASE (Oct 2019)
plus `twitter4j-core` 3.0.6 and `github-api` 1.99. Trivy surfaces ~67 HIGH /
CRITICAL CVEs against this stack, including well-known RCEs:

- **CVE-2022-22965** *Spring4Shell* — Spring RCE via data binding on JDK 9+
- **CVE-2020-1938** *Ghostcat* — Tomcat AJP file read → RCE
- **CVE-2020-9484** / **CVE-2021-25329** — Tomcat session persistence RCE
- **CVE-2024-50379** / **CVE-2024-56337** — Tomcat JSP TOCTOU RCE
- Multiple `jackson-databind` deserialization RCEs
- Multiple `spring-beans` data binding vulnerabilities

**Rationale for shipping report-only first:** every build now logs the full
CVE list so drift is visible immediately. We chose to prove the pipeline
end-to-end before tightening the gate rather than paper over the truth with
a wildcard `.trivyignore`. Visibility is the first shift-left step;
enforcement follows once dependencies are on a supportable baseline.

**Planned remediation** (Phase 4 finalization):

1. Bump `spring-boot-starter-parent` to 2.7.18 (last 2.x LTS) — same major,
   drops Spring4Shell + Ghostcat + most Tomcat/jackson CVEs without a code
   rewrite.
2. Replace `twitter4j-core` and `github-api` (both unmaintained) with
   current alternatives, or drop the demo endpoints that use them.
3. Pin the base image by digest (`eclipse-temurin:21.0.5_11-jre-noble@sha256:…`).
4. Switch Trivy `fs` and `image` stages back to `--exit-code 1`.
5. Track any residual, non-actionable findings in `.trivyignore` with a
   one-line justification per entry.