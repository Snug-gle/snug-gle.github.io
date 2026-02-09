---
created: 2025-01-17
updated: 2025-01-17
tags:
  - portfolio
  - nextjs
  - implementation
status: draft
---

# Next.js 포트폴리오 구현 가이드

## 프로젝트 구조

```
portfolio/
├── app/                           # Next.js 15 App Router
│   ├── page.tsx                   # 홈페이지
│   ├── layout.tsx                 # 전역 레이아웃
│   ├── projects/
│   │   ├── page.tsx               # 프로젝트 목록
│   │   └── [slug]/
│   │       └── page.tsx           # 프로젝트 상세
│   ├── learning/
│   │   ├── page.tsx               # 학습 노트 목록
│   │   └── [slug]/
│   │       └── page.tsx           # 학습 노트 상세
│   └── about/
│       └── page.tsx               # About Me
│
├── components/                    # React 컴포넌트
│   ├── home/
│   │   ├── HeroSection.tsx        # 히어로 섹션
│   │   ├── StatsSection.tsx       # 핵심 성과
│   │   └── FeaturedProjects.tsx   # 주요 프로젝트
│   ├── projects/
│   │   ├── ProjectCard.tsx        # 프로젝트 카드
│   │   ├── Timeline.tsx           # 인터랙티브 타임라인
│   │   └── BeforeAfter.tsx        # Before & After 슬라이더
│   └── ui/                        # shadcn/ui 컴포넌트
│       ├── button.tsx
│       ├── card.tsx
│       └── ...
│
├── content/                       # Obsidian 노트 (심볼릭 링크)
│   ├── projects/                  # 프로젝트 마크다운
│   │   ├── linkwave.mdx
│   │   ├── performance-tester.mdx
│   │   └── rally-point.mdx
│   └── learning/                  # 학습 노트 마크다운
│       ├── real-mysql.mdx
│       ├── spring-boot.mdx
│       └── react-19.mdx
│
├── lib/                           # 유틸리티
│   ├── contentlayer.ts            # Contentlayer 설정
│   └── utils.ts
│
├── public/                        # 정적 파일
│   ├── images/
│   └── resume.pdf
│
├── styles/
│   └── globals.css                # Tailwind CSS
│
├── contentlayer.config.ts         # Contentlayer 설정
├── next.config.js
├── package.json
└── tailwind.config.ts
```

---

## Step-by-Step 구현 가이드

### Step 1: 프로젝트 생성 (5분)

```bash
# Next.js 15 프로젝트 생성
npx create-next-app@latest portfolio \
  --typescript \
  --tailwind \
  --app \
  --no-src-dir \
  --import-alias "@/*"

cd portfolio

# 의존성 설치
npm install contentlayer next-contentlayer date-fns
npm install framer-motion lucide-react
npm install @radix-ui/react-slot class-variance-authority clsx tailwind-merge
```

---

### Step 2: Contentlayer 설정 (10분)

**`contentlayer.config.ts`**:

```typescript
import { defineDocumentType, makeSource } from 'contentlayer/source-files'

export const Project = defineDocumentType(() => ({
  name: 'Project',
  filePathPattern: `projects/**/*.mdx`,
  contentType: 'mdx',
  fields: {
    title: { type: 'string', required: true },
    description: { type: 'string', required: true },
    company: { type: 'string' },
    period: { type: 'string', required: true },
    role: { type: 'string', required: true },
    tags: { type: 'list', of: { type: 'string' } },
    featured: { type: 'boolean', default: false },
    order: { type: 'number', default: 0 },
    impact: {
      type: 'list',
      of: {
        type: 'nested',
        fields: {
          metric: { type: 'string', required: true },
          value: { type: 'string', required: true },
          description: { type: 'string' },
        },
      },
    },
    techStack: {
      type: 'nested',
      fields: {
        backend: { type: 'list', of: { type: 'string' } },
        frontend: { type: 'list', of: { type: 'string' } },
        devops: { type: 'list', of: { type: 'string' } },
      },
    },
  },
  computedFields: {
    slug: {
      type: 'string',
      resolve: (doc) => doc._raw.flattenedPath.replace('projects/', ''),
    },
    url: {
      type: 'string',
      resolve: (doc) => `/projects/${doc._raw.flattenedPath.replace('projects/', '')}`,
    },
  },
}))

export const Learning = defineDocumentType(() => ({
  name: 'Learning',
  filePathPattern: `learning/**/*.mdx`,
  contentType: 'mdx',
  fields: {
    title: { type: 'string', required: true },
    description: { type: 'string', required: true },
    date: { type: 'date', required: true },
    tags: { type: 'list', of: { type: 'string' } },
    relatedProjects: { type: 'list', of: { type: 'string' } },
  },
  computedFields: {
    slug: {
      type: 'string',
      resolve: (doc) => doc._raw.flattenedPath.replace('learning/', ''),
    },
    url: {
      type: 'string',
      resolve: (doc) => `/learning/${doc._raw.flattenedPath.replace('learning/', '')}`,
    },
  },
}))

export default makeSource({
  contentDirPath: 'content',
  documentTypes: [Project, Learning],
  mdx: {
    remarkPlugins: [],
    rehypePlugins: [],
  },
})
```

**`next.config.js`**:

```javascript
const { withContentlayer } = require('next-contentlayer')

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
}

module.exports = withContentlayer(nextConfig)
```

---

### Step 3: Obsidian 노트 연결 (5분)

```bash
# Obsidian vault를 content 폴더로 심볼릭 링크
mkdir -p content/projects
mkdir -p content/learning

# LinkWave 프로젝트
ln -s "/Users/sanghoon/Project/Obsidian Vaults/MyJourneyContinues/area/work/branch/iotree/LinkWave 프로젝트 개요.md" \
  content/projects/linkwave.mdx

# Performance Tester
ln -s "/Users/sanghoon/Project/Obsidian Vaults/MyJourneyContinues/project/active/Performance Tester 프로젝트 면접 준비.md" \
  content/projects/performance-tester.mdx

# Rally-Point
ln -s "/Users/sanghoon/Project/Obsidian Vaults/MyJourneyContinues/project/active/rally-point/architecture.md" \
  content/projects/rally-point.mdx

# 학습 노트
ln -s "/Users/sanghoon/Project/Obsidian Vaults/MyJourneyContinues/resource/book/RealMySQL 8.0" \
  content/learning/real-mysql
```

**또는 직접 MDX 파일 작성:**

**`content/projects/linkwave.mdx`**:

```mdx
---
title: "LinkWave - Multi-channel Messaging Platform"
description: "Hybrid Database Strategy와 JWT RS256 인증으로 성능과 보안을 모두 잡은 B2B SaaS 플랫폼"
company: "IoTree Inc."
period: "2024년 ~ 현재"
role: "Full-stack Developer"
tags: ["spring-boot", "react", "fullstack", "architecture"]
featured: true
order: 1
impact:
  - metric: "조회 성능 향상"
    value: "80%"
    description: "월별 파티션 테이블"
  - metric: "중복 메시지 차단"
    value: "99%"
    description: "DEDUP_HASH 시스템"
techStack:
  backend: ["Spring Boot 4.0", "Java 21", "JPA", "MyBatis", "MySQL 8.0"]
  frontend: ["React 19", "TanStack Router", "Tailwind CSS"]
  devops: ["GitLab CI/CD", "Docker", "Nginx"]
---

## 프로젝트 개요

B2B SaaS 멀티채널 메시징 플랫폼 (SMS/LMS/MMS)

## 문제 상황

### 데이터베이스 성능 문제

- User/Organization: CRUD 중심, 관계 복잡
- Message/Log: 대용량 쓰기 (일 10만+ 건)

모든 도메인을 JPA로?
→ Message 도메인에서 성능 이슈 발생

## 해결 과정

### Hybrid Database Strategy

...
```

---

### Step 4: 홈페이지 구현 (30분)

**`app/page.tsx`**:

```tsx
import { HeroSection } from '@/components/home/HeroSection'
import { StatsSection } from '@/components/home/StatsSection'
import { FeaturedProjects } from '@/components/home/FeaturedProjects'
import { allProjects } from 'contentlayer/generated'

export default function HomePage() {
  const featuredProjects = allProjects
    .filter((p) => p.featured)
    .sort((a, b) => a.order - b.order)

  return (
    <main>
      <HeroSection />
      <StatsSection />
      <FeaturedProjects projects={featuredProjects} />
    </main>
  )
}
```

**`components/home/HeroSection.tsx`**:

```tsx
'use client'

import { motion } from 'framer-motion'
import { ArrowRight } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center">
      {/* 배경 그라데이션 */}
      <div className="absolute inset-0 -z-10 bg-gradient-to-br from-primary/10 via-background to-secondary/10" />

      <div className="container px-4 mx-auto text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <h1 className="text-6xl md:text-8xl font-bold mb-6">
            안녕하세요, <br />
            <span className="text-primary">상훈</span>입니다
          </h1>

          <p className="text-2xl md:text-3xl text-muted-foreground mb-4">
            3년차 Full-stack Developer
          </p>

          <p className="text-xl md:text-2xl text-muted-foreground mb-12 italic">
            "측정하고, 개선하고, 문서화하는 개발자"
          </p>

          <div className="flex gap-4 justify-center">
            <Link href="/projects">
              <Button size="lg" className="text-lg">
                프로젝트 보기
                <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            </Link>
            <Link href="#contact">
              <Button size="lg" variant="outline" className="text-lg">
                연락하기
              </Button>
            </Link>
          </div>
        </motion.div>

        {/* 스크롤 다운 애니메이션 */}
        <motion.div
          className="absolute bottom-8 left-1/2 -translate-x-1/2"
          animate={{ y: [0, 10, 0] }}
          transition={{ repeat: Infinity, duration: 1.5 }}
        >
          <div className="w-6 h-10 border-2 border-primary rounded-full flex justify-center">
            <div className="w-1 h-3 bg-primary rounded-full mt-2" />
          </div>
        </motion.div>
      </div>
    </section>
  )
}
```

**`components/home/StatsSection.tsx`**:

```tsx
'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'

const stats = [
  { number: '90%', label: '렌더링 시간 단축', description: 'Performance Tester' },
  { number: '80%', label: '조회 성능 향상', description: 'LinkWave' },
  { number: '6+', label: '기술 서적 학습', description: 'Real MySQL, Spring 등' },
  { number: '3개', label: '회사 프로젝트', description: 'Full-stack 경험' },
]

export function StatsSection() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })

  return (
    <section ref={ref} className="py-20 bg-muted/50">
      <div className="container px-4 mx-auto">
        <motion.h2
          className="text-4xl md:text-5xl font-bold text-center mb-16"
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
        >
          숫자로 말하는 성과
        </motion.h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {stats.map((stat, index) => (
            <motion.div
              key={stat.label}
              className="text-center p-6 rounded-xl bg-card border"
              initial={{ opacity: 0, y: 20 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: index * 0.1 }}
            >
              <div className="text-5xl md:text-6xl font-bold text-primary mb-2">
                {stat.number}
              </div>
              <div className="text-xl font-semibold mb-1">{stat.label}</div>
              <div className="text-sm text-muted-foreground">{stat.description}</div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

---

### Step 5: 인터랙티브 타임라인 (1시간)

**`components/projects/Timeline.tsx`**:

```tsx
'use client'

import { motion, useInView } from 'framer-motion'
import { useRef, useState } from 'react'
import { Project } from 'contentlayer/generated'
import { ProjectCard } from './ProjectCard'

export function Timeline({ projects }: { projects: Project[] }) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-100px' })

  return (
    <div ref={ref} className="relative max-w-5xl mx-auto">
      {/* 타임라인 선 */}
      <motion.div
        className="absolute left-8 top-0 bottom-0 w-0.5 bg-primary"
        initial={{ scaleY: 0 }}
        animate={isInView ? { scaleY: 1 } : {}}
        transition={{ duration: 1 }}
        style={{ transformOrigin: 'top' }}
      />

      {/* 프로젝트 목록 */}
      {projects.map((project, index) => (
        <TimelineItem key={project._id} project={project} index={index} />
      ))}
    </div>
  )
}

function TimelineItem({ project, index }: { project: Project; index: number }) {
  const [isHovered, setIsHovered] = useState(false)
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-100px' })

  return (
    <motion.div
      ref={ref}
      className="relative mb-16 ml-16"
      initial={{ opacity: 0, x: -50 }}
      animate={isInView ? { opacity: 1, x: 0 } : {}}
      transition={{ delay: index * 0.2 }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* 타임라인 점 */}
      <motion.div
        className="absolute -left-10 top-6 w-4 h-4 rounded-full bg-primary border-4 border-background"
        animate={{
          scale: isHovered ? 1.5 : 1,
          boxShadow: isHovered ? '0 0 0 8px rgba(var(--primary), 0.2)' : 'none',
        }}
      />

      {/* 프로젝트 카드 */}
      <ProjectCard project={project} isHovered={isHovered} />
    </motion.div>
  )
}
```

**`components/projects/ProjectCard.tsx`**:

```tsx
'use client'

import { motion } from 'framer-motion'
import Link from 'next/link'
import { Project } from 'contentlayer/generated'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ArrowRight, Briefcase, Calendar } from 'lucide-react'

export function ProjectCard({
  project,
  isHovered,
}: {
  project: Project
  isHovered: boolean
}) {
  return (
    <motion.div
      className="border rounded-xl p-6 bg-card hover:shadow-lg transition-shadow"
      whileHover={{ scale: 1.02 }}
    >
      {/* 헤더 */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-2xl font-bold mb-2">{project.title}</h3>
          <p className="text-muted-foreground">{project.description}</p>
        </div>
        {project.company && (
          <Badge variant="secondary" className="ml-4">
            {project.company}
          </Badge>
        )}
      </div>

      {/* 메타 정보 */}
      <div className="flex gap-4 mb-4 text-sm text-muted-foreground">
        <div className="flex items-center gap-1">
          <Calendar className="w-4 h-4" />
          {project.period}
        </div>
        <div className="flex items-center gap-1">
          <Briefcase className="w-4 h-4" />
          {project.role}
        </div>
      </div>

      {/* 성과 지표 (호버 시 표시) */}
      {isHovered && project.impact && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          className="grid grid-cols-2 gap-4 mb-4 p-4 bg-muted/50 rounded-lg"
        >
          {project.impact.map((item) => (
            <div key={item.metric} className="text-center">
              <div className="text-3xl font-bold text-primary">{item.value}</div>
              <div className="text-sm font-semibold">{item.metric}</div>
              {item.description && (
                <div className="text-xs text-muted-foreground">{item.description}</div>
              )}
            </div>
          ))}
        </motion.div>
      )}

      {/* 태그 */}
      {project.tags && (
        <div className="flex flex-wrap gap-2 mb-4">
          {project.tags.map((tag) => (
            <Badge key={tag} variant="outline">
              {tag}
            </Badge>
          ))}
        </div>
      )}

      {/* CTA */}
      <div className="flex gap-4">
        <Link href={project.url}>
          <Button>
            프로젝트 상세
            <ArrowRight className="ml-2 h-4 w-4" />
          </Button>
        </Link>
        <Link href={`/learning?project=${project.slug}`}>
          <Button variant="outline">학습 노트</Button>
        </Link>
      </div>
    </motion.div>
  )
}
```

---

### Step 6: 배포 (Vercel) (10분)

```bash
# GitHub 저장소 생성 및 푸시
git init
git add .
git commit -m "feat: 초기 포트폴리오 구축"
git branch -M main
git remote add origin https://github.com/yourname/portfolio.git
git push -u origin main

# Vercel에서 배포
# 1. https://vercel.com 접속
# 2. "Import Project" 클릭
# 3. GitHub 저장소 선택
# 4. "Deploy" 클릭

# 5분 후 확인:
# https://portfolio-yourname.vercel.app
```

---

## 완성된 기능

### ✅ 홈페이지
- Hero Section (히어로 섹션)
- Stats Section (핵심 성과)
- Featured Projects (주요 프로젝트 3개)

### ✅ 프로젝트 페이지
- 인터랙티브 타임라인
- 호버 시 성과 지표 표시
- Before & After 슬라이더
- 프로젝트 ↔ 학습 노트 연결

### ✅ 학습 노트 페이지
- MDX 렌더링
- 프로젝트 연결
- 태그 필터링

### ✅ 반응형 디자인
- 모바일, 태블릿, 데스크톱

---

## 다음 단계

### 추가 기능
- [ ] 다크 모드
- [ ] 검색 기능
- [ ] OG 이미지 생성
- [ ] Google Analytics
- [ ] SEO 최적화

---

**작성일**: 2025-01-17
**상태**: 구현 가이드
**예상 소요 시간**: 3-4시간
