// Jenkinsfile
pipeline {
    agent any

    environment {
        // Docker Hub ID는 더 이상 필요 없지만, 이미지 이름 변수는 유지합니다.
        EC2_HOST = '15.164.46.184' // <-- 실제 EC2 Public IP 또는 DNS로 변경하세요!
        APP_NAME = 'BootMybatisTilesV3'
        APP_VERSION = '0.0.1-SNAPSHOT'
        WAR_FILE = "${APP_NAME}-${APP_VERSION}.war"
        DOCKER_IMAGE_NAME = "chang" // Docker 이미지 이름
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/your-username/your-repo.git'
            }
        }

        stage('Build and Package WAR') {
            steps {
                script {
                    docker.image('maven:3-openjdk-11').inside {
                        sh 'mvn clean package -DskipTests'
                    }
                    sh "ls -l target/${env.WAR_FILE}"
                }
            }
        }

        // 'Build Docker Image' 및 'Push Docker Image to Registry' 단계를 EC2에서 수행하도록 변경
        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent(['ec2-ssh-credentials']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} " \
                                # EC2에서 프로젝트 소스 코드 디렉토리 생성 및 복사
                                mkdir -p /home/ubuntu/app/src && \
                                mkdir -p /home/ubuntu/app/target && \
                                mkdir -p /home/ubuntu/app/src/main/java && \
                                mkdir -p /home/ubuntu/app/src/main/resources && \
                                mkdir -p /home/ubuntu/app/src/main/webapp && \
                                # 먼저 기존 컨테이너 중지 및 삭제
                                echo '--- Stopping existing container (if any) ---' && \
                                docker stop ${env.DOCKER_IMAGE_NAME}-app || true && \
                                docker rm ${env.DOCKER_IMAGE_NAME}-app || true && \
                                \
                                # 로컬 Jenkins workspace의 파일들을 EC2로 SCP 복사
                                # 중요: Jenkins 컨테이너 내부의 워크스페이스 경로를 사용해야 합니다.
                                # docker exec jenkins pwd 명령 등으로 정확한 경로 확인
                                # 여기서는 Jenkins 에이전트 워크스페이스에 파일이 있다고 가정합니다.
                                # 'target' 디렉토리와 'pom.xml', 'Dockerfile', 'src' 디렉토리를 복사
                                # EC2의 /home/ubuntu/app 디렉토리에 복사됩니다.
                                exit_code=0;
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/target/ ${WORKSPACE}/pom.xml ${WORKSPACE}/Dockerfile ${WORKSPACE}/src/ ubuntu@${env.EC2_HOST}:/home/ubuntu/app/ || exit_code=\$?;
                                if [ \$exit_code -ne 0 ]; then
                                    echo "SCP failed, attempting rsync for incremental copy..."
                                    rsync -avz --exclude 'target/' -e 'ssh -o StrictHostKeyChecking=no' ${WORKSPACE}/ ubuntu@${env.EC2_HOST}:/home/ubuntu/app/ && \
                                    rsync -avz -e 'ssh -o StrictHostKeyChecking=no' ${WORKSPACE}/target/ ubuntu@${env.EC2_HOST}:/home/ubuntu/app/target/
                                fi;
                                \
                                # EC2에서 Docker 이미지 빌드
                                echo '--- Building Docker Image on EC2 ---' && \
                                cd /home/ubuntu/app && \
                                docker build -t ${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} . && \
                                \
                                # 새로운 컨테이너 실행
                                echo '--- Running new container ---' && \
                                docker run -d --name ${env.DOCKER_IMAGE_NAME}-app -p 80:8080 ${env.DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} && \
                                \
                                # 오래된 이미지 정리
                                echo '--- Cleaning up old images ---' && \
                                docker image prune -f \
                                "
                        """
                        // 주의: '${WORKSPACE}/target/', '${WORKSPACE}/pom.xml', '${WORKSPACE}/Dockerfile', '${WORKSPACE}/src/'
                        // 이 경로들은 Jenkins 컨테이너 내부의 워크스페이스 경로입니다.
                        // Jenkins 컨테이너가 마운트한 '/var/jenkins_home' 아래에 워크스페이스가 생성될 수 있습니다.
                        // 만약 `scp` 명령에서 `No such file or directory` 에러가 발생한다면,
                        // Jenkins `Console Output`에서 `[Pipeline] ws` 로 시작하는 라인에서 워크스페이스 경로를 확인해야 합니다.
                        // 일반적으로 '/var/jenkins_home/workspace/<YOUR_JOB_NAME>' 형태입니다.
                        // 정확한 워크스페이스 경로가 `src`와 `target` 폴더가 있는 곳입니다.
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}