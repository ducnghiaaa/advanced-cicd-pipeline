pipeline {
  agent { label 'maven' }

  options {
    timeout(time: 30, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {
    stage('Build & Unit Test') {
      steps {
        dir('app') {
          sh 'mvn -B clean verify'
        }
      }
      post {
        always {
          junit 'app/target/surefire-reports/*.xml'
        }
      }
    }

    stage('SonarCloud Analysis + Quality Gate') {
      steps {
        dir('app') {
          withSonarQubeEnv('sonarcloud') {
            sh 'mvn -B sonar:sonar -Dsonar.qualitygate.wait=true'
          }
        }
      }
    }
  }
}
