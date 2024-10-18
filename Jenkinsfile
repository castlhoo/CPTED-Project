pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
        KUBECONFIG = credentials('kubeconfig-credentials-id') // Securely accessing kubeconfig
    }
    stages {
        stage('Checkout') {
            steps {
                // 깃허브에서 코드 가져오기
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // 도커 이미지 빌드
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Docker Hub에 로그인 및 이미지 푸시
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // 쿠버네티스에 배포
                    withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG')]) {
                        sh 'kubectl --kubeconfig=$KUBECONFIG apply -f deployment.yaml --validate=false'
                    }
                }
            }
        }
    }
    post {
        always {
            // 작업 완료 후 로그아웃
            sh 'docker logout'
        }
    }
}
