# CLAUDE.md — Church Connect

Documento de contexto técnico para uso com Claude Code.
Leia este arquivo antes de qualquer tarefa neste repositório.

---

## O que é este projeto

**Church Connect** é um SaaS multi-tenant em Ruby on Rails para gestão operacional de igrejas. Cada igreja é um tenant formal da plataforma. A aplicação centraliza voluntários, departamentos, eventos, escalas, tarefas, anúncios e relatórios em uma única aplicação web responsiva.

Não é um sistema monocliente. Não é um painel administrativo simples. É uma plataforma com dois contextos distintos: gestão da plataforma (Platform Admin) e operação cotidiana da igreja (Church Admin, Leader, Volunteer).

---

## Stack técnica

| Camada | Tecnologia |
|---|---|
| Backend | Ruby on Rails 8+, Ruby 3.3+ |
| Banco de dados | PostgreSQL |
| Autenticação | Devise (ou equivalente Rails 8 nativo) |
| Autorização | Pundit |
| Multi-tenancy | `ActiveSupport::CurrentAttributes` (`Current.church`, `Current.user`) |
| Background jobs | Sidekiq + Redis |
| Cache | Redis |
| E-mail | Action Mailer |
| Frontend | Hotwire (Turbo + Stimulus) + SCSS |
| Componentes | ViewComponent ou Phlex |

---

## Arquitetura de diretórios

```
app/
  models/
  models/concerns/
  controllers/
    platform/          # painel SaaS (Platform Admin)
    church/            # painel operacional das igrejas
  policies/            # Pundit
  services/            # casos de uso e orquestração
  queries/             # consultas complexas e relatórios
  jobs/                # Sidekiq
  mailers/
  components/          # ViewComponents reutilizáveis
  presenters/
  lib/
  views/
config/
  routes.rb
db/
  migrate/
  seeds/
```

### Responsabilidade por camada

- **Models**: associações, validações, enums, escopos por tenant. Sem lógica de negócio pesada.
- **Controllers**: finos. Apenas autenticação, autorização, params e delegação ao service.
- **Services**: casos de uso. Um service por operação relevante. Ex: `Events::CreateEvent`, `Assignments::AllocateVolunteer`.
- **Queries**: consultas complexas extraídas de models e controllers. Ex: `UpcomingEventsQuery`, `ResponseRateQuery`.
- **Policies**: Pundit. Autorização contextual por papel, membership e tenant. Nenhuma autorização em controller sem passar pela policy.
- **Jobs**: Sidekiq. Sempre recebem `church_id` explicitamente. Nunca assumem contexto implícito.
- **Components**: UI reutilizável com ViewComponent. Cards, badges, tabelas, formulários.

---

## Multi-tenancy — regras estruturais

Esta é a decisão arquitetural mais crítica do projeto. Violar qualquer item abaixo é um bug grave.

- Banco único com isolamento lógico por `church_id`.
- Toda entidade operacional pertence a uma igreja direta ou indiretamente.
- `Current.church` e `Current.user` são carregados a cada request via middleware/before_action.
- Todo model operacional deve ter scope padrão ou uso explícito de `.where(church: Current.church)`.
- Nenhuma query operacional sem filtro de tenant.
- Pundit policy valida tenant em todo recurso sensível.
- Jobs recebem `church_id` como argumento e restauram `Current.church` no início da execução.
- Notificações e anúncios nunca vazam entre igrejas.

---

## Modelo de domínio

### Entidades principais

| Entidade (model Rails) | Tabela | Finalidade |
|---|---|---|
| `Church` | `churches` | Tenant principal da plataforma |
| `Plan` | `plans` | Plano comercial da plataforma |
| `Subscription` | `subscriptions` | Vínculo contratual church + plano |
| `User` | `users` | Conta global do usuário |
| `ChurchMembership` | `church_memberships` | Vínculo user ↔ church com papel e status |
| `Department` | `departments` | Departamento da igreja |
| `Skill` | `skills` | Habilidade operacional reutilizável |
| `DepartmentMembership` | `department_memberships` | Vínculo user ↔ department com função |
| `Event` | `events` | Evento da igreja |
| `EventRequirement` | `event_requirements` | Vaga/necessidade operacional do evento |
| `ScheduleAssignment` | `schedule_assignments` | Alocação real de pessoa a um requisito |
| `Unavailability` | `unavailabilities` | Período indisponível do voluntário |
| `SwapRequest` | `swap_requests` | Pedido de troca de escala |
| `Task` | `tasks` | Tarefa operacional |
| `Announcement` | `announcements` | Comunicado da igreja |
| `Notification` | `notifications` | Notificação in-app |
| `ActivityLog` | `activity_logs` | Log de auditoria |

### Distinção crítica: EventRequirement vs ScheduleAssignment

`EventRequirement` define a **vaga**: função, quantidade necessária, prioridade.
`ScheduleAssignment` representa o **ocupante real** da vaga: a pessoa alocada, seu status de resposta e timestamp.

Nunca colapsar esses dois em uma única entidade.

---

## Campos mínimos das tabelas

```ruby
# churches
id, name, slug, legal_name, email, phone, timezone, status, created_at, updated_at

# users
id, name, email, encrypted_password, confirmed_at, platform_role, status, created_at, updated_at

# church_memberships
id, church_id, user_id, church_role, status, joined_at, invited_by, created_at, updated_at

# departments
id, church_id, name, description, color, active, created_at, updated_at

# events
id, church_id, department_id, title, event_type, starts_at, ends_at, location, status, notes, created_by, created_at, updated_at

# event_requirements
id, church_id, event_id, skill_id, role_name, required_quantity, priority, notes, created_at, updated_at

# schedule_assignments
id, church_id, event_id, event_requirement_id, user_id, status, response_at, decline_reason, assigned_by, created_at, updated_at

# unavailabilities
id, church_id, user_id, starts_at, ends_at, reason, status, created_at, updated_at

# swap_requests
id, church_id, schedule_assignment_id, requester_user_id, target_user_id, status, reason, reviewed_by, reviewed_at, created_at, updated_at

# tasks
id, church_id, department_id, title, description, assigned_user_id, priority, status, due_at, created_by, created_at, updated_at

# announcements
id, church_id, title, body, audience_type, published_at, created_by, status, created_at, updated_at

# notifications
id, church_id, user_id, type, title, body, related_type, related_id, read_at, created_at

# activity_logs
id, church_id, actor_user_id, entity_type, entity_id, action, metadata_json, ip_address, created_at
```

---

## Índices obrigatórios

```ruby
add_index :schedule_assignments, [:church_id, :event_id, :status]
add_index :events,               [:church_id, :starts_at]
add_index :church_memberships,   [:church_id, :user_id], unique: true
add_index :tasks,                [:church_id, :status, :due_at]
add_index :notifications,        [:church_id, :user_id, :read_at]
```

---

## Papéis de usuário

| Papel | Escopo | O que pode fazer |
|---|---|---|
| `platform_admin` | Plataforma inteira | Gerenciar igrejas, planos, contratos, logs globais |
| `church_admin` | Um tenant | Tudo dentro da sua igreja |
| `department_leader` | Departamento(s) vinculado(s) | Membros, eventos e escalas do seu depto |
| `volunteer` | Pessoal | Ver agenda, responder convocação, registrar indisponibilidade |

Um usuário pode ter papéis diferentes em igrejas diferentes. O papel é sempre lido de `ChurchMembership#church_role` no contexto do tenant ativo.

---

## Rotas — estrutura base

```ruby
# config/routes.rb

namespace :platform do
  resources :churches
  resources :plans
  resources :subscriptions
  resources :activity_logs, only: [:index]
end

scope module: :church do
  resources :members
  resources :departments do
    resources :memberships, only: [:create, :destroy]
  end
  resources :events do
    resources :requirements
    resources :assignments do
      member do
        patch :confirm
        patch :decline
      end
    end
  end
  resources :tasks
  resources :announcements
  resources :notifications, only: [:index, :show, :update]
  resources :unavailabilities
  resources :swap_requests
end
```

---

## Services — casos de uso principais

Criar um service por operação relevante. Não colocar lógica de negócio em controller nem em model.

```
app/services/
  tenancy/
    context_resolver.rb
  memberships/
    invite_user.rb
    accept_invitation.rb
  events/
    create_event.rb
    publish_event.rb
  assignments/
    allocate_volunteer.rb       # valida conflito, indisponibilidade e pertencimento
    respond_to_assignment.rb    # confirma ou recusa
  swaps/
    request_swap.rb
    approve_swap.rb
    reject_swap.rb
  announcements/
    publish_announcement.rb
  reports/
    export_operational_data.rb
  audit/
    record_activity.rb
```

### Padrão de interface de um service

```ruby
class Events::CreateEvent
  def initialize(church:, params:, actor:)
    @church = church
    @params = params
    @actor  = actor
  end

  def call
    # lógica aqui
    # retornar objeto com sucesso/falha e dados
  end
end

# No controller:
result = Events::CreateEvent.new(church: Current.church, params: event_params, actor: Current.user).call
```

---

## Jobs — padrão obrigatório

```ruby
class SendScheduleInvitationJob < ApplicationJob
  queue_as :default

  def perform(church_id:, assignment_id:)
    church = Church.find(church_id)
    Current.church = church  # sempre restaurar contexto

    assignment = church.schedule_assignments.find(assignment_id)
    ScheduleMailer.invitation(assignment).deliver_now
  end
end
```

Jobs existentes:

| Job | Quando dispara |
|---|---|
| `SendScheduleInvitationJob` | Ao criar designação |
| `SendReminderJob` | Agenda programada |
| `PublishAnnouncementNotificationsJob` | Ao publicar anúncio |
| `ExportReportJob` | Solicitação do usuário |
| `CleanupOldDispatchesJob` | Rotina agendada |

---

## Fluxo de autenticação e contexto

1. Usuário autentica via Devise (global).
2. Sistema busca `ChurchMembership` ativo para o usuário.
3. Se múltiplas igrejas: usuário seleciona o tenant ativo.
4. `Current.church` e `Current.user` são definidos a cada request.
5. Controllers aplicam `policy_scope` e `authorize` em todos os recursos.
6. Jobs recebem `church_id` explicitamente e restauram `Current.church`.

---

## Fluxos críticos

### Onboarding de uma nova igreja
1. Platform Admin cadastra a igreja via `/platform/churches/new`
2. Church Admin é convidado → aceita o vínculo
3. Igreja configura departamentos, habilidades e primeiros membros

### Criação de evento e escala
1. Church Admin ou Leader cria evento
2. Define requisitos operacionais (vagas por função)
3. Aloca voluntários manualmente
4. Sistema valida conflitos e indisponibilidades
5. Designações são criadas e convocações enviadas

### Resposta do voluntário
1. Volunteer acessa convocações pendentes
2. Confirma ou recusa com justificativa
3. Sistema grava timestamp, atualiza status, notifica responsáveis

### Troca de escala
1. Volunteer solicita troca
2. Responsável avalia
3. Se aprovado: vaga reatribuída, auditoria registrada
4. Se rejeitado: designação original mantida

---

## Regras de negócio — resumo operacional

- Todo registro operacional pertence a uma igreja.
- Um usuário pode participar de múltiplas igrejas com papéis distintos.
- Líder só gerencia departamentos aos quais esteja formalmente vinculado.
- Evento pode ser interdepartamental, mas pertence a uma única igreja.
- Não alocar voluntário indisponível sem ação administrativa explícita e auditável.
- Confirmação e recusa de escala exigem timestamp.
- Troca de escala não pode gerar duplicidade de ocupação da mesma vaga.
- Toda ação crítica gera log de auditoria via `Audit::RecordActivity`.

---

## Segurança

- Todo acesso passa por autenticação.
- Toda operação sensível valida tenant ativo e papel do usuário via Pundit.
- Strong parameters em todos os controllers.
- Logs de auditoria: ator, ação, entidade, tenant, IP.
- Uploads e exportações protegidos contra acesso cruzado entre tenants.
- Jobs restauram `church_id` antes de qualquer query.

---

## UI / Frontend

- **Hotwire** (Turbo Frames + Turbo Streams + Stimulus). Sem SPA.
- **SCSS** para estilo. Organizado por componente/módulo em `app/assets/stylesheets/`.
- **Mobile-first**. A interface principal é usada em celular por voluntários.
- **Dois layouts distintos**:
  - `platform_layout` — sidebar administrativa para Platform Admin
  - `church_layout` — sidebar + bottom nav mobile para operação da igreja
- Componentes reutilizáveis via ViewComponent em `app/components/`.

---

## Roadmap de implementação

| Fase | Entregas |
|---|---|
| **Fase 1 — Núcleo SaaS** | Tenancy, autenticação, gestão de igrejas, users, memberships, permissões |
| **Fase 2 — Operação** | Departments, events, requirements, escalas, indisponibilidades, respostas |
| **Fase 3 — Comunicação** | Announcements, notifications, e-mails, tarefas, auditoria |
| **Fase 4 — Análise** | Dashboards, relatórios, exportações, otimizações |
| **Fase 5 — Expansão** | Billing, API pública, integrações externas, mobile |

---

## O que não fazer

- Não colocar lógica de negócio em controllers ou views.
- Não fazer query operacional sem filtro de `church_id`.
- Não criar job sem passar `church_id` explicitamente.
- Não misturar rotas/controllers do namespace `platform` com o namespace `church`.
- Não assumir que um usuário pertence a apenas uma igreja.
- Não colapsar `EventRequirement` e `ScheduleAssignment` em uma tabela só.
- Não usar classes utilitárias inline no HTML; estilo vai em SCSS por componente/módulo.
- Não autorizar nada sem passar pela Pundit policy correspondente.