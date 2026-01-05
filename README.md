# DevOps Playground: Secure CI/CD (GitHub Actions + Snyk + CodeQL + Docker + Kubernetes)

- **Quality gates**: ESLint + unit tests
- **SAST**: Snyk Code (анализ на нашия код)
- **SCA**: Snyk Open Source (уязвимости в зависимости)
- **Container security**: Snyk Container (уязвимости в Docker image-а)
- **CD**: build + push към GHCR и deploy към Kubernetes чрез `kubectl`

## Vertical deep dive: Security на няколко слоя (multi-level)

За да е **вертикално на повече нива**, security е разгърнат на слоеве:

- **Code level (SAST)**: Snyk Code + CodeQL
- **Dependencies (SCA)**: Snyk Open Source + `npm audit`
- **Container level**: build + scan на Docker image
- **Runtime/IaC level (Kubernetes hardening)**: securityContext, seccomp, non-root, read-only FS

## Приложението накратко

- Runtime: Node.js 20
- Framework: Express
- Health endpoint: `GET /healthz` -> `{ "status": "ok" }`

## Локално стартиране

```powershell
npm ci
npm start
```

По подразбиране слуша на `http://localhost:3000`.

## CI/CD: какво точно прави workflow-ът

Файл: `.github/workflows/main.yml`

Pipeline-ът е структуриран на отделни job-ове

### Job 1: `quality` (PR + main)

**Цел:** спираме проблеми при build-ването в кода възможно най-рано.

Стъпки:

- `npm ci`
- `npm run lint`
- `npm test`

### Job 2: `codeql` (SAST) (PR + main)

**Цел:** допълнителен SAST слой чрез CodeQL.

Стъпки:

- Initialize CodeQL (JavaScript/TypeScript)
- Autobuild
- Analyze

### Job 3: `security` (PR + main)

**Цел:** Security проверки на PR-и и на main.

Стъпки:

1. `npm run audit` с `--audit-level=high`

2. **Snyk Open Source (SCA)**

- сканира `package-lock.json` за уязвими версии
- gate: pipeline fail при **High/Critical** (`--severity-threshold=high`)

3. **Snyk Code (SAST)**

- сканира `src/` за уязвимости
- gate: fail при **High/Critical** (`--severity-threshold=high`)

#### Deep dive (SAST vs SCA)

- **SAST (Snyk Code)**: Проблемите са в `src/`.
- **SCA (Snyk Open Source)**: Проблемите са в `package.json`/`package-lock.json`.

Pipeline-ът е конфигуриран да спира само при **High/Critical**.

Файлът `.snyk` е в репото, за да може всеки “ignore” да е:

- с причина
- с крайна дата (expiry)

### Job 4: `container` (само `main` при push)

**Цел:** build + security scan на image-а преди да го качим.

Стъпки:

- Build на Docker image-а от `Dockerfile`
- **Snyk Container** scan на построения image (High+)

### Job 5: `deploy` (само `main` при push)

**Цел:** автоматичен deployment към Kubernetes.

Стъпки:

- `kubectl apply -f k8s/`
- `kubectl set image deployment/dev-ops-playground dev-ops-playground=<image-from-container-job>`
- `kubectl rollout status`

#### Какъв Kubernetes използва deploy job-ът?

За да е **напълно автоматизиран** и да не зависи от външен клъстър, deploy job-ът създава **временен Kubernetes** в GitHub Actions runner чрез **k3d** (k3s-in-Docker), deploy-ва manifest-ите и чака rollout.

## GitHub Actions Secrets

Pipeline-ът очаква следните **GitHub Actions Secrets**:

- `SNYK_TOKEN` – Snyk API token (нужен за SAST/SCA/Container)

За push към GHCR се използва вградения `GITHUB_TOKEN` (автоматично генериран от GitHub) с `packages: write` permission.

## Как да валидираш локално, че ще мине CI

```powershell
npm ci
npm run lint
npm test
npm run audit
```
