---
created: 2025-11-28
---
# GEMINI.md

This file provides guidance to Gemini when working with this repository.

## Repository Overview

This is an Obsidian vault for personal knowledge management using the PARA method (Projects, Areas, Resources, Archive). The vault contains technical notes, study materials, and project documentation primarily focused on software development.

## Organizational Structure

The vault follows the PARA methodology:

- **project/**: Active and pending projects with specific goals and deadlines
  - `active/`: Currently active projects (framework studies, side projects, rally-point)
  - `inbox/`: Quick capture notes and ideas awaiting organization
  - `pending/`: Projects on hold

- **area/**: Ongoing responsibilities and long-term interests
  - `career/`: Career development and professional growth
  - `log/`: Daily logs and meeting notes
  - `work/`: Work-related documentation (branch-specific work like mafra)
  - `private/`: Personal files

- **resource/**: Reference materials and learning content
  - `book/`: Book notes (Java, MySQL, algorithms, LLM, etc.)
  - `lecture/`: Course notes (Spring, CS fundamentals, Java practice)
  - `daily/`: Technical daily notes and discoveries
  - `files/`: Attachments and supporting files

- **archive/**: Completed or inactive items
  - `templates/`: Note templates

## Obsidian Configuration

Key settings from `.obsidian/app.json`:
- New files are created in `area/log/` by default
- Attachments are stored in `resource/files/`
- Line numbers are enabled for code blocks
- System trash is used (not Obsidian's `.trash/`)

## Content Focus

The vault primarily covers:
- **Java ecosystem**: Spring Framework, JPA, Java fundamentals
- **Database**: MySQL (RealMySQL 8.0 study notes), JPA mappings
- **Algorithms & Data Structures**: Sorting, problem-solving with mathematics
- **Web Development**: Vue.js, React (mentioned in project context)
- **LLM/AI**: LLM applications, transformers, embeddings, RAG systems
- **Software Engineering**: TDD, ORM, architecture patterns

## Working with This Vault

### File Naming Conventions
- Date-based files use `YYYY-MM-DD` format
- Topic files use descriptive names in Korean or English
- Inbox files may use various naming patterns as they await organization

### Cross-references
Many notes use Obsidian's wiki-link format `[[Note Name]]` for internal linking. When reading or modifying content, preserve these links.

### Git Workflow
The vault is version-controlled. Recent commits show frequent "vault backup" commits, indicating automatic or manual backups are common.
