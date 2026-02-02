pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }

    stages {

        stage('Checkout Source') {
            steps {
                git(
                    branch: 'main',
                    url: 'https://github.com/ORG_NAME/REPO_NAME.git',
                    credentialsId: 'github-credentials'
                )
            }
        }

        stage('Static Sanity Checks') {
            steps {
                sh '''
                  terraform --version
                  ansible --version
                  python3 --version
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra') {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate & Plan') {
            steps {
                dir('infra') {
                    sh '''
                      terraform validate
                      terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                dir('infra') {
                    sh '''
                      python3 generate_inventory.py
                      cat hosts.ini
                    '''
                }
            }
        }

        stage('Connectivity Test') {
            steps {
                dir('infra') {
                    sh '''
                      ansible all -i ansible/inventory/hosts.ini -m ping
                    '''
                }
            }
        }

        stage('Deploy WordPress (Ansible)') {
            steps {
                dir('ansible') {
                    sh '''
                      ansible-playbook -i ansible/inventory/hosts.ini deploy_wordpress.yml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🚀 Pipeline completed successfully. Infrastructure and application are converged."
        }
        failure {
            echo "🔥 Pipeline failed. State is preserved for forensic analysis."
        }
        always {
            archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
        }
    }
}
