# Phase BE-19: Task Assignment & Workflow

## Phase Metadata

- **Phase ID**: BE-19
- **Phase Name**: Task Assignment & Workflow
- **Section**: Backend Execution — Operations Layer
- **Depends On**: BE-01 to BE-18
- **Blocks**: BE-20 (reports use task data), BE-24 (notifications)
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium

## Goal

Build task management system: task creation by managers, assignment to staff, status workflow (pending → in_progress → completed), evidence requirements (photos, scans), due dates with overdue tracking, recurring tasks, task templates, and integration with expiry alerts (auto-create tasks).

## Why This Phase Matters

Tasks operationalize the platform:
- Manager assigns "Check Aisle 3 expiries" → Staff member completes
- Auto-task: "Remove 50 expired items in dairy section"
- Evidence: Staff scans completed items as proof
- Compliance: Audit trail of "who did what when"
- Workflow: Daily/weekly recurring tasks

Without tasks:
- No way to assign work to staff
- Manual coordination via WhatsApp
- No accountability
- No evidence of completion

## Prerequisites

- [ ] BE-01 to BE-18 completed
- [ ] User management (BE-09)
- [ ] Scan recording (BE-16)
- [ ] Expiry alerts (BE-18)

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/tasks.ts` | Tasks table |
| `server/src/db/schema/task_assignments.ts` | Multi-assignee support |
| `server/src/db/schema/task_events.ts` | Audit trail |
| `server/src/db/schema/task_evidence.ts` | Evidence (photos/scans) |
| `server/src/db/schema/task_templates.ts` | Reusable templates |
| `server/src/modules/tasks/tasks.module.ts` | Module |
| `server/src/modules/tasks/tasks.controller.ts` | Endpoints |
| `server/src/modules/tasks/tasks.service.ts` | Business logic |
| `server/src/modules/tasks/services/task-assignment.service.ts` | Assignment |
| `server/src/modules/tasks/services/task-workflow.service.ts` | State machine |
| `server/src/modules/tasks/services/task-evidence.service.ts` | Evidence handling |
| `server/src/modules/tasks/services/task-templates.service.ts` | Templates |
| `server/src/modules/tasks/services/recurring-tasks.service.ts` | Recurring logic |
| `server/src/modules/tasks/services/auto-task-generator.service.ts` | Auto from alerts |
| `server/src/modules/tasks/repositories/tasks.repository.ts` | Tasks data |
| `server/src/modules/tasks/repositories/task-assignments.repository.ts` | Assignments |
| `server/src/modules/tasks/repositories/task-events.repository.ts` | Events |
| `server/src/modules/tasks/dto/create-task.dto.ts` | DTOs |
| `server/src/modules/tasks/dto/update-task.dto.ts` | DTOs |
| `server/src/modules/tasks/dto/list-tasks.dto.ts` | DTOs |
| `server/src/modules/tasks/types/task.types.ts` | Types |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/tasks/tasks.service.ts

export interface ITasksService {
  // CRUD
  create(dto: CreateTaskDto, createdBy: string): Promise<Task>;
  findById(id: string): Promise<TaskWithDetails | null>;
  update(id: string, dto: UpdateTaskDto, userId: string): Promise<Task>;
  delete(id: string, userId: string): Promise<void>;
  
  // Listing
  listForUser(userId: string, filters: ListTasksFilter): Promise<PaginatedResult<Task>>;
  listForStore(storeId: string, filters: ListTasksFilter): Promise<PaginatedResult<Task>>;
  
  // Workflow
  start(id: string, userId: string): Promise<Task>;
  complete(id: string, dto: CompleteTaskDto, userId: string): Promise<Task>;
  reject(id: string, reason: string, userId: string): Promise<Task>;
  cancel(id: string, reason: string, userId: string): Promise<Task>;
  
  // Reassignment
  reassign(id: string, dto: ReassignTaskDto, userId: string): Promise<Task>;
  
  // Evidence
  addEvidence(taskId: string, dto: AddEvidenceDto, userId: string): Promise<TaskEvidence>;
  removeEvidence(evidenceId: string, userId: string): Promise<void>;
  
  // Templates
  createFromTemplate(templateId: string, overrides: Partial<CreateTaskDto>): Promise<Task>;
  
  // Auto-generation
  autoGenerateFromAlert(alertId: string): Promise<Task | null>;
  
  // Stats
  getStats(filters: TaskStatsFilters): Promise<TaskStats>;
}

export type TaskStatus =
  | 'pending'      // Created, not started
  | 'in_progress'  // Assignee started
  | 'completed'    // Finished successfully
  | 'rejected'     // Marked invalid
  | 'cancelled'    // Cancelled before start
  | 'overdue';     // Past due date, not complete

export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent';

export type TaskType =
  | 'expiry-check'
  | 'shelf-audit'
  | 'inventory-count'
  | 'price-update'
  | 'cleaning'
  | 'restock'
  | 'training'
  | 'maintenance'
  | 'other';

export interface CreateTaskDto {
  title: string;
  description?: string;
  type: TaskType;
  priority?: TaskPriority;
  storeId: string;
  assigneeIds: string[]; // Multiple assignees supported
  dueDate?: Date;
  startDate?: Date;
  estimatedDurationMinutes?: number;
  
  // Evidence requirements
  requiresPhoto?: boolean;
  requiresScan?: boolean;
  minimumEvidenceCount?: number;
  
  // Linking
  expiryAlertId?: string;
  productIds?: string[];
  scanSessionId?: string;
  
  // Recurring
  isRecurring?: boolean;
  recurrencePattern?: RecurrencePattern;
  
  metadata?: Record<string, unknown>;
}

export interface CompleteTaskDto {
  notes?: string;
  evidence?: AddEvidenceDto[];
  scanSessionId?: string;
}

export interface AddEvidenceDto {
  type: 'photo' | 'scan' | 'note' | 'video';
  mediaId?: string;
  scanSessionId?: string;
  note?: string;
}

export interface RecurrencePattern {
  type: 'daily' | 'weekly' | 'monthly';
  interval: number; // every N days/weeks/months
  daysOfWeek?: number[]; // 0-6, for weekly
  dayOfMonth?: number; // 1-31, for monthly
  endDate?: Date;
  occurrences?: number;
}

export interface TaskWithDetails extends Task {
  assignees: User[];
  events: TaskEvent[];
  evidence: TaskEvidence[];
  template?: TaskTemplate;
  product?: Product;
  expiryAlert?: ExpiryAlert;
}

export interface TaskStats {
  total: number;
  byStatus: Record<TaskStatus, number>;
  byPriority: Record<TaskPriority, number>;
  byType: Record<TaskType, number>;
  byAssignee: Array<{ userId: string; userName: string; count: number; completed: number }>;
  averageCompletionMinutes: number;
  onTimeRate: number; // percentage completed before due date
}
```

## Implementation Code

### 1. Tasks Schema

```typescript
// server/src/db/schema/tasks.ts
import { pgTable, varchar, uuid, integer, boolean, timestamp, jsonb, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns, softDeleteColumn, auditColumns } from './_base';

export const taskStatusEnum = pgEnum('task_status', [
  'pending',
  'in_progress',
  'completed',
  'rejected',
  'cancelled',
  'overdue',
]);

export const taskPriorityEnum = pgEnum('task_priority', [
  'low',
  'medium',
  'high',
  'urgent',
]);

export const taskTypeEnum = pgEnum('task_type', [
  'expiry-check',
  'shelf-audit',
  'inventory-count',
  'price-update',
  'cleaning',
  'restock',
  'training',
  'maintenance',
  'other',
]);

export const tasks = pgTable(
  'tasks',
  {
    ...baseColumns,
    ...softDeleteColumn,
    ...auditColumns,
    tenantId: uuid('tenant_id').notNull(),
    storeId: uuid('store_id').notNull(),
    
    title: varchar('title', { length: 200 }).notNull(),
    description: varchar('description', { length: 2000 }),
    type: taskTypeEnum('type').notNull(),
    priority: taskPriorityEnum('priority').notNull().default('medium'),
    status: taskStatusEnum('status').notNull().default('pending'),
    
    // Dates
    startDate: timestamp('start_date', { withTimezone: true }),
    dueDate: timestamp('due_date', { withTimezone: true }),
    startedAt: timestamp('started_at', { withTimezone: true }),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    
    // Duration
    estimatedDurationMinutes: integer('estimated_duration_minutes'),
    actualDurationMinutes: integer('actual_duration_minutes'),
    
    // Evidence requirements
    requiresPhoto: boolean('requires_photo').notNull().default(false),
    requiresScan: boolean('requires_scan').notNull().default(false),
    minimumEvidenceCount: integer('minimum_evidence_count').default(0),
    
    // Linking
    expiryAlertId: uuid('expiry_alert_id'),
    productIds: jsonb('product_ids').default([]),
    scanSessionId: uuid('scan_session_id'),
    
    // Template
    templateId: uuid('template_id'),
    
    // Recurring
    isRecurring: boolean('is_recurring').notNull().default(false),
    recurrencePattern: jsonb('recurrence_pattern'),
    parentTaskId: uuid('parent_task_id'),
    
    // Stats
    evidenceCount: integer('evidence_count').notNull().default(0),
    
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    storeStatusDueIdx: index('idx_tasks_store_status_due').on(
      table.storeId,
      table.status,
      table.dueDate,
    ),
    statusIdx: index('idx_tasks_status').on(table.status),
    typeIdx: index('idx_tasks_type').on(table.tenantId, table.type),
    expiryAlertIdx: index('idx_tasks_expiry_alert').on(table.expiryAlertId),
    parentIdx: index('idx_tasks_parent').on(table.parentTaskId),
    dueIdx: index('idx_tasks_due').on(table.dueDate),
  }),
);

export type Task = typeof tasks.$inferSelect;
export type NewTask = typeof tasks.$inferInsert;
```

### 2. Task Assignments Schema

```typescript
// server/src/db/schema/task_assignments.ts
import { pgTable, varchar, uuid, timestamp, index, unique } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';
import { tasks } from './tasks';
import { users } from './users';

export const taskAssignments = pgTable(
  'task_assignments',
  {
    ...baseColumns,
    taskId: uuid('task_id').notNull().references(() => tasks.id, { onDelete: 'cascade' }),
    assigneeId: uuid('assignee_id').notNull().references(() => users.id),
    role: varchar('role', { length: 20 }).notNull().default('primary'), // primary, observer
    assignedBy: uuid('assigned_by').notNull(),
    assignedAt: timestamp('assigned_at', { withTimezone: true }).defaultNow(),
    notifiedAt: timestamp('notified_at', { withTimezone: true }),
    acknowledgedAt: timestamp('acknowledged_at', { withTimezone: true }),
  },
  (table) => ({
    taskAssigneeIdx: unique('uniq_task_assignee').on(table.taskId, table.assigneeId),
    assigneeIdx: index('idx_assignments_assignee').on(table.assigneeId),
  }),
);

export type TaskAssignment = typeof taskAssignments.$inferSelect;
```

### 3. Task Events Schema

```typescript
// server/src/db/schema/task_events.ts
import { pgTable, varchar, uuid, jsonb, timestamp, pgEnum, index } from 'drizzle-orm/pg-core';
import { baseColumns } from './_base';

export const taskEventTypeEnum = pgEnum('task_event_type', [
  'created',
  'assigned',
  'started',
  'updated',
  'completed',
  'rejected',
  'cancelled',
  'reassigned',
  'evidence_added',
  'comment',
  'status_changed',
  'overdue',
]);

export const taskEvents = pgTable(
  'task_events',
  {
    ...baseColumns,
    taskId: uuid('task_id').notNull(),
    type: taskEventTypeEnum('type').notNull(),
    actorId: uuid('actor_id').notNull(),
    
    // Event-specific data
    fromStatus: varchar('from_status', { length: 20 }),
    toStatus: varchar('to_status', { length: 20 }),
    notes: varchar('notes', { length: 1000 }),
    metadata: jsonb('metadata').default({}),
  },
  (table) => ({
    taskCreatedIdx: index('idx_task_events_task_created').on(table.taskId, table.createdAt),
    typeIdx: index('idx_task_events_type').on(table.type),
  }),
);

export type TaskEvent = typeof taskEvents.$inferSelect;
```

### 4. Task Workflow Service (State Machine)

```typescript
// server/src/modules/tasks/services/task-workflow.service.ts
import { Injectable } from '@nestjs/common';
import { BusinessException } from '../../../common/errors/business.exception';
import { ErrorCode } from '../../../common/errors/error-codes';
import { TaskStatus } from '../types/task.types';

@Injectable()
export class TaskWorkflowService {
  private readonly transitions: Record<TaskStatus, TaskStatus[]> = {
    pending: ['in_progress', 'cancelled'],
    in_progress: ['completed', 'rejected', 'cancelled'],
    completed: [],         // Terminal
    rejected: ['pending'], // Can be reopened
    cancelled: [],         // Terminal
    overdue: ['in_progress', 'completed', 'cancelled'],
  };

  validateTransition(from: TaskStatus, to: TaskStatus): void {
    const allowed = this.transitions[from] || [];
    if (!allowed.includes(to)) {
      throw new BusinessException(
        ErrorCode.BUSINESS_RULE_VIOLATION,
        `Cannot transition from ${from} to ${to}`,
        { metadata: { from, to, allowed } },
      );
    }
  }

  isTerminal(status: TaskStatus): boolean {
    return this.transitions[status].length === 0;
  }

  canTransitionTo(from: TaskStatus, to: TaskStatus): boolean {
    return this.transitions[from]?.includes(to) || false;
  }

  getNextPossibleStatuses(current: TaskStatus): TaskStatus[] {
    return this.transitions[current] || [];
  }
}
```

### 5. Tasks Service

```typescript
// server/src/modules/tasks/tasks.service.ts
import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { TasksRepository } from './repositories/tasks.repository';
import { TaskAssignmentsRepository } from './repositories/task-assignments.repository';
import { TaskEventsRepository } from './repositories/task-events.repository';
import { TaskWorkflowService } from './services/task-workflow.service';
import { TaskEvidenceService } from './services/task-evidence.service';
import { DbService } from '../../db/db.service';
import { AuditLogService } from '../../observability/audit-log.service';
import { LoggerService } from '../../logging/logger.service';
import {
  ITasksService,
  CreateTaskDto,
  UpdateTaskDto,
  CompleteTaskDto,
  TaskWithDetails,
} from './types/task.types';
import {
  NotFoundException,
  BusinessException,
  ForbiddenException,
} from '../../common/errors/business.exception';
import { ErrorCode } from '../../common/errors/error-codes';

@Injectable()
export class TasksService implements ITasksService {
  constructor(
    private readonly db: DbService,
    private readonly tasksRepo: TasksRepository,
    private readonly assignmentsRepo: TaskAssignmentsRepository,
    private readonly eventsRepo: TaskEventsRepository,
    private readonly workflow: TaskWorkflowService,
    private readonly evidenceService: TaskEvidenceService,
    private readonly auditLog: AuditLogService,
    private readonly logger: LoggerService,
  ) {}

  async create(dto: CreateTaskDto, createdBy: string): Promise<Task> {
    return this.db.transaction(async (tx) => {
      // Create task
      const task = await this.tasksRepo.create({
        title: dto.title,
        description: dto.description,
        type: dto.type,
        priority: dto.priority || 'medium',
        status: 'pending',
        storeId: dto.storeId,
        startDate: dto.startDate,
        dueDate: dto.dueDate,
        estimatedDurationMinutes: dto.estimatedDurationMinutes,
        requiresPhoto: dto.requiresPhoto || false,
        requiresScan: dto.requiresScan || false,
        minimumEvidenceCount: dto.minimumEvidenceCount || 0,
        expiryAlertId: dto.expiryAlertId,
        productIds: dto.productIds,
        scanSessionId: dto.scanSessionId,
        isRecurring: dto.isRecurring || false,
        recurrencePattern: dto.recurrencePattern,
        metadata: dto.metadata,
      }, tx);
      
      // Create assignments
      for (const assigneeId of dto.assigneeIds) {
        await this.assignmentsRepo.create({
          taskId: task.id,
          assigneeId,
          role: 'primary',
          assignedBy: createdBy,
        }, tx);
      }
      
      // Log creation event
      await this.eventsRepo.create({
        taskId: task.id,
        type: 'created',
        actorId: createdBy,
        toStatus: 'pending',
        metadata: { assigneeCount: dto.assigneeIds.length },
      }, tx);
      
      // Audit
      await this.auditLog.logAction({
        action: 'CREATE',
        resourceType: 'Task',
        resourceId: task.id,
        userId: createdBy,
        tenantId: task.tenantId,
        success: true,
        metadata: { type: dto.type, assignees: dto.assigneeIds },
      });
      
      return task;
    });
  }

  async findById(id: string): Promise<TaskWithDetails | null> {
    const task = await this.tasksRepo.findById(id);
    if (!task) return null;
    
    const [assignees, events, evidence] = await Promise.all([
      this.assignmentsRepo.findByTask(id),
      this.eventsRepo.findByTask(id),
      this.evidenceService.findByTask(id),
    ]);
    
    return {
      ...task,
      assignees: assignees.map((a) => a as any), // Type assertion for User
      events,
      evidence,
    };
  }

  async start(id: string, userId: string): Promise<Task> {
    const task = await this.tasksRepo.findById(id);
    if (!task) throw new NotFoundException('Task', id);
    
    // Check assignment
    const assignment = await this.assignmentsRepo.findByTaskAndUser(id, userId);
    if (!assignment) {
      throw new ForbiddenException('Not assigned to this task');
    }
    
    // Validate transition
    this.workflow.validateTransition(task.status as any, 'in_progress');
    
    return this.db.transaction(async (tx) => {
      const updated = await this.tasksRepo.update(id, {
        status: 'in_progress',
        startedAt: new Date(),
      }, tx);
      
      await this.eventsRepo.create({
        taskId: id,
        type: 'started',
        actorId: userId,
        fromStatus: task.status,
        toStatus: 'in_progress',
      }, tx);
      
      return updated;
    });
  }

  async complete(id: string, dto: CompleteTaskDto, userId: string): Promise<Task> {
    const task = await this.tasksRepo.findById(id);
    if (!task) throw new NotFoundException('Task', id);
    
    // Check assignment
    const assignment = await this.assignmentsRepo.findByTaskAndUser(id, userId);
    if (!assignment) {
      throw new ForbiddenException('Not assigned to this task');
    }
    
    // Validate transition
    this.workflow.validateTransition(task.status as any, 'completed');
    
    // Validate evidence requirements
    if (task.minimumEvidenceCount > 0) {
      const totalEvidence = task.evidenceCount + (dto.evidence?.length || 0);
      if (totalEvidence < task.minimumEvidenceCount) {
        throw new BusinessException(
          ErrorCode.BUSINESS_RULE_VIOLATION,
          `Minimum ${task.minimumEvidenceCount} evidence items required`,
        );
      }
    }
    
    if (task.requiresScan && !dto.scanSessionId && task.scanSessionId === null) {
      throw new BusinessException(
        ErrorCode.BUSINESS_RULE_VIOLATION,
        'Scan session evidence required',
      );
    }
    
    return this.db.transaction(async (tx) => {
      // Add evidence if provided
      if (dto.evidence?.length) {
        for (const ev of dto.evidence) {
          await this.evidenceService.add(id, ev, userId, tx);
        }
      }
      
      // Calculate duration
      const startedAt = task.startedAt ? new Date(task.startedAt) : new Date();
      const completedAt = new Date();
      const actualDurationMinutes = Math.round(
        (completedAt.getTime() - startedAt.getTime()) / 60000,
      );
      
      const updated = await this.tasksRepo.update(id, {
        status: 'completed',
        completedAt,
        actualDurationMinutes,
        ...(dto.scanSessionId && { scanSessionId: dto.scanSessionId }),
      }, tx);
      
      await this.eventsRepo.create({
        taskId: id,
        type: 'completed',
        actorId: userId,
        fromStatus: task.status,
        toStatus: 'completed',
        notes: dto.notes,
        metadata: { actualDurationMinutes },
      }, tx);
      
      // If linked to expiry alert, can auto-resolve
      if (task.expiryAlertId) {
        // BE-18 alert service will be called here
      }
      
      // If recurring, create next occurrence
      if (task.isRecurring && task.recurrencePattern) {
        await this.scheduleNextOccurrence(task, tx);
      }
      
      return updated;
    });
  }

  async reject(id: string, reason: string, userId: string): Promise<Task> {
    const task = await this.tasksRepo.findById(id);
    if (!task) throw new NotFoundException('Task', id);
    
    this.workflow.validateTransition(task.status as any, 'rejected');
    
    return this.db.transaction(async (tx) => {
      const updated = await this.tasksRepo.update(id, {
        status: 'rejected',
      }, tx);
      
      await this.eventsRepo.create({
        taskId: id,
        type: 'rejected',
        actorId: userId,
        fromStatus: task.status,
        toStatus: 'rejected',
        notes: reason,
      }, tx);
      
      return updated;
    });
  }

  async cancel(id: string, reason: string, userId: string): Promise<Task> {
    const task = await this.tasksRepo.findById(id);
    if (!task) throw new NotFoundException('Task', id);
    
    this.workflow.validateTransition(task.status as any, 'cancelled');
    
    return this.db.transaction(async (tx) => {
      const updated = await this.tasksRepo.update(id, {
        status: 'cancelled',
      }, tx);
      
      await this.eventsRepo.create({
        taskId: id,
        type: 'cancelled',
        actorId: userId,
        fromStatus: task.status,
        toStatus: 'cancelled',
        notes: reason,
      }, tx);
      
      return updated;
    });
  }

  // ... other methods (reassign, addEvidence, listForUser, listForStore, getStats, etc.)
  
  private async scheduleNextOccurrence(task: Task, tx: any): Promise<Task | null> {
    const pattern = task.recurrencePattern as any;
    if (!pattern) return null;
    
    const nextDueDate = this.calculateNextDueDate(task.dueDate || new Date(), pattern);
    if (!nextDueDate) return null;
    
    // Check end conditions
    if (pattern.endDate && nextDueDate > new Date(pattern.endDate)) return null;
    
    // Create next task
    return this.tasksRepo.create({
      ...task,
      id: undefined as any,
      status: 'pending',
      startedAt: null,
      completedAt: null,
      actualDurationMinutes: null,
      dueDate: nextDueDate,
      parentTaskId: task.id,
      evidenceCount: 0,
    }, tx);
  }
  
  private calculateNextDueDate(current: Date, pattern: any): Date | null {
    const next = new Date(current);
    
    switch (pattern.type) {
      case 'daily':
        next.setDate(next.getDate() + (pattern.interval || 1));
        return next;
      case 'weekly':
        next.setDate(next.getDate() + 7 * (pattern.interval || 1));
        return next;
      case 'monthly':
        next.setMonth(next.getMonth() + (pattern.interval || 1));
        return next;
      default:
        return null;
    }
  }
}
```

## API Endpoints

| Method | Endpoint | Auth | Role | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/tasks` | Bearer | Manager+ | Create task |
| GET | `/api/v1/tasks` | Bearer | Staff+ | List (filtered) |
| GET | `/api/v1/tasks/my` | Bearer | Staff+ | My assigned |
| GET | `/api/v1/tasks/:id` | Bearer | Staff+ | Get details |
| PATCH | `/api/v1/tasks/:id` | Bearer | Manager+ | Update |
| DELETE | `/api/v1/tasks/:id` | Bearer | Manager+ | Soft delete |
| POST | `/api/v1/tasks/:id/start` | Bearer | Assignee | Start work |
| POST | `/api/v1/tasks/:id/complete` | Bearer | Assignee | Complete |
| POST | `/api/v1/tasks/:id/reject` | Bearer | Assignee | Reject |
| POST | `/api/v1/tasks/:id/cancel` | Bearer | Manager+ | Cancel |
| POST | `/api/v1/tasks/:id/reassign` | Bearer | Manager+ | Reassign |
| POST | `/api/v1/tasks/:id/evidence` | Bearer | Assignee | Add evidence |
| GET | `/api/v1/tasks/stats` | Bearer | Manager+ | Statistics |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-20 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Create Task ✅
```bash
curl -X POST .../tasks -d '{
  "title":"Check expiry in Aisle 3",
  "type":"expiry-check",
  "storeId":"<id>",
  "assigneeIds":["<staff-id>"],
  "dueDate":"2024-12-31T18:00:00Z"
}'
```
**Pass Criteria**: ✅ Task created with assignment

### Test 2: Status Workflow ✅
- pending → in_progress (via /start) ✅
- in_progress → completed (via /complete) ✅
- pending → cancelled ✅
- completed → in_progress ❌ (not allowed)

**Pass Criteria**: ✅ State machine enforced

### Test 3: Evidence Requirements ✅
Task with `requiresPhoto: true, minimumEvidenceCount: 2`:
Try complete without evidence → 422
Add 1 photo, try complete → 422
Add 2 photos, complete → 200

**Pass Criteria**: ✅ Evidence enforced

### Test 4: Assignment Check ✅
Task assigned to User A.
User B tries to start → 403 FORBIDDEN

**Pass Criteria**: ✅ Only assignees can act

### Test 5: Recurring Tasks ✅
Create daily recurring task, complete it.
**Expected**: Next day's task auto-created with parentTaskId

**Pass Criteria**: ✅ Recurrence works

### Test 6: Auto-Task from Alert ✅
Create expiry alert (BE-18).
**Expected**: Auto-task created, linked via expiryAlertId

**Pass Criteria**: ✅ Alert integration works

### Test 7: Multiple Assignees ✅
Task with 3 assignees.
**Expected**: All can see task, any can complete

**Pass Criteria**: ✅ Multi-assignee works

### Test 8: Audit Trail ✅
Check task_events table after status changes:
**Expected**: Entry per transition with actorId, timestamps

**Pass Criteria**: ✅ Full event history

### Test 9: Overdue Detection ✅
Cron job (BE-24) marks tasks past due_date as overdue.
**Pass Criteria**: ✅ Auto-overdue works

### Test 10: Stats ✅
```bash
curl .../tasks/stats
```
**Expected**: Counts by status, priority, type, assignee
**Pass Criteria**: ✅ Stats accurate

### Test 11: Reassignment ✅
Reassign in-progress task to new staff member:
**Expected**: Old assignment closed, new opened, event logged
**Pass Criteria**: ✅ Reassignment audited

### Test 12: Tenant Isolation ✅
**Pass Criteria**: ✅ Cross-tenant blocked

### Test 13: Evidence Types ✅
- Photo evidence (with mediaId from BE-13)
- Scan evidence (with scanSessionId)
- Note evidence (text only)

**Pass Criteria**: ✅ All evidence types work

### Test 14: Performance ✅
List tasks for store with 1000 tasks: < 200ms

**Pass Criteria**: ✅ Indexes used

### Test 15: Validation ✅
- Empty title → 400
- Invalid status → 400
- Past start date → warning
- Multiple assignees with duplicate → 400

**Pass Criteria**: ✅ All validations work

## 🎯 Q&A Session

### Q1: Why state machine?
**Expected**: Prevents invalid transitions, clear lifecycle, audit-friendly

### Q2: Why multiple assignees?
**Expected**: Real-world tasks have helpers, observers, coordinators

### Q3: Why separate task_events table?
**Expected**: Append-only audit log, immutable history, compliance

### Q4: Why minimum evidence count?
**Expected**: Quality control, ensures actual work done, prevents shortcuts

### Q5: How recurring tasks work?
**Expected**: Pattern stored, next created on completion, linked via parentTaskId

### Q6: Why auto-tasks from alerts?
**Expected**: Reduces manual work, ensures expiry alerts are addressed

### Q7: How are overdue tasks tracked?
**Expected**: Cron job updates status nightly, dashboard highlights

### Q8: What about task templates?
**Expected**: Reusable definitions, "Daily shelf check", easier creation

## 📝 Sign-Off Checklist

- [ ] All 15 tests pass
- [ ] State machine enforced
- [ ] Evidence requirements work
- [ ] Recurring tasks work
- [ ] Auto-task from alert works
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-20**
**☐ CHANGES REQUESTED**

---

**END OF BE-19 — DO NOT PROCEED WITHOUT APPROVAL**
