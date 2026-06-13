# ══════════════════════════════════════════════════════════════
# Imagem custom do Jenkins — ja vem com tudo configurado
#   - Ferramentas embutidas: git, rsync, nodejs, docker CLI
#   - Plugins pre-instalados (plugins.txt)
#   - Configuration as Code (jenkins.yaml): admin/admin, git tool,
#     e seed job que cria o pipeline 'financas-pipeline' sozinho
# Resultado: subiu o container -> Jenkins ja pronto pra 'Build Now'
# ══════════════════════════════════════════════════════════════
FROM jenkins/jenkins:lts

USER root

# ── Ferramentas que o pipeline precisa dentro do container ──────
RUN apt-get update -qq && \
    apt-get install -y -qq \
        git \
        rsync \
        docker.io \
        curl \
        ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y -qq nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Pula o setup wizard e aponta o JCasC ────────────────────────
# IMPORTANTE: o JCasC fica FORA de /var/jenkins_home porque esse path
# e um volume persistente que "tapa" o conteudo da imagem em runtime.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc/jenkins.yaml

# ── Instala plugins definidos em plugins.txt ────────────────────
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# ── Copia a configuracao JCasC (inclui o seed job) ──────────────
COPY jenkins.yaml /usr/share/jenkins/ref/casc/jenkins.yaml

# Volta pro usuario jenkins (mas o container roda como root via Terraform
# para ter acesso ao docker.sock)
USER jenkins
