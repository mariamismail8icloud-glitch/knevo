- Always use code to create and draw diagrams (code to diagrams).
- Use C4 diagrams for visualizing software architecture. Specifically: Context diagram(s), and Container Diagrams.
- Diagrams flow from top to bottom, and from left to right.
- C4 diagrams need to contain concrete information. High level doesn't mean vague. Arrows must indicate what is being requested or transferred and what the protocol is. Containers in container diagrams must indicate technology and role of the container in the system design.
- Use PlantUML for creating diagrams C4 diagrams. Use Structurizr for more advanced modeling of software architecture.
- Use mermaid for other types of diagrams that are well supported by mermaid.

## Decisions

- Use gradle with kotlin DSL for the build of Java projects
- Use Spring Boot and Java for the Backend
- Use react for the frontend, with tailwindcss
- Use PostgreSQL for the database
- Use Swift and SwiftUI for the iOS mobile app
