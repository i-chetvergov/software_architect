# C4 Container Diagram

![C4 Container Diagram](../assets/diagrams/c4_containers.svg)

## Назначение диаграммы

Диаграмма C4 Containers описывает внутреннюю структуру UC-платформы
на уровне контейнеров и микросервисов.

## Основные контейнеры

- API Gateway
- Identity / IAM Service
- Call Control Service
- SIP Gateway / SBC
- WebRTC Gateway
- Presence Service
- Messaging / Chat Service
- Media / Recording Service
- Provisioning Service
- Billing / CDR Service
- Notification Service
- Observability Stack

## Архитектурный смысл

Диаграмма отражает микросервисный стиль архитектуры и протоколы
взаимодействия между контейнерами (SIP, WebRTC, REST, gRPC, Events).