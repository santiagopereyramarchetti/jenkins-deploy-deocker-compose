pipeline {
    agent any

    triggers {
        pollSCM('H * * * *')
    }

    environment {        
        MYSQL_IMAGE_NAME = "santiagopereyramarchetti/mysql:1.2"
        MYSQL_DOCKERFILE_PATH = "./docker/mysql/Dockerfile.mysql"
        MYSQL_CONTAINER_NAME = "mysql"

        API_IMAGE_NAME = "santiagopereyramarchetti/api:1.2"
        API_DOCKERFILE_PATH = "./docker/laravel/Dockerfile.laravel"
        API_CONTAINER_NAME = "api"

        NGINX_IMAGE_NAME = "santiagopereyramarchetti/nginx:1.2"
        NGINX_DOCKERFILE_PATH = "./docker/nginx/Dockerfile.nginx"
        NGINX_CONTAINER_NAME = "nginx"

        FRONTEND_IMAGE_NAME = "santiagopereyramarchetti/frontend:1.2"
        FRONTEND_DOCKERFILE_PATH = "./docker/vue/Dockerfile.vue"
        FRONTEND_CONTAINER_NAME = "frontend"

        PROXY_IMAGE_NAME = "santiagopereyramarchetti/proxy:1.2"
        PROXY_DOCKERFILE_PATH = "./docker/proxy/Dockerfile.proxy"
        PROXY_CONTAINER_NAME = "proxy"

        INICIALIZATION_IMAGE_NAME = "santiagopereyramarchetti/inicialization:1.2"
        INICIALIZATION_DOCKERFILE_PATH = "./docker/inicialization/Dockerfile"
        INICIALIZATION_CONTAINER_NAME = "inicialization"

        REDIS_IMAGE_NAME = "redis:7-alpine"
        REDIS_CONTAINER_NAME = "redis"

        dockerHubCredentials = 'dockerhub'

        REMOTE_HOST = 'vagrant@192.168.10.50'
        LARAVEL_ENV = credentials('laravel-env')
        MYSQL_ENV = credentials('mysql-env')
        INIT_ENV = credentials('ini-env')

    }

    stages{
        stage('Buildeando images para testing'){
            steps{
                script{
                    sh 'docker compose -f docker-compose.ci.yml build --no-cache'
                }
            }
        }
        stage('Preparando environment para la pipeline'){
            steps{
                script{
                    writeFile file: '.env', text: readFile(LARAVEL_ENV)
                    writeFile file: '.env.mysql', text: readFile(MYSQL_ENV)
                    writeFile file: '.env.ini', text: readFile(INIT_ENV)
                    sh 'docker compose -f docker-compose.ci.yml up -d'
                    sh 'docker wait inicialization'
                }
            }
        }
        stage('Analisis de código estático'){
            steps{
                script{
                   sh 'docker exec ${API_CONTAINER_NAME} ./vendor/bin/phpstan analyse'
                }
            }
        }
        stage('Analisis de la calidad del código'){
            steps{
                script{
                    def userInput = input(
                        message: 'Ejecutar este step?',
                        parameters: [
                            choice(name: 'Selecciona una opcion', choices: ['Si', 'No'], description: 'Elegir si queres ejecutar este step')    
                        ]
                    )
                    if (userInput == 'Si'){
                        sh 'docker exec ${API_CONTAINER_NAME} php artisan insights --no-interaction --min-quality=90 --min-complexity=90 --min-architecture=90 --min-style=90'
                    } else {
                        echo 'Step omitido. Siguiendo adelante...'
                    }
                }
            }
        }
        stage('Tests unitarios'){
            steps{
                script{
                   sh 'docker exec ${API_CONTAINER_NAME} php artisan test'
                }
            }
        }
        stage('Buildeando images para prod'){
            steps{
                script{
                    sh 'docker compose -f docker-compose.ci.prod.yml build --no-cache api'
                }
            }
        }
        stage('Pusheando images hacia Dockerhub'){
            steps{
                script{
                    withCredentials([usernamePassword(credentialsId: dockerHubCredentials, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
 
                        sh '''
                            docker push ${MYSQL_IMAGE_NAME}
                            docker push ${API_IMAGE_NAME}
                            docker push ${NGINX_IMAGE_NAME}
                            docker push ${FRONTEND_IMAGE_NAME}
                            docker push ${PROXY_IMAGE_NAME}
                            docker push ${INICIALIZATION_IMAGE_NAME}
                        '''
                    }
                }
            }
        }
        stage('Deployando nueva release'){
            steps{
                sshagent(credentials: ['onpremise-vps']){
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_HOST} 'rm -rf ~/.env && rm -rf ~/.env.mysql && rm -rf ~/.env.ini && rm -rf ~/docker-compose.yml'
    
                        scp -o StrictHostKeyChecking=no ${LARAVEL_ENV} ${REMOTE_HOST}:~/.env
                        scp -o StrictHostKeyChecking=no ${MYSQL_ENV} ${REMOTE_HOST}:~/.env.mysql
                        scp -o StrictHostKeyChecking=no ${INIT_ENV} ${REMOTE_HOST}:~/.env.ini
                        scp -o StrictHostKeyChecking=no ./docker-compose.prod.yml ${REMOTE_HOST}:~/docker-compose.yml
    
                        ssh -o StrictHostKeyChecking=no ${REMOTE_HOST} "export MYSQL_IMAGE_NAME='${MYSQL_IMAGE_NAME}' \
                            export MYSQL_CONTAINER_NAME='${MYSQL_CONTAINER_NAME}' \
                            export API_IMAGE_NAME='${API_IMAGE_NAME}' \
                            export API_CONTAINER_NAME='${API_CONTAINER_NAME}' \
                            export NGINX_IMAGE_NAME='${NGINX_IMAGE_NAME}' \
                            export NGINX_CONTAINER_NAME='${NGINX_CONTAINER_NAME}' \
                            export FRONTEND_IMAGE_NAME='${FRONTEND_IMAGE_NAME}' \
                            export FRONTEND_CONTAINER_NAME='${FRONTEND_CONTAINER_NAME}' \
                            export PROXY_IMAGE_NAME='${PROXY_IMAGE_NAME}' \
                            export PROXY_CONTAINER_NAME='${PROXY_CONTAINER_NAME}' \
                            export INICIALIZATION_IMAGE_NAME='${INICIALIZATION_IMAGE_NAME}' \
                            export INICIALIZATION_CONTAINER_NAME='${INICIALIZATION_CONTAINER_NAME}' \
                            export REDIS_IMAGE_NAME='${REDIS_IMAGE_NAME}' \
                            export REDIS_CONTAINER_NAME='${REDIS_CONTAINER_NAME}' \
                            && docker compose -f ~/docker-compose.yml up -d"
                    '''
                }
            }
        }


    }

    post{
        always{
            script{
                sh 'docker compose -f docker-compose.prod.yml down -v || true' 
                sh 'docker compose -f docker-compose.ci.yml down -v || true'

                sh 'docker rmi -f ${API_IMAGE_NAME} || true'
                sh 'docker rmi -f ${MYSQL_IMAGE_NAME} || true'
                sh 'docker rmi -f ${REDIS_IMAGE_NAME} || true'
                sh 'docker rmi -f ${FRONTEND_IMAGE_NAME} || true'
                sh 'docker rmi -f ${PROXY_IMAGE_NAME} || true'
                sh 'docker rmi -f ${NGINX_IMAGE_NAME} || true'
                sh 'docker rmi -f ${INICIALIZATION_IMAGE_NAME} || true'

                cleanWs()
            }
        }
    }
}