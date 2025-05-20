# Modificar el chart para que use secrets

## Objetivo:
Comprender como usar comandos basicos de helm.

Comprender como crear un chart desde cero.

Comprender como crear un template desde cero.

Comprender que son los secrets en kubernetes.

Comprender como asociar un secret a un deployment.

Links:
[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) 

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#use-case-as-container-environment-variables) 

## Descripción tarea:
Utilizando el chart creado anteriormente agregar un template de un recurso del tipo secret para guardar las variables de entorno. El secret se debe poder habilitar o deshabilitar desde el values y cargar las variables de entorno desde aqui.

Además se debe asociar al deployment para que este lo utilice.

### Consultas
que son los ConfigMaps en kubernetes ?
Un ConfigMap es un API object que se utiliza para almacenar datos no confidenciales en pares clave-valor. Los pods pueden usar ConfigMaps como variables de entorno, argumentos de línea de comandos o archivos de configuración en un volumen. No provee encripcion ni seguridad adicional (para esto se utilizan secrets). Permite establecer datos de configuracion separado del codigo de la aplicacion.


Hay cuatro maneras diferentes de usar un ConfigMap para configurar un contenedor dentro de un Pod:

- Argumento en la linea de comandos como entrypoint de un contenedor
- Variable de entorno de un contenedor
- Como fichero en un volumen de solo lectura, para que lo lea la aplicación
- Escribir el código para ejecutar dentro de un Pod que utiliza la API para leer el ConfigMap

Ejemplo de un ConfigMap:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
data:
  # property-like keys; each key maps to a simple value
  player_initial_lives: "3"

  # file-like keys
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
```

Luego en los manifiestos podemos llamar a estas variables de la siguiente forma:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo-pod
spec:
  containers:
    - name: demo
      image: alpine
      command: ["sleep", "3600"]
      env:
        # Define the environment variable
        - name: PLAYER_INITIAL_LIVES # Notice that the case is different here
                                     # from the key name in the ConfigMap.
          valueFrom:
            configMapKeyRef:
              name: game-demo           # The ConfigMap this value comes from.
              key: player_initial_lives # The key to fetch.
      volumeMounts:
      - name: config
        mountPath: "/config"
        readOnly: true
  volumes:
  # You set volumes at the Pod level, then mount them into containers inside that Pod
  - name: config
    configMap:
      # Provide the name of the ConfigMap you want to mount.
      name: game-demo
      # An array of keys from the ConfigMap to create as files
      items:
      - key: "game.properties"
        path: "game.properties"
```        

Otros usos que se le puede dar a este objeto es como como ficheros en un Pod: Cada clave del ConfigMap data se convierte en un un fichero en el mountPath.

que son los Secrets en kubernetes ? 
Los objetos de tipo Secret permiten almacenar y administrar información confidencial, como contraseñas, tokens OAuth y llaves ssh. Más seguro y más flexible que ponerlo en la definición de un Pod o en un container image. Pueden ser creados de forma independiente pudiendose definir estos secrets como de solo lectura.

Por defecto se almacenan los secrets sin cifrado en el API server subyascente (etcd). Cualquiera con acceso a la API podria por lo tanto modificar/acceder a los secrets. Cualquiera con acceso a crear un Pod en un namespace podria acceder (ro) a cualquier sercret en ese namespace. Considerando esto es recomendable:
- Enable Encryption at Rest for Secrets.
- Enable or configure RBAC rules with least-privilege access to Secrets.
- Restrict Secret access to specific containers.
- Consider using external Secret store providers.

```bash
╰─➤  cat first-chart-secrets/templates/deployment.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: secret-dotfiles-pod
spec:
  volumes:
    - name: secret-volume
      secret:
        secretName: dotfile-secret
  containers:
    - name: dotfile-test-container
      image: busybox:latest
      command:
        - ls
        - "-la"
        - "/etc/secret-volume"
      volumeMounts:
        - name: secret-volume
          readOnly: true
          mountPath: "/etc/secret-volume"      
╰─➤  cat first-chart-secrets/templates/secret.yaml 
apiVersion: v1
kind: Secret
metadata:
  name: dotfile-secret
data:
  .secret-file: dmFsdWUtMg0KDQo=% 

╰─➤  helm install secret first-chart-secrets
NAME: secret
LAST DEPLOYED: Tue May 20 12:49:45 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

╰─➤  k logs secret-dotfiles-pod  
total 4
drwxrwxrwt    3 root     root           100 May 20 15:52 .
drwxr-xr-x    1 root     root          4096 May 20 15:53 ..
drwxr-xr-x    2 root     root            60 May 20 15:52 ..2025_05_20_15_52_55.1550964928
lrwxrwxrwx    1 root     root            32 May 20 15:52 ..data -> ..2025_05_20_15_52_55.1550964928
lrwxrwxrwx    1 root     root            19 May 20 15:52 .secret-file -> ..data/.secret-file
╰─➤  echo "dmFsdWUtMg0KDQo=" | base64 --decode
value-2
```

Podemos ver que se ha creado un volumen en el path `/etc/secret-volume` que tiene un enlace simbolico `.secret-file` a ..data/.secret-file donde este archivo tiene la referencia a la version mas nueva del secret `dmFsdWUtMg0KDQo=` (codificado en base64).

`..data`: directorio intermedio a la versión activa de los datos del Secret. Inicialmente, ..data apunta al directorio con la version actual.
`..2025_05_20_15_52_55.1550964928`: Dentro de este directorio es donde se escribe la versión actual y real de los datos del Secret.

Esto se debe a cómo Kubernetes maneja las actualizaciones atómicas de Secrets y ConfigMaps; los monta en directorios temporales y luego crea enlaces simbólicos a la versión activa, para que los pods no necesiten reiniciarse cuando se actualizan.


| Tipo Integrado                       | Uso                                             |
| :----------------------------------- | :---------------------------------------------- |
| `Opaque`                             | Datos arbitrarios definidos por el usuario      |
| `kubernetes.io/service-account-token` | Token de ServiceAccount                         |
| `kubernetes.io/dockercfg`            | Archivo `~/.docker/config` serializado         |
| `kubernetes.io/dockerconfigjson`     | Archivo `~/.docker/config.json` serializado    |
| `kubernetes.io/basic-auth`           | Credenciales para autenticación básica          |
| `kubernetes.io/ssh-auth`             | Credenciales para autenticación SSH             |
| `kubernetes.io/tls`                  | Datos para un cliente o servidor TLS            |
| `bootstrap.kubernetes.io/token`      | Datos de token de arranque (`bootstrap token`)  |

`kubernetes.io/service-account-token`: Es el único tipo de Secret que Kubernetes crea y gestiona de forma nativa para permitir la comunicación segura de los pods con el plano de control de Kubernetes. No lo creas manualmente.


Para una seguridad de nivel superior, considera soluciones como Kubernetes External Secrets, HashiCorp Vault, o AWS Secrets Manager/Parameter Store (con integraciones) para almacenar y gestionar tus secretos fuera del clúster y solo inyectarlos en el momento de la ejecución.

Todas las secrets dentro de data (en el manifiesto) deben estar en base64, caso contrario la API devuelve un error. Si creamos el secret desde el cli, kubectl se encarga de pasarlo a base64.

```
╰─➤  kubectl create secret docker-registry secret-tiger-docker \
  --docker-email=tiger@acme.example \
  --docker-username=tiger \
  --docker-password=pass1234 \
  --docker-server=my-registry.example:5000
secret/secret-tiger-docker created

╰─➤  kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}'
eyJhdXRocyI6eyJteS1yZWdpc3RyeS5leGFtcGxlOjUwMDAiOnsidXNlcm5hbWUiOiJ0aWdlciIsInBhc3N3b3JkIjoicGFzczEyMzQiLCJlbWFpbCI6InRpZ2VyQGFjbWUuZXhhbXBsZSIsImF1dGgiOiJkR2xuWlhJNmNHRnpjekV5TXpRPSJ9fX0=%              

╰─➤  kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}' | base64 -d
{"auths":{"my-registry.example:5000":{"username":"tiger","password":"pass1234","email":"tiger@acme.example","auth":"dGlnZXI6cGFzczEyMzQ="}}}% 
```
## Desarrollo de tareas:


### Troubleshooting
