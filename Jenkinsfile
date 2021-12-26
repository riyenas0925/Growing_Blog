pipeline {
    agent any

    environment {
        IMAGE_NAME = 'riyenas0925/growing_spring'
        SONARQUBE_CREDENTIAL = 'sonarqube'
        SONARQUBE_INSTALLATION_NAME = 'SonarQube Server'
        DOCKER_IMAGE = ''
        DOCKERHUB_CREDENTIAL = 'dockerhub'
        DOCKER_REGISTRY_URL = ''
    }

    stages {
        stage('Build') {
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build --exclude-task test'
                stash(name: 'build-artifacts', includes: '**/build/libs/*.jar')
            }
        }

        stage('Unit Test') {
            steps {
                sh './gradlew test'
                stash(name: 'test-artifacts', includes: '**/build/test-results/test/TEST-*.xml')
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

        stage('Report & Publish') {
            steps {
                unstash 'build-artifacts'
                unstash 'test-artifacts'
                junit '**/build/test-results/test/TEST-*.xml'
                step([$class: 'JacocoPublisher'])
                archiveArtifacts 'build/libs/*.jar'
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
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
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                script {
                    docker.withRegistry(DOCKER_REGISTRY_URL, DOCKERHUB_CREDENTIAL) {
                        DOCKER_IMAGE.push('$BUILD_NUMBER')
                        DOCKER_IMAGE.push('latest')
                    }
                }
            }
        }

        stage('Remove Unused Docker Image') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                sh 'docker rmi $IMAGE_NAME:$BUILD_NUMBER'
                sh 'docker rmi $IMAGE_NAME:latest'
            }
        }
    }
}