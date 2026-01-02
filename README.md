# Secure CI/CD Pipeline Demo (GitHub Actions + Snyk)

Това репо е малка, но **production-style** Node.js услуга, която демонстрира реалистичен DevSecOps pipeline с GitHub Actions + Snyk:

- **Quality gates**: ESLint + unit tests
- **SAST**: Snyk Code (анализ на нашия код)
- **SCA**: Snyk Open Source (уязвимости в зависимости)
- **Container security**: Snyk Container (уязвимости в Docker image-а)
- **CD**: build + push към GHCR и deploy към Kubernetes чрез `kubectl`

## Услугата накратко

- Runtime: Node.js 20
- Framework: Express
- Health endpoint: `GET /healthz` -> `{ "status": "ok" }`

## Локално стартиране

```powershell
npm ci
npm run lint
npm test
npm start
```

По подразбиране слуша на `http://localhost:3000`.

## CI/CD: какво точно прави workflow-ът

Файл: `.github/workflows/main.yml`

Pipeline-ът е структуриран на отделни job-ове, за да има ясни quality/security gates и да е лесен за дебъг.

### Job 1: `quality` (PR + main)

**Цел:** спираме проблеми в кода възможно най-рано.

Стъпки:

- `npm ci` (винаги от lockfile)
- `npm run lint`
- `npm test` (Node built-in test runner)

Ако тук не е зелено, security/container/deploy изобщо не тръгват.

### Job 2: `security` (PR + main)

**Цел:** “shift-left” security проверки на PR-и и на main.

Стъпки:

1) `npm run audit` с `--audit-level=high` (бърз сигнал от npm advisory DB)

2) **Snyk Open Source (SCA)**

- сканира `package-lock.json` за CVE-та и уязвими версии
- gate: pipeline fail при **High/Critical** (`--severity-threshold=high`)

3) **Snyk Code (SAST)**

- сканира `src/` за уязвими модели/потоци (инжекции, небезопасни операции, hardcoded secrets и др.)
- gate: fail при **High/Critical** (`--severity-threshold=high`)

#### Deep dive (SAST vs SCA) – в контекста на това репо

- **SAST (Snyk Code)**: гледа *нашата логика* — как използваме входа/изхода, как строим заявки, как обработваме данни. Проблемите са в `src/`.
- **SCA (Snyk Open Source)**: гледа *чуждия код* — зависимостите, които доставяме. Проблемите са в `package.json`/`package-lock.json`.

#### Политика за “fail” (реалистична и управляема)

За да няма шум и да не блокира development-а за ниско-рискови находки, pipeline-ът е конфигуриран да спира само при **High/Critical**.

Файлът `.snyk` е в репото, за да може всеки “ignore” да е:

- reviewable (Code Review)
- с причина
- с крайна дата (expiry)

### Job 3: `container` (само `main` при push)

**Цел:** build + security scan на image-а преди да го качим.

Стъпки:

- Build на Docker image-а от `Dockerfile` (multi-stage, non-root runtime)
- **Snyk Container** scan на построения image (High+)
- Push към GitHub Container Registry (GHCR)

Име на image-а, което pipeline-ът използва:

- `ghcr.io/<owner>/<repo>/my-app:<git-sha>`

### Job 4: `deploy` (само `main` при push)

**Цел:** автоматичен deployment към Kubernetes.

Стъпки:

- `kubectl apply -f k8s/`
- `kubectl set image deployment/my-app my-app=<image-from-container-job>`
- `kubectl rollout status` (чака rollout-а да завърши)

`k8s/deployment.yaml` е hardened (non-root, read-only filesystem, drop capabilities, seccomp).

## Secrets (GitHub repository secrets)

Това са реалните секрети, които workflow-ът очаква:

- `SNYK_TOKEN` – Snyk API token (нужен за SAST/SCA/Container)
- `KUBECONFIG_B64` – base64-нат kubeconfig за deploy job-а

> Забележка: за push към GHCR се използва вградения `GITHUB_TOKEN` с `packages: write` permission.

## Как да валидираш локално, че ще мине CI

```powershell
npm ci
npm run lint
npm test
npm run audit
```

Snyk командите могат да се пуснат локално само ако имаш Snyk CLI и `SNYK_TOKEN`.
