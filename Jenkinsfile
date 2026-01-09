pipeline {
    agent any

    parameters{
        booleanParam(
            name: 'autoApprove',
            defaultValue: false,
            description: 'Automatically approve Terraform apply without manual confirmation'
        )
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Choose Terraform action to perform')
    }

    environment {
        AWS_ACCOUNT_ID   = "562404438689"
        AWS_REGION       = "us-east-1"
        ECR_REGISTRY     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        BACKEND_REPO    = "backend"
        FRONTEND_REPO   = "frontend"
        ADMIN_REPO      = "admin"

        IMAGE_TAG        = "latest"

        LOCAL_BACKEND_IMAGE  = "backend:${IMAGE_TAG}"
        LOCAL_FRONTEND_IMAGE = "frontend:${IMAGE_TAG}"
        LOCAL_ADMIN_IMAGE    = "admin:${IMAGE_TAG}"

        ECS_CLUSTER_NAME      = "food-delivery-cluster"
        ECS_BACKEND_SERVICE   = "food-backend-service"
        ECS_FRONTEND_SERVICE  = "food-frontend-service"
        ECS_ADMIN_SERVICE     = "food-admin-service"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git(
                    url: 'https://github.com/gopi-ganesan/new-terraform-project-CI-CD.git',
                    branch: 'main',
                    credentialsId: 'github-token'
                )
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    dir('terraform') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    dir('terraform') {
                        sh 'terraform plan -out=tfplan'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
            }
        }

        stage('Terraform Apply / Destroy') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    dir('terraform') {
                        script {
                            if (params.action == 'apply') {
                                if (!params.autoApprove) {
                                    def plan = readFile 'tfplan.txt'
                                    input(
                                        message: 'Do you want to apply the Terraform plan?',
                                        parameters: [
                                            text(
                                                name: 'PLAN',
                                                defaultValue: plan,
                                                description: 'Terraform execution plan'
                                            )
                                        ]
                                    )
                                }
                                sh 'terraform apply -input=false tfplan'
                            } else {
                                sh 'terraform destroy -auto-approve'
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh "docker-compose -f docker-compose.yml build"
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """
                }
            }
        }

        stage('Push Docker Images to ECR') {
            steps {
                sh """
                    docker tag ${LOCAL_BACKEND_IMAGE} ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}

                    docker tag ${LOCAL_FRONTEND_IMAGE} ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    docker tag ${LOCAL_ADMIN_IMAGE} ${ECR_REGISTRY}/${ADMIN_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${ADMIN_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh """
                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER_NAME} \
                            --service ${ECS_BACKEND_SERVICE} \
                            --force-new-deployment

                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER_NAME} \
                            --service ${ECS_FRONTEND_SERVICE} \
                            --force-new-deployment

                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER_NAME} \
                            --service ${ECS_ADMIN_SERVICE} \
                            --force-new-deployment
                    """
                }
            }
        }
    }
}
