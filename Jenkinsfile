pipeline {
  agent { label 'maven' }

  options {
    timeout(time: 10, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {
    stage('Toolchain check') {
      steps {
        sh '''
          set -eu
          java -version
          mvn -v
          docker version --format '{{.Server.Version}}'
          aws sts get-caller-identity --query Arn --output text
        '''
      }
    }
  }
}
