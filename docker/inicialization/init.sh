#!/bin/sh

start_time=$(date +%s)

while true; do
    # Intentar conectarse al MySQL en el contenedor
    if docker exec $MYSQL_CONTAINER_NAME mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "MySQL está listo para aceptar conexiones."
        break
    else
        echo "MySQL no está listo aún, esperando..."
    fi

    # Verificar si se ha excedido el tiempo de espera máximo
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ "$elapsed_time" -ge "$MAX_WAIT" ]; then
        echo "Se agotó el tiempo de espera. MySQL no está listo."
        exit 1
    fi

    # Esperar antes de volver a intentar
    sleep "$WAIT_INTERVAL"
done

if [ "$mode" == "prod" ]; then
  docker exec $API_CONTAINER_NAME php artisan key:generate
  docker exec $API_CONTAINER_NAME php artisan storage:link
  docker exec $API_CONTAINER_NAME php artisan optimize:clear
  docker exec $API_CONTAINER_NAME php artisan down
  docker exec $API_CONTAINER_NAME php artisan migrate --force
  docker exec $API_CONTAINER_NAME php artisan config:cache
  docker exec $API_CONTAINER_NAME php artisan route:cache
  docker exec $API_CONTAINER_NAME php artisan view:cache
  docker exec $API_CONTAINER_NAME php artisan up
elif [ "$mode" == "dev" ]; then
  docker exec $API_CONTAINER_NAME php artisan down
  docker exec $API_CONTAINER_NAME php artisan storage:link
  docker exec $API_CONTAINER_NAME php artisan migrate --force
  docker exec $API_CONTAINER_NAME php artisan up
fi