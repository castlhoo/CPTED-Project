pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
    }
    stages {
        stage('Checkout') {
            steps {
                // GitHub에서 소스코드 가져오기
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
                // kubeconfig-credentials-id 기반으로 쿠버네티스에 접근
                withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG')]) {
                    script {
                        // kubeconfig 파일을 사용하여 kubectl로 배포 실행
                        sh "kubectl --kubeconfig=$KUBECONFIG apply -f deployment.yaml --validate=false"
                    }
                }
            }
        }
    }
    post {
        always {
            // 작업 후 도커 로그아웃
            sh 'docker logout'
        }
    }
}
