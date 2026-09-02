# ACE-FCA + retrospectives extension

## Why retrospectives matter

The Advanced Context Engineering for Coding Agents (ACE-FCA) methodology gives us a powerful framework: Research → Plan → Implement. But it's missing something crucial: **learning from what actually happened**.

Without retrospectives, we repeat the same mistakes, miss improvement opportunities, and fail to capture the nuanced insights that make human-AI collaboration truly effective.

## What we're adding

We're extending ACE-FCA with a fourth phase: **Retrospective**.

```
Research → Plan → Implement → Retrospective
           ↓         ↓           ↑
    Create retro  Update retro  Complete retro
```

## How it works

### During planning

When you create a plan, a corresponding retrospective document is automatically created in `.github/ace-fca/retros/` with the same filename. This retrospective starts empty but ready to capture insights as they emerge.

### During implementation
Use trigger phrases to add insights in real-time:
- "Add this to the retro: the authentication approach worked better than expected"
- "Retrospective note: should have started with the simpler endpoint first"
- "For the retrospective: the Terraform provider download issue cost us 2 hours"

The agent will automatically update the retrospective document as you work.

### After completion
Complete the retrospective with:
- **Technical feedback**: What worked, what didn't, what's missing
- **Process insights**: How to improve human-AI collaboration
- **Creative icebreakers**: Fun elements that encourage engagement

## Whimsy

- "What kind of animal am I based on this project?"
- "If this conversation were a painting, what would it look like?"
- "What D&D class best represents my approach here?"

## Why this extends ACE-FCA

ACE-FCA's core insight is that **context management is everything**. Retrospectives extend this by managing **learning context** across projects:

- **Research quality improves** when you remember what research approaches worked before
- **Planning gets sharper** when you know your blind spots from previous plans
- **Implementation flows better** when you've learned from past execution challenges
- **Human leverage increases** when both human and agent learn from each interaction

The goal isn't perfect retrospectives. The goal is building a learning system where each project makes the next one better.