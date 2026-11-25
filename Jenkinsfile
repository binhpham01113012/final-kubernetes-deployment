pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    environment {
        MAVEN_OPTS = '-Xmx256m'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'chmod +x mvnw'
            }
        }

        stage('Test') {
            steps {
                sh './mvnw -B test -DargLine=-Xmx192m'
            }
        }

        stage('Build JAR') {
            steps {
                sh './mvnw -B package -DskipTests'
                sh 'ls -lh target/*.jar'
            }
        }

        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar',
                                 fingerprint: true
            }
        }

        stage('Publish to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh '''
                        set +x
                        SETTINGS=$(mktemp)
                        trap 'rm -f "$SETTINGS"' EXIT

                        cat > "$SETTINGS" <<'EOF'
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASS}</password>
    </server>
  </servers>
</settings>
EOF

                        ./mvnw -B -s "$SETTINGS" \
                          deploy:deploy-file \
                          -Dfile=target/helloworld-0.0.1-SNAPSHOT.jar \
                          -DpomFile=pom.xml \
                          -DrepositoryId=nexus \
                          -Durl=http://nexus:8081/repository/maven-snapshots/
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Build and Nexus upload successful.'
        }
        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
