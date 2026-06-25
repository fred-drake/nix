# Code Architect Technical Planning

## OBJECTIVE
Analyze a Gitea issue thread and produce a comprehensive technical implementation plan broken into executable phases.

## Initial Setup

### Parse Arguments
```
ISSUE_NUMBER = #$ARGUMENTS  # The Gitea issue number to analyze
```

### Required Tools
- `code-architect` sub-agent: For technical analysis and planning
- `gitea-code-architect` MCP server: For fetching issue data

## Phase 1: Issue Analysis

### 1. Fetch Complete Issue Thread
Using `gitea-code-architect` MCP server, retrieve:
- Original issue description
- ALL comments in chronological order
- Issue metadata (labels, milestone, assignees)
- Any linked issues or pull requests

### 2. Stakeholder Identification
Identify and categorize participants:
- **Product Owner**: Original requirements and clarifications
- **Engineers**: Technical concerns and feasibility discussions
- **Users**: Feature requests and use case descriptions
- **Other Stakeholders**: QA, DevOps, Security considerations

### 3. Requirement Extraction
Extract and categorize all requirements:
- **Functional Requirements**: What the system must do
- **Non-Functional Requirements**: Performance, security, scalability
- **Constraints**: Technical limitations, dependencies, deadlines
- **Acceptance Criteria**: How to verify completion

## Phase 2: Deep Technical Analysis ("Ultrathinking")

The `code-architect` must perform comprehensive ultrathinking before creating the plan:

### 1. Problem Space Analysis
- **Root Cause Identification**: Go beyond symptoms to underlying issues
- **System-Wide Impact**: Trace effects across all system components
- **Hidden Complexity**: Uncover non-obvious technical challenges
- **Assumption Validation**: Challenge implicit assumptions in requirements

### 2. Solution Space Exploration
- **Architecture Patterns**: Evaluate multiple architectural approaches
  - Microservices vs. monolithic considerations
  - Event-driven vs. request-response patterns
  - Synchronous vs. asynchronous processing
- **Technology Deep Dive**:
  - Research latest best practices
  - Evaluate emerging technologies
  - Consider deprecation timelines
  - Assess community support and ecosystem

### 3. Future-Proofing Analysis
- **Scalability Projections**: Model growth scenarios
- **Extensibility Planning**: Design for unknown future requirements
- **Technical Debt Assessment**: Conscious debt decisions
- **Migration Pathways**: Plan for technology evolution

### 4. Cross-Functional Implications
- **DevOps Considerations**: Deployment, monitoring, maintenance
- **Security Architecture**: Threat modeling and mitigation
- **Data Architecture**: Storage, access patterns, consistency
- **Performance Engineering**: Latency, throughput, resource usage

### 5. Decision Tree Construction
Create decision trees for critical choices:
```
If [condition A] → Use Pattern X because [reasoning]
  If [sub-condition A1] → Modify with Y
  If [sub-condition A2] → Add component Z
Else → Use Pattern Q because [reasoning]
```

### 6. Risk Mitigation Strategies
For each identified risk:
- **Probability Assessment**: Likelihood of occurrence
- **Impact Analysis**: Consequences if realized
- **Mitigation Approaches**: Preventive and reactive measures
- **Monitoring Strategy**: How to detect early warning signs

### 7. Implementation Complexity Mapping
- **Complexity Hotspots**: Areas requiring senior expertise
- **Parallelization Opportunities**: What can be built concurrently
- **Learning Curves**: New technologies/patterns team must learn
- **Integration Challenges**: Third-party or legacy system touchpoints

## Phase 3: Technical Plan Creation

### Structure for Technical Plan

```markdown
# Technical Implementation Plan for Issue #[NUMBER]

## Executive Summary
[2-3 sentence overview of the solution approach]

## Problem Analysis
### Core Requirements
- [Extracted from issue thread]

### Technical Constraints
- [Identified limitations]

### Success Criteria
- [Measurable outcomes]

## Proposed Solution

### Architecture Overview
[High-level description of the solution architecture]

### Ultrathinking Insights
**Key Discoveries from Deep Analysis:**
- [Non-obvious implications discovered]
- [Hidden dependencies identified]
- [Performance considerations uncovered]
- [Security vulnerabilities anticipated]

**Critical Decisions Made:**
- Chose [Pattern A] over [Pattern B] because [reasoning from ultrathinking]
- Prioritized [Aspect X] due to [deep analysis finding]
- Deferred [Feature Y] based on [complexity analysis]

### Technology Stack
- **Languages**: [Required programming languages]
- **Frameworks**: [Necessary frameworks]
- **Dependencies**: [External libraries/services]
- **Infrastructure**: [Deployment requirements]

## Implementation Phases

### Phase 1: Foundation
**Objective**: [What this phase accomplishes]
**Components**:
- [ ] Component A: [Description and purpose]
- [ ] Component B: [Description and purpose]
**Testing Strategy**: [How to verify this phase]
**Deliverables**: [What will be complete after this phase]

### Phase 2: Core Functionality
**Objective**: [What this phase accomplishes]
**Components**:
- [ ] Feature X: [Description and implementation approach]
- [ ] Feature Y: [Description and implementation approach]
**Dependencies**: [What must be complete from Phase 1]
**Testing Strategy**: [How to verify this phase]
**Deliverables**: [What will be complete after this phase]

### Phase 3: Integration & Polish
**Objective**: [Final integration and refinements]
**Components**:
- [ ] Integration points
- [ ] Error handling
- [ ] Performance optimization
**Testing Strategy**: [End-to-end testing approach]
**Deliverables**: [Final deliverable description]

## Technical Considerations

### Security
- [Security measures to implement]
- [Authentication/authorization approach]

### Performance
- [Expected performance characteristics]
- [Optimization strategies]

### Scalability
- [How the solution scales]
- [Future growth considerations]

### Maintenance
- [Documentation requirements]
- [Monitoring and logging approach]
- [Update/upgrade strategy]

## Risk Mitigation
| Risk | Impact | Mitigation Strategy |
|------|--------|-------------------|
| [Risk 1] | [High/Medium/Low] | [How to address] |
| [Risk 2] | [High/Medium/Low] | [How to address] |

## Open Questions
- [ ] [Questions requiring product owner clarification]
- [ ] [Technical decisions needing team input]

## Next Steps
1. Review and approval of this technical plan
2. Assign phase ownership to team members
3. Set up development environment
4. Begin Phase 1 implementation
```

## Phase 4: Plan Delivery

### 1. Format as Gitea Comment
Structure the response as a direct reply to the issue:
- Use proper Markdown formatting
- Include checkboxes for trackable tasks
- Reference specific comments when addressing concerns
- @mention relevant stakeholders for visibility

### 2. Quality Checks
Before posting, ensure the plan:
- Addresses ALL requirements from the issue thread
- Provides clear, actionable phases
- Includes testing strategy for each phase
- Considers all stakeholder concerns raised
- Is technically sound and feasible

### 3. Plan Characteristics
The technical plan should be:
- **Comprehensive**: Covers all aspects of the implementation
- **Phased**: Broken into logical, manageable chunks
- **Testable**: Each phase has clear verification criteria
- **Flexible**: Allows for iteration based on feedback
- **Clear**: Understandable by both technical and non-technical stakeholders

## Example Execution

```
Fetching issue #42 from Gitea...
Retrieved 15 comments from 5 participants
Analyzing requirements and technical discussions...

Identified:
- 3 functional requirements
- 2 non-functional requirements
- 1 major technical constraint
- 4 acceptance criteria

Performing deep technical analysis...
Evaluating 3 potential architectures...
Assessing risks and trade-offs...

Generating phased technical plan...
Formatting for Gitea comment...
Plan ready for review and posting.
```

## Important Notes

- **No Timelines**: As specified, do not include dates, deadlines, or time estimates
- **Phase Dependencies**: Clearly indicate which phases depend on others
- **Iterative Approach**: Plan should accommodate feedback and changes
- **Technical Focus**: While accessible, the plan should be technically thorough
- **Direct Response**: The output is formatted as a direct issue comment, not a separate document
