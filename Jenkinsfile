pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        AWS_ACCOUNT_ID="<AWS_ACCOUNT_ID>"
        AWS_DEFAULT_REGION="<AWS_DEFAULT_REGION>"
        IMAGE_REPO_NAME="<IMAGE_REPO_NAME>"
        IMAGE_TAG="<IMAGE_TAG>"
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
    }
    stages {
        stage('code-pulling') {
            steps {
                slackSend channel: 'deployment', message: 'Job Started'
                git credentialsId: 'ubuntu', url: 'https://github.com/sanjay7917/student-ui.git'
                slackSend channel: 'deployment', message: 'Code Pulled Successfully'
            }
        }
        stage("build-maven"){
            steps{
                slackSend channel: 'deployment', message: 'Building Artifact'
                sh 'mvn clean package'
                slackSend channel: 'deployment', message: 'Artifact Build Successfully'
            }    
        }
        stage('sonarqube-integration'){
            steps{
                withSonarQubeEnv('sonarqube-9.9') {
                    sh "mvn sonar:sonar"
                }
                slackSend channel: 'deployment', message: 'Code Quality Check Report Transfered On SonarQube Server'
            }
        }
        stage("sonarqube-quality-gate-check") {
            steps {
                waitForQualityGate abortPipeline: true
                slackSend channel: 'deployment', message: 'Code Quality Gate Report Transfered On SonarQube Server'
            }
        }
        stage('artifact-to-s3') {
            steps {
                slackSend channel: 'deployment', message: 'Sending Artifact On AWS S3 Bucket'
                withAWS(credentials: 'aws', region: 'us-east-2') {
                    sh'''
                    sudo apt update -y
                    sudo apt install awscli -y
                    aws s3 ls
                    aws s3 mb s3://<Bucket_Name> --region us-east-2
                    sudo mv /var/lib/jenkins/workspace/prod-deployment-pipeline/target/studentapp-2.2-SNAPSHOT.war /tmp/studentapp-2.2-SNAPSHOT${BUILD_ID}.war
                    aws s3 cp /tmp/studentapp-2.2-SNAPSHOT${BUILD_ID}.war  s3://<Bucket_Name>/
                    sudo rm -rvf /tmp/studentapp-2.2-SNAPSHOT${BUILD_ID}.war
                    '''
                }
                slackSend channel: 'deployment', message: 'Artifact Stored On AWS S3 Bucket'
            }     
        }
        stage("pull-artifact"){
            steps{
                slackSend channel: 'deployment', message: 'Pulling Artifact From AWS S3 Bucket'
                withAWS(credentials: 'aws', region: 'us-east-2') {
                    script {
                        sh 'aws s3 cp s3://<Bucket_Name>/studentapp-2.2-SNAPSHOT${BUILD_ID}.war .'
                        sh 'mv studentapp-2.2-SNAPSHOT${BUILD_ID}.war student.war'
                    }
                }
                slackSend channel: 'deployment', message: 'Artifact Pulled Successfully'
            }    
        }
        stage("build-docker-image"){
            steps{
                slackSend channel: 'deployment', message: 'Building Docker Image From Dockerfile'
                withAWS(credentials: 'aws', region: 'us-east-2') {
                    script {
                        sh 'docker build -t ${IMAGE_REPO_NAME} .'
                    }
                }
                slackSend channel: 'deployment', message: 'Docker Image Build Successfully'
            }    
        }
        stage("push-docker-image-to-ecr"){
            steps{
                slackSend channel: 'deployment', message: 'Sending Docker Image To AWS ECR'
                script {
                    sh "docker tag ${IMAGE_REPO_NAME} ${REPOSITORY_URI}:${IMAGE_TAG}"
                    sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                }
                slackSend channel: 'deployment', message: 'Docker Image Pushed On AWS ECR'
            }
        }
        stage('send-k8s-manifest') {
            steps {
                slackSend channel: 'deployment', message: 'Sending K8S Deployment Manifest To EKS Cluster Server'
                sshagent(['ubuntu']) {
                    sh "scp -o StrictHostKeyChecking=no deploysvc.yml ubuntu@<IP_Of_EKS_Cluster_Agent>:/home/ubuntu"
                }
                slackSend channel: 'deployment', message: 'K8S Deployment Manifest Transfered Successfully'
            }
        }
        stage('k8s-cluster-creation-and-deploy') {
            steps {
                slackSend channel: 'deployment', message: 'Creating AWS EKS Cluster, Nodegroup and Deploying K8S Manifest On Slave Nodes'
                withCredentials([sshUserPrivateKey(credentialsId: 'ubuntu', keyFileVariable: 'id_rsa', usernameVariable: 'eks')]) {
                    sh'''
                    sudo ssh -i ${id_rsa} -T -o StrictHostKeyChecking=no ubuntu@<IP_Of_EKS_Cluster_Agent><<EOF
                    pwd
                    ls
                    kubectl version --short --client
                    eksctl create cluster --name=eksdemo1 \
                                        --region=us-east-2 \
                                        --zones=us-east-2a,us-east-2b \
                                        --without-nodegroup
                    eksctl utils associate-iam-oidc-provider \
                        --region us-east-2 \
                        --cluster eksdemo1 \
                        --approve
                    eksctl create nodegroup --cluster=eksdemo1 \
                                        --region=us-east-2 \
                                        --name=eksdemo1-ng-public1 \
                                        --node-type=t3.medium \
                                        --nodes=2 \
                                        --nodes-min=2 \
                                        --nodes-max=4 \
                                        --node-volume-size=20 \
                                        --ssh-access \
                                        --ssh-public-key=kube-demo \
                                        --managed \
                                        --asg-access \
                                        --external-dns-access \
                                        --full-ecr-access \
                                        --appmesh-access \
                                        --alb-ingress-access
                    eksctl get cluster
                    kubectl get nodes -o wide
                    kubectl apply -f deploysvc.yml
                    '''
                }
                slackSend channel: 'deployment', message: 'Cluster And Nodegroup Created Successfully, And Spring Boot Application Deployed On K8S Cluster'
            }
        }
    }
    post{
        always{
            echo "Production Enviroment EKS Spring Boot Application Deployment Pipeline"
        }
        success{
            slackSend channel: 'deployment', message: 'Pipeline Executed Successfully'
        }
        failure{
            slackSend channel: 'deployment', message: 'Pipeline Failed to Execute'
        }
    }
}

