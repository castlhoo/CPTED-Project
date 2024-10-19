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
        stage('Parallel Build and Test') {
            parallel {
                stage('Build Docker Image') {
                    steps {
                        script {
                            def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                            // Docker 캐시 활용하여 빌드
                            sh """
                                docker pull castlehoo/crime_prediction_image:latest || true
                                docker build --cache-from=castlehoo/crime_prediction_image:latest -t ${imageName} .
                            """
                        }
                    }
                }
                stage('Run Tests') {
                    steps {
                        // 테스트 스크립트 실행 (예: 유닛 테스트)
                        sh './run_tests.sh'
                    }
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
                    // latest 태그로 업데이트
                    sh "docker tag ${imageName} castlehoo/crime_prediction_image:latest"
                    sh "docker push castlehoo/crime_prediction_image:latest"
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
