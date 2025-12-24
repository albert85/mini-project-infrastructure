pipeline {
    agent any
    parameters {
        choice( name: 'TF_ACTION', 
        choices: ['init', 'plan', 'apply'], 
        description: 'Terraform action to perform')
    }
    
    stages {
        stage ('checkout') {
            steps {
                checkout scm
            }
        }
        stage ('terraform init') {
            steps {
                dir ('terraform') {
                    sh ' terraform init -reconfigure'
                }
            }
        }

        
        stage ('terraform validate') {
            steps {
                dir ('terraform') {
                    sh ' terraform validate'
                }
            }
        } 
        
        stage ('terraform plan') {
            when  {
                expression { params.TF_ACTION == 'plan'}
            }
            steps {
                dir ('terraform') {
                    sh ' terraform plan -var-file="dev.tfvars"'
                }
            }
        } 

        stage ('terraform apply') {
         when  {
                expression { params.TF_ACTION == 'apply'}
            }
            steps {
                dir ('terraform') {
                    sh ' terraform apply -var-file="dev.tfvars" -auto-approve'
                }
            }
        } 

        stage ('terraform destroy') {
         when  {
                expression { params.TF_ACTION == 'destroy'}
            }
            steps {
                dir ('terraform') {
                    sh ' terraform destroy -var-file="dev.tfvars"  -auto-approve'
                }
            }
        } 
    }
}