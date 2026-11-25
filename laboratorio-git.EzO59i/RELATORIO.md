# Exercício de Git e GitHub

Vídeo-base: https://www.youtube.com/watch?v=kB5e-gTAl_s

- Data: 2026-11-25 01:09:08 -0300
- Remoto: bruno-sime/CI1005-Qualidade-de-Software
- Branch principal do exercício: qualidade-20261125-010835-44378-21177/principal
- Branch staging: qualidade-20261125-010835-44378-21177/staging
- Branch da funcionalidade: qualidade-20261125-010835-44378-21177/sistema-de-login
- Pull request: https://github.com/bruno-sime/CI1005-Qualidade-de-Software/pull/1
- Versão inicial: 1fa5ca2fadf81aa0935de6dde00c4ef9c7768939
- Segunda versão (restaurada após reset): cd7738fa716303fe3bf4cf9f39f2381d33d00981
- Versão final em ambos os diretórios: b95acab7903f9f039a21934818610fa54649e343
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
