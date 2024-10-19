pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
        KUBECONFIG = credentials('kubeconfig-credentials-id')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // --cache-from 사용하지 않고 빌드
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                    // latest 태그로도 푸시
                    sh "docker tag ${imageName} castlehoo/crime_prediction_image:latest"
                    sh "docker push castlehoo/crime_prediction_image:latest"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG')]) {
                        sh 'kubectl --kubeconfig=$KUBECONFIG apply -f deployment.yaml --validate=false'
                    }
                }
            }
        }
    }
    post {
        always {
            sh 'docker logout'
        }
    }
}
