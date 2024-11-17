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
        API_TARGET_STAGE = "dev"

        NGINX_IMAGE_NAME = "santiagopereyramarchetti/nginx:1.2"
        NGINX_DOCKERFILE_PATH = "./docker/nginx/Dockerfile.nginx"
        NGINX_CONTAINER_NAME = "nginx"

        FRONTEND_IMAGE_NAME = "santiagopereyramarchetti/frontend:1.2"
        FRONTEND_DOCKERFILE_PATH = "./docker/vue/Dockerfile.vue"
        FRONTEND_TARGET_STAGE = "prod"
        FRONTEND_CONTAINER_NAME = "frontend"

        PROXY_IMAGE_NAME = "santiagopereyramarchetti/proxy:1.2"
        PROXY_DOCKERFILE_PATH = "./docker/proxy/Dockerfile.proxy"
        PROXY_TARGET_STAGE = "prod"
        PROXY_CONTAINER_NAME = "proxy"

        REDIS_IMAGE_NAME = "redis:7-alpine"
        REDIS_CONTAINER_NAME = "redis"

        DB_CONNECTION = "mysql"
        DB_HOST = "mysql"
        DB_PORT = "3306"
        DB_NAME = "backend"
        DB_USER = "backend"
        DB_PASSWORD = "password"

        MAX_WAIT=120
        WAIT_INTERVAL=10

        dockerHubCredentials = 'dockerhub'

        REMOTE_HOST = 'vagrant@192.168.10.50'
        LARAVEL_ENV = credentials('laravel-env')
    }

    stages{
        stage('Buildeando images'){
            steps{
                script{
                    docker.build(MYSQL_IMAGE_NAME, "-f ${MYSQL_DOCKERFILE_PATH} --no-cache .")
                    docker.build(API_IMAGE_NAME, "-f ${API_DOCKERFILE_PATH} --no-cache --target ${API_TARGET_STAGE} .")
                    docker.build(NGINX_IMAGE_NAME, "-f ${NGINX_DOCKERFILE_PATH} --no-cache .")
                    docker.build(FRONTEND_IMAGE_NAME, "-f ${FRONTEND_DOCKERFILE_PATH} --no-cache --target ${FRONTEND_TARGET_STAGE} .")
                    docker.build(PROXY_IMAGE_NAME, "-f ${PROXY_DOCKERFILE_PATH} --no-cache --target ${PROXY_TARGET_STAGE} .")
                }
            }
        }
        stage('Preparando environment para la pipeline'){
            steps{
                script{
                   sh '''
                        cd ./backend
                        cp .env.example .env
                        sed -i "/DB_CONNECTION=sqlite/c\\DB_CONNECTION=${DB_CONNECTION}" "./.env"
                        sed -i "/# DB_HOST=127.0.0.1/c\\DB_HOST=${DB_HOST}" "./.env"
                        sed -i "/# DB_PORT=3306/c\\DB_PORT=${DB_PORT}" "./.env"
                        sed -i "/# DB_DATABASE=laravel/c\\DB_DATABASE=${DB_NAME}" "./.env"
                        sed -i "/# DB_USERNAME=root/c\\DB_USERNAME=${DB_USER}" "./.env"
                        sed -i "/# DB_PASSWORD=/c\\DB_PASSWORD=${DB_PASSWORD}" "./.env"
                        cd ..
                    '''
                    sh 'docker network create my_app'

                    sh 'docker run -d -e MYSQL_ROOT_PASSWORD=password --name ${MYSQL_CONTAINER_NAME} --network my_app ${MYSQL_IMAGE_NAME}'

                    sh 'docker run -d --name ${REDIS_CONTAINER_NAME} --network my_app ${REDIS_IMAGE_NAME}'
                    
                    sh 'docker run -d --name ${API_CONTAINER_NAME} --network my_app ${API_IMAGE_NAME}'

                    sh '''
                        start_time=$(date +%s)

                        while true; do
                            # Intentar conectarse al MySQL en el contenedor
                            if docker exec ${MYSQL_CONTAINER_NAME} mysql -u"${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
                                echo "MySQL está listo para aceptar conexiones."
                                break
                            else
                                echo "MySQL no está listo aún, esperando..."
                            fi

                            ## Verificar si se ha excedido el tiempo de espera máximo
                            current_time=$(date +%s)
                            elapsed_time=$((current_time - start_time))

                            if [ "$elapsed_time" -ge "${MAX_WAIT}" ]; then
                                echo "Se agotó el tiempo de espera. MySQL no está listo."
                                exit 1
                            fi

                            # Esperar antes de volver a intentar
                            sleep "${WAIT_INTERVAL}"
                        done
                    '''

                    sh '''
                        docker exec ${API_CONTAINER_NAME} php artisan key:generate
                        docker exec ${API_CONTAINER_NAME} php artisan storage:link
                        docker exec ${API_CONTAINER_NAME} php artisan migrate --force
                    '''
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
                        '''
                    }
                }
            }
        }
        stage('Deployando nueva release'){
            steps{
                sshagent(credentials: ['vps-docker']){
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_HOST} 'rm -f /tmp/.env'
                        
                        scp -o StrictHostKeyChecking=no ${LARAVEL_ENV} ${REMOTE_HOST}:/tmp/.env
                        scp -o StrictHostKeyChecking=no ./docker/jenkins/deploy.sh ${REMOTE_HOST}:/tmp/deploy.sh
                        
                        ssh -o StrictHostKeyChecking=no ${REMOTE_HOST} "bash /tmp/deploy.sh '${MYSQL_ROOT_PASSWORD}' \
                        '${DB_USER}' \
                        '${DB_PASSWORD}' \
                        '${MAX_WAIT}' \
                        '${WAIT_INTERVAL}' \
                        '${MYSQL_IMAGE_NAME}' \
                        '${MYSQL_CONTAINER_NAME}' \
                        '${API_IMAGE_NAME}' \
                        '${API_CONTAINER_NAME}' \
                        '${NGINX_IMAGE_NAME}' \
                        '${NGINX_CONTAINER_NAME}' \
                        '${FRONTEND_IMAGE_NAME}' \
                        '${FRONTEND_CONTAINER_NAME}' \
                        '${PROXY_IMAGE_NAME}' \
                        '${PROXY_CONTAINER_NAME}' \
                        '${REDIS_IMAGE_NAME}' \
                        '${REDIS_CONTAINER_NAME}'"
                    '''
                }
            }
        }


    }

    post{
        always{
            script{
                sh 'docker stop ${API_CONTAINER_NAME} || true'
                sh 'docker stop ${MYSQL_CONTAINER_NAME} || true'
                sh 'docker stop ${REDIS_CONTAINER_NAME} || true'
                sh 'docker stop ${FRONTEND_CONTAINER_NAME} || true'
                sh 'docker stop ${PROXY_CONTAINER_NAME} || true'

                sh 'docker rm -f ${API_CONTAINER_NAME} || true'
                sh 'docker rm -f ${MYSQL_CONTAINER_NAME} || true'
                sh 'docker rm -f ${REDIS_CONTAINER_NAME} || true'
                sh 'docker rm -f ${FRONTEND_CONTAINER_NAME} || true'
                sh 'docker rm -f ${PROXY_CONTAINER_NAME} || true'

                sh 'docker rmi -f ${API_IMAGE_NAME} || true'
                sh 'docker rmi -f ${MYSQL_IMAGE_NAME} || true'
                sh 'docker rmi -f ${REDIS_IMAGE_NAME} || true'
                sh 'docker rmi -f ${FRONTEND_IMAGE_NAME} || true'
                sh 'docker rmi -f ${PROXY_IMAGE_NAME} || true'

                sh 'docker network rm my_app || true'
            }
        }
    }
}