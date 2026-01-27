# Deployment Diagram

![Deployment Diagram](../assets/diagrams/deployment.svg)

## Назначение диаграммы

Диаграмма развертывания фиксирует **целевую модель размещения UC-платформы** в инфраструктуре облачного региона (EU-1) и уточняет **технологический стек и протоколы взаимодействия**, которые на контейнерном уровне обозначались агрегированно.

В отличие от контейнерной диаграммы, здесь акцент сделан на:

- **сетевых зонах** (публичная/приватная подсети);
- **Kubernetes как базовом runtime** (namespaces, policies, mTLS);
- **доменных контурах нагрузки** (Chat отдельно от Voice Conferencing);
- **формальной точке принятия решений доступа** (Policy PDP: OPA);
- **единой шине событий Kafka** (топики по доменам);
- **S3-хранилище** для медиа и записей (AWS S3 или MinIO), с явным протоколом `S3 API (HTTPS/TLS)`.

## Модель развертывания

### Клиенты и периметр

Пользовательские клиенты (Web/Mobile/Desktop) обращаются к платформе через:

- **CDN** по `HTTPS/HTTP2` для web-assets;
- **Ingress/Load Balancer** в публичной подсети для:
  - `HTTPS/HTTP2` — REST/Web API (управляющие запросы),
  - `WSS` — real-time контур чата (WebSocket),
  - `WebTransport/UDP + ICE` — real-time сигнализация,
  - `WebRTC (DTLS/SRTP)` — медиа-потоки голос/видео.

Таким образом, на уровне развертывания зафиксировано, что разные классы трафика имеют разные каналы и профили нагрузки.

### Kubernetes-кластер приложений (приватная подсеть)

В приватной подсети размещён Kubernetes-кластер приложений с разделением по namespaces:

- `uc-gateway`: **API Gateway**, **WebRTC Gateway**;
- `uc-core`: **IAM**, **OPA PDP**, **Call Control**, **SIP GW/SBC**, **Presence**, **Chat**, **Voice Conferencing**, **Provisioning**, **Billing/CDR**, **Notification**;
- `uc-media`: **Media/Recording** (RTP/SRTP, запись/обработка);
- `uc-observability`: **Prometheus**, **Loki/ELK**, **Tempo/Jaeger**, **Grafana/Kibana**.

Внутри кластера применяются:
- **NetworkPolicies** для сегментации east-west трафика;
- **mTLS** для сервис-to-сервис взаимодействий;
- **HPA** для горизонтального масштабирования по CPU/RPS/latency (и при необходимости по кастомным метрикам).

### Слой данных (приватная подсеть)

В слое данных размещены управляемые/кластерные сервисы:

- **PostgreSQL HA** (Managed PG / Patroni, AZ-aware) с отдельными логическими БД:
  - `DB_ACCOUNTS`, `DB_CALLS`, `DB_CDR`, `DB_MESSAGING`, `DB_CONFERENCES`;
- **Redis cluster** (Managed Redis / Sentinel) с `Redis/TLS` для кэшей/сессий/presence;
- **Kafka cluster** (Managed Kafka / KRaft) с `Kafka/TLS + ACL` как **единой event-bus** и набором доменных топиков:
  `call-events`, `cdr-events`, `chat-events`, `conf-events`, `provisioning-events`, `notification-events`, `recording-events`;
- **Object Storage (S3)** — AWS S3 или MinIO, доступ по `S3 API (HTTPS/TLS)` для:
  `recordings/`, `media/`.

## Архитектурные допущения и гарантии

- **Горизонтальное масштабирование** сервисов выполняется независимо по доменам:
  - Chat и Voice Conferencing масштабируются отдельно, так как имеют разные SLA и профиль нагрузки (WebSocket vs RTP/медиа-мост).
- **Высокая доступность** критичных компонентов обеспечивается:
  - multi-AZ для PostgreSQL HA,
  - кластером Kafka с TLS/ACL,
  - Redis cluster,
  - репликацией ключевых pods и отказоустойчивым Ingress/LB.
- **ABAC/OPA как архитектурный драйвер** закреплён через отдельный **Policy PDP (OPA)**:
  - API Gateway делает запросы `authorize(subject, resource, action, context)` и получает `allow/deny + obligations`.
- **Event-driven взаимодействия** реализуются через Kafka:
  - типичная семантика доставки — `at-least-once`,
  - корректность обеспечивается **идемпотентностью** потребителей и дедупликацией (в т.ч. через Redis/ключи).
- **Изоляция окружений (prod/stage)** предполагается на уровне:
  - отдельных namespaces/кластеров,
  - раздельных Kafka топиков/кластеров и S3 buckets,
  - раздельных политик доступа и секретов.

Диаграмма развертывания согласована с Context/Container/Component диаграммами: клиенты и внешние системы находятся **вне границы платформы**, а внутри границы явно выделены домены Chat, Voice Conferencing, Policy PDP, Kafka и S3 как выбранные инфраструктурные компоненты.