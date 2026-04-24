pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'financas-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        INTEGRATION_PORT = '3001'
        INTEGRATION_CONTAINER = 'financas-integracao'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
                dir('frontend') {
                    sh 'npm ci'
                }
            }
        }

        stage('Lint') {
            parallel {
                stage('Lint Backend') {
                    steps {
                        dir('backend') {
                            sh 'npm run lint'
                        }
                    }
                }
                stage('Lint Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm run lint'
                        }
                    }
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Test Backend') {
                    steps {
                        dir('backend') {
                            sh 'npm run test:ci'
                        }
                    }
                    post {
                        always {
                            junit 'backend/test-results.xml'
                        }
                    }
                }
                stage('Test Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm run test:ci'
                        }
                    }
                    post {
                        always {
                            junit 'frontend/test-results.xml'
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
            }
        }

        stage('Deploy Integration') {
            steps {
                sh """
                    docker stop ${INTEGRATION_CONTAINER} || true
                    docker rm ${INTEGRATION_CONTAINER} || true
                    docker run -d \
                        --name ${INTEGRATION_CONTAINER} \
                        --network financas-network \
                        -p ${INTEGRATION_PORT}:3000 \
                        -v financas-integracao-data:/data \
                        -e NODE_ENV=integration \
                        -e PORT=3000 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }
    }

    post {
        always {
            cleanWs(cleanWhenNotBuilt: false)
        }
        success {
            echo "Pipeline executado com sucesso! Integração disponível na porta ${INTEGRATION_PORT}"
        }
        failure {
            echo 'Pipeline falhou!'
        }
    }
}
