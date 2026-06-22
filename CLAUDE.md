
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

## Coding and testing

- Always use automated tools to verify the correctness of code, like linters and validators
- Always identify and write automated tests that define what "correct" looks like for required behavior
- Use playwright to test web applications; do not rely only on vite unit tests because even though these are useful the are not sufficient on their own, you need to verify functionality of web apps using playwright.
- Use other means to check the code works, like the browser
- Always review the code and check complexity that needs to be simplified

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
