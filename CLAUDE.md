
## Project Structure

### Always read this

- `spec-and-architecture.md` is the most credible source of information on what the shape of the system should be like.

### Read when needed only

- `spec-detail.md` contains additional clarifications but in the case of any conflict, `./spec-and-architecture.md` wins
- `milestones.md` contains the milestones breakdown as input for implementation iterations planning

### Applications

- `knevo-backend/` is the backend application
- `knevo-web/` is the web application
- `KnevoPatient/` is the mobile iOS application

## UI Design

- User facing errors should be user friendly error, not technical errors.

## Integrations

- For integrations between systems/subsystems/containers/applications, design and create an API contract/schema first, then use that API contract/schema while implementing the client/server/peer sides of the integration.
    - This must include end points, data structures, data types, what is required and what is optional, and any significant semantics as well.
    - This must include operational aspects like authentication, authorization, and latency requirements.

## Coding and testing

- Always use automated tools to verify the correctness of code, like linters and validators
- Always identify and write automated tests that define what "correct" looks like for required behavior
- Use playwright to test web applications; do not rely only on vite unit tests because even though these are useful the are not sufficient on their own, you need to verify functionality of web apps using playwright.
- Use other means to check the code works, like the browser
- Always review the code and check complexity that needs to be simplified
- When there is frontend and backend, or a mobile app and a backend, you must create some end to end integration tests to verify integration.
- Use pepper to perform testing of mobile iOS applications inside the simulator

## Diagrams

- Always use code to create and draw diagrams (code to diagrams).
- Use C4 diagrams for visualizing software architecture. Specifically: Context diagram(s), and Container Diagrams.
- Diagrams flow from top to bottom, and from left to right.
- C4 diagrams need to contain concrete information. High level doesn't mean vague. Arrows must indicate what is being requested or transferred and what the protocol is. Containers in container diagrams must indicate technology and role of the container in the system design.
- Use PlantUML for creating diagrams C4 diagrams. Use Structurizr for more advanced modeling of software architecture.
- Use mermaid for other types of diagrams that are well supported by mermaid.

## Tech Stack Decisions

- Use gradle with kotlin DSL for the build of Java projects
- Use Spring Boot and Java for the Backend
- Use react for the frontend, with tailwindcss
- Use PostgreSQL for the database
- Use Swift and SwiftUI for the iOS mobile app. Support iOS version 18 and 26 (18+)

## Architecture

- Follow existing architectural patterns and conventions.
- Avoid introducing new frameworks, abstractions, or dependencies unless they provide clear value and are consistent with the existing codebase.
- Prefer simple solutions over clever ones.
- Minimize scope and avoid unrelated refactoring.

## Decision Making

When multiple implementation options exist:

- Choose the simplest solution that satisfies the requirements. It still needs to be a real solution though, fake solutions don't count.
- Prefer existing project patterns over introducing new ones.
- Explain significant architectural decisions before making them.

<!-- graymatter:instructions:begin — managed by `graymatter init`; edits inside this block are overwritten -->
## Memory (GrayMatter)

This project has persistent agent memory via the `graymatter` MCP tools:

- `memory_search` (`agent_id`, `query`) — call at the **start of a task** when prior context might matter.
- `memory_add` (`agent_id`, `text`) — call whenever you learn something **durable**: user preferences, decisions, conventions, gotchas.
- `memory_reflect` (`action`, `agent`, `text`/`target`) — update or forget stale facts. ⚠ takes `agent`, not `agent_id`.
- `checkpoint_save` / `checkpoint_resume` (`agent_id`) — snapshot/restore session state before major refactors or across restarts.

Use a stable `agent_id` of the form `<project>-<role>` (e.g. `myapp-backend`). Store conclusions, not conversation logs. Err on the side of remembering.
<!-- graymatter:instructions:end -->
