pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build --exclude-task test'
                stash(name: 'build-artifacts', includes: '**/build/libs/*.jar')
            }
        }

        stage('Test & Coverage') {
            steps {
                sh './gradlew test'
                stash(name: 'test-artifacts', includes: '**/build/test-results/test/TEST-*.xml')
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(credentialsId: 'sonarqube', installationName: 'SonarQube Server') {
                    sh './gradlew sonarqube'
                }
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
    }
}