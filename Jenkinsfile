pipeline {
    agent any

    environment {
        IMAGE_NAME = 'riyenas0925/growing_spring'
        SONARQUBE_CREDENTIAL = 'sonarqube'
        SONARQUBE_INSTALLATION_NAME = 'SonarQube Server'
        DOCKER_IMAGE = ''
        DOCKERHUB_CREDENTIAL = 'dockerhub'
    }

    stages {
        stage('Build') {
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build --exclude-task test'
                stash(name: 'build-artifacts', includes: '**/build/libs/*.jar')
            }
            post {
                success {
                    archiveArtifacts 'build/libs/*.jar'
                }
            }
        }

        stage('Unit Test') {
            steps {
                sh './gradlew test'
                stash(name: 'test-artifacts', includes: '**/build/test-results/test/TEST-*.xml')
            }
            post {
                always {
                    junit '**/build/test-results/test/TEST-*.xml'
                    step([$class: 'JacocoPublisher'])
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(credentialsId: SONARQUBE_CREDENTIAL, installationName: SONARQUBE_INSTALLATION_NAME) {
                    sh './gradlew sonarqube'
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            echo "Status: ${qg.status}"
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        } else {
                            echo "Status: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                branch 'develop'
            }
            steps {
                unstash 'build-artifacts'
                script {
                    DOCKER_IMAGE = docker.build IMAGE_NAME
                }
            }
        }

        stage('Push Docker Image') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    docker.withRegistry('', DOCKERHUB_CREDENTIAL) {
                        DOCKER_IMAGE.push "${BUILD_NUMBER}"
                        DOCKER_IMAGE.push 'latest'
                    }
                }
            }
        }

        stage('Remove Unused Docker Image') {
            when {
                branch 'develop'
            }
            steps {
                sh 'docker rmi $IMAGE_NAME:${BUILD_NUMBER}'
                sh 'docker rmi $IMAGE_NAME:latest'
            }
        }

        stage('Deploy') {
            when {
                branch 'develop'
            }
            steps([$class: 'BapSshPromotionPublisherPlugin']) {
                sshPublisher(
                    continueOnError: false, failOnError: true,
                    publishers: [
                        sshPublisherDesc(
                            configName: 'growing-spring-server-1',
                            verbose: true,
                            transfers: [
                                sshTransfer(
                                    sourceFiles: '',
                                    removePrefix: '',
                                    remoteDirectory: '',
                                    execCommand: 'sh ~/deploy.sh'
                                )
                            ]
                        )
                    ]
                )
            }
        }
    }
}