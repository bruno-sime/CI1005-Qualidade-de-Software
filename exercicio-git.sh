#!/usr/bin/env bash
# Curso Dev Aprender: https://www.youtube.com/watch?v=kB5e-gTAl_s
# Bash 3.2+ (macOS, Linux, Git Bash no Windows). Execute com bash, nunca source.
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Uso: bash exercicio_git.sh [DONO/REPOSITORIO] [--automatico]
     bash exercicio_git.sh --teste-local --automatico

Sem DONO/REPOSITORIO, usa o origin do repositório do diretório atual.
Cria dois diretórios e branches exclusivas; publica somente arquivos de exemplo.
Abre e integra um pull request real entre branches do laboratório.
Por padrão, pausa antes de cada etapa. --automatico remove essas pausas.
--teste-local usa um remoto local e SIMULA o PR; não cumpre a etapa GitHub.
Requisitos para GitHub: git, gh instalado, gh auth login e permissão de escrita.
HELP
}
AUTO=0
LOCAL=0
REPO_INPUT=''
for arg in "$@"; do
  case "$arg" in
    --automatico) AUTO=1 ;;
    --teste-local) LOCAL=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'Opção desconhecida: %s\n' "$arg" >&2; exit 2 ;;
    *) [[ -z "$REPO_INPUT" ]] || { usage; exit 2; }; REPO_INPUT=$arg ;;
  esac
done
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  printf 'Execute com bash exercicio_git.sh; não use source.\n' >&2
  return 2
fi
command -v git >/dev/null || { printf 'Instale o Git: https://git-scm.com/downloads\n' >&2; exit 1; }
if [[ "$AUTO" == 0 && ! -t 0 ]]; then
  printf 'Sem terminal interativo. Use --automatico.\n' >&2; exit 2
fi
# Evita que variáveis de um Git externo redirecionem os comandos do laboratório.
for var in GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS; do
  if printenv "$var" >/dev/null 2>&1; then
    printf 'Abra um terminal sem a variável %s antes de executar.\n' "$var" >&2; exit 2
  fi
done
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
export GIT_PAGER=cat PAGER=cat GIT_EDITOR=true GIT_MERGE_AUTOEDIT=no
export GH_PAGER=cat GH_PROMPT_DISABLED=1

NAME=$(git config user.name || true)
NAME=${NAME:-Bruno}
EMAIL=$(git config user.email || true)
REPO=''
if [[ "$LOCAL" == 0 ]]; then
  command -v gh >/dev/null || { printf 'Instale gh: https://cli.github.com/ e execute gh auth login.\n' >&2; exit 1; }
  gh auth status --hostname github.com >/dev/null 2>&1 || {
    printf 'Autentique primeiro: gh auth login --hostname github.com\n' >&2; exit 1;
  }
  if [[ -z "$REPO_INPUT" ]]; then
    REPO_INPUT=$(git remote get-url origin 2>/dev/null) || {
      printf 'Informe DONO/REPOSITORIO ou execute dentro de um clone com origin.\n' >&2; exit 2;
    }
  fi
  # Normaliza explicitamente o host: este script destina-se ao github.com.
  case "$REPO_INPUT" in
    https://github.com/*) REPO_INPUT=${REPO_INPUT#https://github.com/} ;;
    git@github.com:*) REPO_INPUT=${REPO_INPUT#git@github.com:} ;;
    ssh://git@github.com/*) REPO_INPUT=${REPO_INPUT#ssh://git@github.com/} ;;
  esac
  REPO_INPUT=${REPO_INPUT%/}
  REPO_INPUT=${REPO_INPUT%.git}
  [[ "$REPO_INPUT" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || {
    printf 'Use DONO/REPOSITORIO ou uma URL do github.com, sem credenciais.\n' >&2; exit 2;
  }
  REPO=$(gh repo view "$REPO_INPUT" --json nameWithOwner --jq .nameWithOwner)
  PERMISSION=$(gh repo view "$REPO" --json viewerPermission --jq .viewerPermission)
  case "$PERMISSION" in
    ADMIN|MAINTAIN|WRITE) ;;
    *) printf 'Sua conta não tem permissão de escrita em %s.\n' "$REPO" >&2; exit 1 ;;
  esac
  if [[ -z "$EMAIL" ]]; then
    EMAIL=$(gh api --hostname github.com user --jq '"\(.id)+\(.login)@users.noreply.github.com"')
  fi
fi
EMAIL=${EMAIL:-bruno@example.invalid}

ROOT=$(mktemp -d "$PWD/laboratorio-git.XXXXXX")
ROOT=$(cd "$ROOT" && pwd -P)
ID="qualidade-$(date +%Y%m%d-%H%M%S)-$$-${RANDOM}"
BASE="$ID/principal"
STAGING="$ID/staging"
LOGIN="$ID/sistema-de-login"
U1="$ROOT/usuario1"
U2="$ROOT/usuario2"
LOG="$ROOT/execucao.log"
REPORT="$ROOT/RELATORIO.md"
PR_URL=''
SUCCESS=0
main() {
finish() {
  code=$?
  if [[ "$SUCCESS" != 1 ]]; then
    printf '\nEXECUÇÃO INTERROMPIDA (código %s). Consulte %s\n' "$code" "$LOG"
    printf 'Os diretórios e branches foram preservados. Nenhuma limpeza automática é feita.\n'
    printf 'Para tentar novamente do início, rode o script outra vez: ele cria outro laboratório.\n'
  fi
}
trap finish EXIT
run() {
  printf '\n[%s] $' "$(basename "$PWD")"
  printf ' %q' "$@"
  printf '\n'
  "$@"
}
step() {
  printf '\n========== %s ==========\n%s\n' "$1" "$2"
  if [[ "$AUTO" == 0 ]]; then
    read -r -p 'Leia a explicação e pressione Enter para executar... ' answer
  fi
}
file() {
  printf '\n[%s] Escrevendo %s:\n%s\n' "$(basename "$PWD")" "$1" "$2"
  printf '%s\n' "$2" > "$1"
}
expected_failure() {
  if run "$@"; then
    printf 'ERRO: o comando deveria falhar neste exemplo.\n' >&2; exit 1
  else
    printf 'Falha esperada e demonstrada; continuando.\n'
  fi
}
configure() {
  run git config --local user.name "$1"
  run git config --local user.email "$EMAIL"
  run git config --local commit.gpgsign false
  run git config --local core.autocrlf false
  run git config --local core.excludesFile /dev/null
  run git config --local push.default simple
  run git config --local push.autoSetupRemote false
  run git config --local pull.rebase false
  mkdir -p .git/lab-hooks
  run git config --local core.hooksPath "$PWD/.git/lab-hooks"
  if [[ "$LOCAL" == 0 ]]; then
    # Credenciais do gh somente neste clone; não altera configuração global.
    run git config --local credential.https://github.com.helper ''
    run git config --local --add credential.https://github.com.helper '!gh auth git-credential'
  fi
}
printf 'Laboratório: %s\nRepositório: %s\nBranch principal do exercício: %s\n' "$ROOT" "${REPO:-REMOTO LOCAL DE TESTE}" "$BASE"
printf 'São duas cópias locais e uma conta GitHub; o segundo autor é uma simulação.\n'
printf 'O histórico do exercício será independente do histórico existente no remoto.\n'

step '1 — Pré-requisitos, init e identidade (04:07–10:59)' 'Verifica o Git e inicializa usuario1. Nome e e-mail são configurados apenas neste laboratório.'
run git --version
mkdir "$U1"
cd "$U1"
run git init --template=
run git symbolic-ref HEAD "refs/heads/$BASE"
configure "$NAME (usuario 1)"
file 'meu codigo.txt' "Olá, meu nome é $NAME."
run git status

step '2 — add individual, add . e commit (11:00–15:29)' 'Compara arquivos não rastreados com arquivos preparados no índice. Cria a primeira versão.'
run git add 'meu codigo.txt'
run git status
file app.py 'print("Hello")'
file vendas.csv 'produto,quantidade
caderno,2'
# SVG e CSV são arquivos reais, em substituição aos exemplos PNG e XLSX da aula.
file imagem.svg '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="30"><text x="5" y="20">Git</text></svg>'
run git status
run git add .
run git status
run git commit -m 'Commit inicial: texto, código, tabela e imagem'
V1=$(git rev-parse HEAD)

step '3 — remote e primeiro push (15:30–20:23)' 'Demonstra os erros de push sem remoto e sem upstream; depois publica a branch principal do exercício.'
expected_failure git push
if [[ "$LOCAL" == 1 ]]; then
  REMOTE="$ROOT/remoto.git"
  run git init --bare --template= "$REMOTE"
else
  REMOTE="https://github.com/$REPO.git"
fi
run git remote add origin "$REMOTE"
run git remote -v
expected_failure git push
run git push -u origin "$BASE"
if [[ "$LOCAL" == 1 ]]; then
  run git --git-dir="$REMOTE" symbolic-ref HEAD "refs/heads/$BASE"
fi

step '4 — Ciclo de atualização e histórico (20:24–23:07)' 'Modifica o arquivo, prepara a alteração, cria outra versão e envia. Exibe reflog e log.'
printf 'Olá, eu sou uma nova linha.\n' >> 'meu codigo.txt'
run git status
run git diff
run git add .
run git status
run git commit -m 'Permitir cadastrar usuários: segunda versão do exemplo'
V2=$(git rev-parse HEAD)
run git push
run git reflog
run git log --oneline --decorate

step '5 — Navegar entre versões com reset (23:08–26:00)' 'Como no vídeo, usa reset --hard para voltar à versão 1 e retornar à versão 2. Somente arquivos de exemplo já commitados estão envolvidos.'
[[ -z "$(git status --porcelain)" ]] || { printf 'Árvore suja antes do reset; abortando.\n'; exit 1; }
run git reset --hard "$V1"
run cat 'meu codigo.txt'
run git reflog
run git reset --hard "$V2"
run cat 'meu codigo.txt'
[[ "$(git rev-parse HEAD)" == "$V2" ]]

step '6 — Branch staging (26:01–33:38)' 'Cria uma branch e muda para ela. A modificação fica separada da principal até o merge.'
run git branch "$STAGING"
run git branch
run git checkout "$STAGING"
printf 'Alteração feita na staging: nome completo de exemplo.\n' >> 'meu codigo.txt'
run git add .
run git commit -m 'Staging: adicionar nome completo'
run git push -u origin "$STAGING"
run git checkout "$BASE"
run cat 'meu codigo.txt'
run git diff "$BASE..$STAGING" -- 'meu codigo.txt'

step '7 — Merge e feature de login (33:39–41:08)' 'Atualiza a principal antes de integrar staging. Depois cria e integra uma feature, como na aula.'
run git pull --ff-only
run git merge "$STAGING" --no-edit
run git push
run git pull --ff-only
run git checkout -b "$LOGIN" "$BASE"
file 'sistema de login.txt' 'Digite seu nome:
Digite sua senha:'
run git add .
run git commit -m 'Criar sistema de login demonstrativo'
run git checkout "$BASE"
run git pull --ff-only
run git merge "$LOGIN" --no-edit
run git push

step '8 — Dois usuários em dois diretórios (adaptação do enunciado)' 'Clona em usuario2, configura um autor simulado e envia uma alteração. usuario1 precisa de pull para recebê-la.'
cd "$ROOT"
run git clone --template= --single-branch --branch "$BASE" "$REMOTE" "$U2"
cd "$U2"
configure "$NAME (usuario 2 simulado)"
file colaboracao.txt 'Alteração produzida no diretório usuario2; ambos os usuários são simulados pela mesma pessoa.'
run git add .
run git commit -m 'Usuário 2 simulado: contribuir com o projeto'
run git push
cd "$U1"
[[ ! -f colaboracao.txt ]] || { printf 'Exemplo de sincronização inesperado.\n'; exit 1; }
run git pull --ff-only
run cat colaboracao.txt

step '8B — Conflito entre os dois usuários (complemento prático)' 'Concretiza o conflito discutido na introdução: dois autores alteram a mesma linha. Demonstra push rejeitado, conflito no pull e resolução.'
file app.py 'print("Hello, usuario 1")'
run git add app.py
run git commit -m 'Usuário 1: alterar saudação'
run git push
cd "$U2"
file app.py 'print("Hello, usuario 2")'
run git add app.py
run git commit -m 'Usuário 2 simulado: alterar a mesma saudação'
expected_failure git push
expected_failure git -c merge.conflictStyle=merge pull --no-rebase --no-edit
[[ "$(git diff --name-only --diff-filter=U)" == app.py ]] || {
  printf 'O pull falhou por motivo diferente do conflito esperado em app.py.\n'; exit 1;
}
run git status
run cat app.py
file app.py 'print("Hello people: usuarios 1 e 2")'
run git add app.py
run git commit -m 'Resolver conflito: combinar saudação dos dois usuários'
run git push
cd "$U1"
run git pull --ff-only
run cat app.py

step '9 — Pull request real (41:09–45:50)' 'Adiciona idade à feature. Publica e abre PR para a principal do EXERCÍCIO. Inspeciona a diferença e integra usando sua própria conta.'
run git checkout "$LOGIN"
run git merge "$BASE" --no-edit
printf 'Digite sua idade:\n' >> 'sistema de login.txt'
run git add .
run git commit -m 'Adicionar idade ao sistema de login'
run git push -u origin "$LOGIN"
if [[ "$LOCAL" == 0 ]]; then
  file "$ROOT/corpo-pr.md" 'Exercício individual de Git/GitHub da disciplina de Qualidade.

Adiciona um campo de idade ao arquivo demonstrativo de login; não implementa validação.
Os diretórios usuario1 e usuario2 simulam dois participantes, usando uma única conta GitHub.
Este PR integra exclusivamente branches do laboratório. Não representa revisão independente.'
  run gh pr create --repo "$REPO" --base "$BASE" --head "$LOGIN" --title 'Exercício: adicionar idade ao login' --body-file "$ROOT/corpo-pr.md"
  PR_URL=$(gh pr view "$LOGIN" --repo "$REPO" --json url --jq .url)
  run gh pr diff "$PR_URL" --repo "$REPO"
  if [[ "$AUTO" == 0 ]]; then
    read -r -p 'Confira o diff acima. Enter para fazer o merge do PR do laboratório... ' answer
  fi
  PR_HEAD=$(git rev-parse HEAD)
  run gh pr merge "$PR_URL" --repo "$REPO" --merge --match-head-commit "$PR_HEAD"
  PR_STATE=$(gh pr view "$PR_URL" --repo "$REPO" --json state --jq .state)
  [[ "$PR_STATE" == MERGED ]] || {
    printf 'O PR está em %s, ainda não MERGED. Conclua no GitHub conforme as regras do repositório.\n' "$PR_STATE"; exit 1;
  }
else
  printf '\nTESTE LOCAL: PR real NÃO executado. Merge local usado apenas para testar o fluxo.\n'
  run git checkout "$BASE"
  run git merge --no-ff "$LOGIN" -m 'TESTE LOCAL: simulação de merge do PR'
  run git push
  PR_URL='NÃO REALIZADO — execução em modo de teste local'
fi
run git checkout "$BASE"
run git pull --ff-only
run cat 'sistema de login.txt'

step '10 — .gitignore para pasta e arquivo (45:51–49:10)' 'Cria segredos fictícios e uma imagem de exemplo. Demonstra o status antes/depois e verifica que não entraram no índice.'
mkdir segredos
file segredos/senhas.txt 'DADO FICTÍCIO: exemplo didático, sem nenhuma credencial real.'
file fotos.svg '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>'
run git status --short --untracked-files=all
run touch .gitignore
file .gitignore 'segredos/
fotos.svg'
run git status --short --untracked-files=all
run git check-ignore -v segredos/senhas.txt fotos.svg
run git add .
run git diff --cached --name-only
if git ls-files --error-unmatch segredos/senhas.txt >/dev/null 2>&1 || git ls-files --error-unmatch fotos.svg >/dev/null 2>&1; then
  printf 'ERRO: um arquivo que deveria estar ignorado foi adicionado.\n'; exit 1
fi
run git commit -m 'Adicionar gitignore: ignorar pasta de segredos e foto'
run git push
run git status --short --ignored

step '11 — Conferência e evidências' 'Atualiza usuario2 e confere que os dois diretórios terminaram na mesma versão. Gera um relatório e preserva o log.'
cd "$U2"
run git pull --ff-only
[[ "$(git rev-parse HEAD)" == "$(git -C "$U1" rev-parse HEAD)" ]]
[[ ! -e segredos/senhas.txt && ! -e fotos.svg ]]
cd "$U1"
[[ -z "$(git status --porcelain)" ]]
run git log --all --graph --decorate --oneline
run git log --format='%h | %an <%ae> | %s'
run git branch -avv
cat > "$REPORT" <<EOF
# Exercício de Git e GitHub

Vídeo-base: https://www.youtube.com/watch?v=kB5e-gTAl_s

- Data: $(date '+%Y-%m-%d %H:%M:%S %z')
- Remoto: ${REPO:-remoto local de teste}
- Branch principal do exercício: $BASE
- Branch staging: $STAGING
- Branch da funcionalidade: $LOGIN
- Pull request: $PR_URL
- Versão inicial: $V1
- Segunda versão (restaurada após reset): $V2
- Versão final em ambos os diretórios: $(git rev-parse HEAD)
- Dois participantes simulados por uma pessoa e uma conta GitHub.

| Trecho da aula | Reprodução |
| --- | --- |
| 04:07–07:54 | Git verificado; conta existente usada como pré-requisito |
| 07:55–10:59 | git init, arquivo de texto e git status |
| 11:00–13:21 | git add individual e git add . com vários tipos de arquivo |
| 13:22–15:29 | configuração local de identidade e primeiro commit |
| 15:30–20:23 | falhas esperadas de push, remote add e push com upstream |
| 20:24–22:31 | edição, status, diff, add, commit e push |
| 22:32–23:07 | git reflog e git log |
| 23:08–26:00 | reset --hard à versão 1 e retorno à versão 2 |
| 26:01–33:38 | criação, troca e publicação de staging |
| 33:39–41:08 | pull antes de merge; feature de login criada e integrada |
| 41:09–45:50 | PR GitHub criado, diff inspecionado e merge confirmado; somente em modo GitHub |
| 45:51–49:10 | .gitignore para diretório e arquivo, com checagem do índice |
| Adaptação do enunciado | clone em usuario2, commit, push e pull em usuario1 |
| Complemento prático à introdução | alterações concorrentes, push rejeitado e resolução de conflito real |

CSV substitui a planilha XLSX e SVG substitui PNG: os exemplos mantêm a operação
Git demonstrada, usando arquivos válidos que não exigem programas adicionais.
Os textos foram adaptados ao aluno. A branch principal do exercício substitui
a master da aula; tem histórico independente e não altera main/master existente.
Configurações de identidade são locais, em vez de globais, para preservar seu ambiente.
Instalação do Git e criação de conta/repositório não são automatizadas: são pré-requisitos.

O log completo está em execucao.log, ao lado deste relatório. Ele inclui comandos,
saídas, falhas intencionais e a alternância dos diretórios. Os segredos são fictícios.
O reflog é local e não é enviado pelo push; preserve os diretórios e o log.
EOF
printf '\nCONCLUÍDO: %s\nRelatório: %s\nLog: %s\nPR: %s\n' "$ROOT" "$REPORT" "$LOG" "$PR_URL"
if [[ "$LOCAL" == 1 ]]; then
  printf 'ATENÇÃO: modo de teste local. A etapa de GitHub/PR real ainda precisa ser feita.\n'
fi
SUCCESS=1
}
# Pipeline comum, sem /dev/fd ou substituição de processo, para maior compatibilidade.
# pipefail propaga falhas do laboratório mesmo com a saída passando pelo tee.
main 2>&1 | tee "$LOG"
