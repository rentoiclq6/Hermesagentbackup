---
name: career-transition-planning
title: Career Transition Planning
description: Full methodology for industry/role career transition — resume parsing, skill transfer mapping, dual-track strategy, tiered company recommendations, skill gap analysis, and timeline planning.
triggers:
  - "帮我看一下我的背景，推荐公司"
  - "我想从X行业转到Y行业，怎么做"
  - "根据我的简历给我规划一下求职方向"
  - "帮我分析我的技能能做什么岗位"
  - "职业规划 / 转行 / 跳槽建议"
  - Any request for career advice, job search planning, company recommendations based on user background
---

# Career Transition Planning Methodology

## Overview

When a user asks for career planning / job search strategy / industry transition advice, follow this structured methodology. It produces a **dual-track strategy** — the aspirational target + a safety net — rather than a single list.

## Step 1: Read User Background

- Read the user's resume/document from the path they provide
- Extract: education, years of experience, domain expertise, specific skills, project highlights, awards
- **Important**: When the user gives a Windows path like `F:\找工作\document.md`, first mount all /mnt/ drives and check which one has the file. Don't assume only C: and D: exist — external drives can be any letter. Use `ls /mnt/[a-z]/` to discover available mount points.

## Step 2: Skill Transfer Mapping (Critical)

Create a table mapping the user's EXISTING skills to the TARGET industry:

| User Skill | Target Industry Equivalent | Gap |
|-----------|--------------------------|-----|
| ... | ... | direct / minor gap / needs retooling |

This is the foundation for everything else. Be honest about gaps — the user will respect accurate assessment more than optimism.

## Step 3: Research Target Industry Companies

Organize into **3 tiers** based on skill match + career potential:

- **Tier 1 (Primary Target)**: High match + good career trajectory — companies the user should invest most effort into
- **Tier 2 (Alternative)**: Good match but slightly lower salary/role fit — still worth pursuing
- **Tier 3 (Fallback)**: Lower match, good for getting a foot in the door

For each company include:
- Company name, city, primary product/direction
- Matching job titles
- Estimated salary range (use public info or reasonable estimates; mark as `[SPECULATIVE]`)
- Why the user's background is relevant

## Step 4: Dual-Track Strategy

Split into two parallel tracks with an **effort allocation**:

| Track | % Effort | Objective | Target Companies |
|-------|---------|-----------|-----------------|
| 🚀 Aspirational (target industry) | 70% | Direct transition | Tier 1-2 companies |
| 🛡️ Safety Net (current industry) | 30% | Fallback / skill build | Top 3-5 current-industry companies |

Include a **tiered recommendation** for the safety net:
- **Preferred**: High-skill-match companies in current industry (do first)
- **Fallback**: Lower-match but available roles (last resort)

## Step 5: Skill Gap Analysis & Learning Path

Identify 3-5 concrete gaps. For each:

| Priority | Skill | Learning Method | Time Estimate | Target Level |
|----------|-------|----------------|--------------|------------|
| ⭐⭐⭐ | ... | resource / project | X weeks | concrete outcome |

Include specific tools/courses/projects. A portfolio project (e.g. GitHub repo) is worth more than a course certificate.

## Step 6: Resume & Interview Adjustments

Tailored advice:
- Keywords to add/change for the target industry
- Which projects to emphasize
- How to reframe experience (e.g. "VCU" → "embedded control system")
- Interview prep focus areas

## Step 6b: Generate Visual Skill Map (Optional, High-Value)

For complex industry transitions, generate a **standalone HTML visualization** alongside the markdown output:

**When to do this**: The user's background has 15+ skills to map, or the gap analysis is nuanced enough that a table alone doesn't communicate the overlap clearly.

**What to include in the HTML**:
1. **Venn Diagram** — 3 zones: "My existing skills" (left), "Target industry needs" (right), "Overlap" (center, yellow). Annotate overlap count and gap count.
2. **Detailed comparison table** — One row per skill with columns: Skill | Current Level | Industry Requirement | Gap Assessment | Priority
3. **Radar chart** — Circle gauges comparing current level vs. requirement for 6-9 key skills. Use `lvl-0` through `lvl-5` CSS classes on ring divs.
4. **Learning path table** — All gaps sorted by priority (P0-P3), with time estimates and concrete success criteria.
5. **Resume keyword rewriting table** — Original VCU/industry term → target industry equivalent.

**Output format**: Single self-contained HTML file, dark theme (`#0f172a` background), no JavaScript dependencies. Save to a path the user can open in a browser (Desktop is a good default).

**Integration**: After generating the visual, append a text-based version of the key tables to the same markdown file the company lists are written to, so everything stays in one place.

## Step 7: Timeline

```
Now ──────────────→ 3 months ──────────→ 6 months ─────→ 1 year
 │                   │                   │              │
 ├─ Apply + learn    ├─ Re-assess        ├─ Target hit   │
 ├─ Fill gaps        ├─ First offers     │  or pivot     │
 └─ Projects         └─ Adjust timeline  └─ Safety net   │
                                                    Target role
```

## Pitfalls

- **Mount point discovery — do NOT guess**: When the user gives a Windows path like `F:\找工作\file.md`, the FIRST action is `ls /mnt/` to see ALL available mount points. Do NOT try C: or D: first. Do NOT search incrementally. The user gets frustrated if you repeatedly fail to find their file. Immediately list ALL mounts and pick the matching drive letter.
- **If the drive letter doesn't match any /mnt/ mount**: Check if the mount might use a different case (e.g. `/mnt/f` vs `/mnt/F`) or if the drive needs to be mounted manually (`sudo mount -t drvfs F: /mnt/f`). Fall back to `find /mnt/ -maxdepth 3 -name "*.md" -path "*找*" 2>/dev/null` only after mount discovery fails.
- **Don't retry without reporting**: After the first failed file read, stop and output `[STATUS]` with what was tried and the full `ls /mnt/` output so the user can correct you.
- **Don't give a single list**: Always provide a dual-track structure (aspirational + safety net).
- **Don't be overly optimistic about gap closing**: Time estimates should be realistic. ROS2 in 2 weeks is plausible; C++ mastery in 2 weeks is not.
- **Don't ignore salary**: Users care about compensation. Include estimated ranges even if speculative, and mark them as [SPECULATIVE].
- **Don't recommend companies without location**: City matters for job decisions.
- **Don't skip the skill mapping table**: It's the most important part — it justifies WHY the transition is feasible.

## Verification Checklist

- [ ] Resume parsed and key data extracted
- [ ] Skill transfer mapping complete
- [ ] 3-tier target industry companies listed with cities and salaries
- [ ] Dual-track strategy with % effort allocation
- [ ] Skill gap analysis with time estimates and resources
- [ ] Resume adjustment recommendations
- [ ] Timeline diagram
- [ ] File written to user-specified path (if applicable)

## Reference Files

- `references/vcu-to-robotics.md` — Example: full VCU→Robotics transition case study from this session
