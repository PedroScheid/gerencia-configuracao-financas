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
                sh 'rsync -a --delete --exclude node_modules /repo/ ./'
            }
        }

        stage('Install & Quality') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('backend') {
                            sh 'npm install --prefer-offline'
                            sh 'npm run lint'
                            sh 'npm run test:ci'
                            sh 'npm run build'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'backend/test-results.xml'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm install --prefer-offline'
                            sh 'npm run lint'
                            sh 'npm run test:ci'
                            sh 'npm run build'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'frontend/test-results.xml'
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
                    docker rm -f ${INTEGRATION_CONTAINER} 2>/dev/null || true
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
        success {
            echo "Pipeline executado com sucesso! Integracao disponivel na porta ${INTEGRATION_PORT}"
        }
        failure {
            echo 'Pipeline falhou!'
        }
    }
}
