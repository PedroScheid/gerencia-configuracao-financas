# Prompt para gerar a imagem da arquitetura (ChatGPT / DALL·E)

Cole o texto abaixo no ChatGPT (com geração de imagem ativada) para gerar um
diagrama ilustrativo da arquitetura do projeto.

---

## Prompt (PT-BR)

Crie um diagrama de arquitetura de software limpo, profissional e moderno (estilo
infográfico técnico, fundo claro, ícones nítidos, cores distintas por camada),
no formato horizontal (landscape), em português, representando o pipeline CI/CD
abaixo. Use ícones reconhecíveis das tecnologias e setas claras indicando o fluxo.

**Título:** "Arquitetura CI/CD — Sistema de Finanças"

**Camadas e elementos (da esquerda para a direita):**

1. **Desenvolvedor local** — ícone de notebook. Texto: "Altera o código, faz commit e push".

2. **GitHub** — ícone do GitHub (octocat) e símbolo de branch Git. Texto:
   "Repositório, branch main". Uma seta verde sai daqui para o Jenkins com o
   rótulo "push dispara o build (polling SCM)".

3. **Jenkins (CI/CD)** — ícone de engrenagem/Jenkins. Mostrar um pipeline com 4
   etapas em sequência: "Checkout" → "Lint + 37 Testes (ESLint, Jest/Vitest)" →
   "Build Docker" → "Deploy". Indicar um "Quality Gate" em vermelho que bloqueia
   o deploy se o lint ou os testes falharem.

4. **Docker Host (VM Linux)** — uma caixa grande, com o ícone da baleia do Docker,
   contendo TRÊS ambientes isolados lado a lado, cada um como um container com seu
   próprio banco de dados:
   - **Integração** (verde) — porta 3001 — banco SQLite próprio
   - **Homologação** (azul) — porta 3002 — banco SQLite próprio
   - **Produção** (roxo) — porta 3000 — banco SQLite próprio
   Setas cinza entre eles com o rótulo "promote" (Integração → Homologação → Produção).

5. **Infraestrutura como Código** — uma faixa/camada inferior com os ícones de
   **Terraform** (provisiona a rede, o Jenkins e os containers) e **Ansible**
   (provisiona a VM: Docker, Node, firewall).

**Rodapé / legenda de tecnologias (com ícones):** Docker, Jenkins, Terraform,
Ansible, ESLint, Jest/Vitest, Node.js 20, SQLite, Git/GitHub.

**Estilo:** vetorial flat moderno, paleta sóbria (azuis, verdes, roxo, cinza),
boa legibilidade, espaçamento generoso, sem excesso de texto. Proporção 16:9.

---

## Observações

- O ChatGPT/DALL·E gera imagens ILUSTRATIVAS — ótimas para capa de slide, mas os
  textos podem sair levemente errados ou em inglês. Revise antes de usar.
- Para um diagrama TÉCNICO preciso (textos e portas exatos), use os arquivos que
  já estão no projeto: `arquitetura-resumida.png` (visão geral) e `ARQUITETURA.md`
  (diagrama Mermaid detalhado, editável).
