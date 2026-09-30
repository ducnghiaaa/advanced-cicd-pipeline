pipeline {
  agent { label 'maven' }

  options {
    timeout(time: 30, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    AWS_REGION = 'ap-southeast-1'
    ECR_REPO   = 'p06/sample-app'
  }

  stages {
    stage('Secret scan') {
      steps {
        // TruffleHog on the entire git history of the checkout.
        // --only-verified drops false positives, --fail exits non-zero,
        // --no-update disables auto-upgrade (binary is root-owned, jenkins can't write).
        sh 'trufflehog --no-update git file://. --only-verified --fail'
      }
    }

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

    stage('Trivy filesystem scan') {
      steps {
        // Scans dependency manifests (pom.xml) + resolved deps for HIGH/CRITICAL.
        // NOTE: with Spring Boot 2.2 + twitter4j + github-api-1.99 this will
        // almost certainly fail. Set --exit-code 0 temporarily to see the
        // report, or track exceptions in .trivyignore (with reason).
        sh '''
          trivy fs \
            --scanners vuln \
            --severity HIGH,CRITICAL \
            --exit-code 1 \
            --ignore-unfixed \
            app/
        '''
      }
    }

    stage('Docker build') {
      steps {
        dir('app') {
          script {
            env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
            env.LOCAL_IMAGE = "${env.ECR_REPO}:${env.IMAGE_TAG}"
          }
          sh 'docker build -t ${LOCAL_IMAGE} .'
        }
      }
    }

    stage('Trivy image scan') {
      steps {
        sh '''
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --exit-code 1 \
            ${LOCAL_IMAGE}
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        script {
          env.ACCOUNT_ID = sh(
            script: 'aws sts get-caller-identity --query Account --output text',
            returnStdout: true
          ).trim()
          env.ECR_REGISTRY = "${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
          env.REMOTE_IMAGE = "${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}"
        }

        sh '''
          set -eu

          # ECR repo is IMMUTABLE: skip if this tag was already pushed
          # to avoid a failed 'tag already exists' error.
          if aws ecr describe-images \
                --repository-name "${ECR_REPO}" \
                --image-ids imageTag="${IMAGE_TAG}" \
                --region "${AWS_REGION}" >/dev/null 2>&1; then
            echo "Tag ${IMAGE_TAG} already exists in ECR - skipping push."
            exit 0
          fi

          aws ecr get-login-password --region "${AWS_REGION}" \
            | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

          docker tag  "${LOCAL_IMAGE}"  "${REMOTE_IMAGE}"
          docker push "${REMOTE_IMAGE}"
        '''
      }
    }
  }

  post {
    always {
      // Keep the agent disk usable across builds.
      sh '''
        docker image prune -f || true
        if [ -n "${LOCAL_IMAGE:-}" ];  then docker image rm -f "${LOCAL_IMAGE}"  || true; fi
        if [ -n "${REMOTE_IMAGE:-}" ]; then docker image rm -f "${REMOTE_IMAGE}" || true; fi
      '''
    }
  }
}
