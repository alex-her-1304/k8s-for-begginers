## Objetivo:

Comprender como usar comandos basicos de helm.

Comprender como crear un chart desde cero.

Comprender como modificar templates y values de un chart.

Comprender como usar imagenes, variables de entorno y comandos en deployments.

Links:

https://helm.sh/docs/helm/helm_create/ 

https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/ 

## Descripción tarea:

Utilizando helm create crear un chart y modificar la imagen en el values para que utilice alpine.

Se debe modificar el deployment en la carpeta templates para que reciba variables de entorno desde el values.

Luego se debe configurar el siguiente comando en el values donde MENSAJE es una variable de entorno del sistema:

echo $MENSAJE & sleep 1000

## Desarrollo de tareas:

### Como utilizar variables de entorno en un pod
```bash
╰─➤  cat envar-demo-pod3.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: dnstool2
  labels:
    app: dnstool
spec:
  containers:
  - name: dnstool
    image: nicolaka/netshoot:latest
    env:
    - name: GREETING
      value: "Warm greetings to"
    - name: HONORIFIC
      value: "The Most Honorable"
    - name: NAME
      value: "Kubernetes"
    - name: MESSAGE
      value: "$(GREETING) $(HONORIFIC) $(NAME)"
    command: ["echo"]
    args: ["$(MESSAGE)"]%
╰─➤  k apply -f envar-demo-pod3.yaml        
pod/dnstool2 created
╰─➤  k logs dnstool2                
Warm greetings to The Most Honorable Kubernetes
```

### Creación de un chart
Se seguirán los siguientes pasos:
https://helm.sh/docs/chart_template_guide/getting_started/


templates/NOTES.txt: The "help text" for your chart. This will be displayed to your users when they run helm install.
templates/deployment.yaml: A basic manifest for creating a Kubernetes deployment
templates/service.yaml: A basic manifest for creating a service endpoint for your deployment
templates/_helpers.tpl: A place to put template helpers that you can reuse throughout the chart

```bash
╰─➤  helm create first-chart                                                            
Creating first-chart
╰─➤  tree first-chart 
first-chart
├── charts
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── NOTES.txt
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml
# para seguir con la guia vamos a borrar templates/*
╰─➤  rm -rf first-chart/templates/*
╰─➤  cd first-chart/templates 
╰─➤  pbpaste > configmap.yaml      
╰─➤  cd ../..
```



templates/configmap.yaml,
El archivo YAML anterior es un ConfigMap básico, con los campos mínimos necesarios. Dado que este archivo se encuentra en el directorio mychart/templates/, se enviará a través del template engine: 

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"
```

Cada archivo comienza con --- para indicar el inicio de un documento YAML

```bash
╰─➤  helm install full-coral ./first-chart 
NAME: full-coral
LAST DEPLOYED: Mon May 19 16:53:16 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
╰─➤  helm get manifest full-coral
---
# Source: first-chart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"
```

Añadiremos un Template Call
```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
```

Una template directive está incluida en {{ and }} blocks.
Un template directive {{ .Release.Name }} inyecta el nombre de la versión en la plantilla.

" .Release.Name" como "comience en el espacio de nombres superior, busque el objeto Release, luego busque dentro de él un objeto llamado Name".

### Built-in Objects
Los objetos (incorporados) se pasan a una plantilla desde el template engine. Y tu código puede pasar objetos entre sí (entencias with y range).
#### TOP-Level Objects:
**Release:** This object describes the release itself. It has several objects inside of it:
- Release.Name: The release name
- Release.Namespace: The namespace to be released into (if the manifest doesn’t override)
- Release.IsUpgrade: This is set to true if the current operation is an upgrade or rollback.
- Release.IsInstall: This is set to true if the current operation is an install.
- Release.Revision: The revision number for this release. On install, this is 1, and it is incremented with each upgrade and rollback.
- Release.Service: The service that is rendering the present template. On Helm, this is always Helm.

**Values:** Values passed into the template from the values.yaml file and from user-supplied files. By default, Values is empty.

**Chart:** The contents of the Chart.yaml file. Any data in Chart.yaml will be accessible here. For example {{ .Chart.Name }}-{{ .Chart.Version }} will print out the mychart-0.1.0.

Others: Subchart/Files/Capabilities/Template

### Como utilizar variables de entorno en un pod - Value Files
```bash
╰─➤  cat first-chart/templates/configmap.yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favoriteDrink }}%

╰─➤  helm install solid-vulture ./first-chart --dry-run --debug --set favoriteDrink=slurm                                                                                       
...
---
# Source: first-chart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: solid-vulture-configmap
data:
  myvalue: "Hello World"
  drink: slurm
```

Notas:
cuando vemos algo como:

  `drink: {{ .Values.favorite.drink  | default "tea" | quote }}`
  `food: {{ .Values.favorite.food | upper | quote }}`

son transformaciones que se aplican a los parametros, en la primer linea estamos agregando comillas dobles y en la segunda ademas de agregar las comillas estamos aplicando mayusculas

  `drink: "coffee"`
  `food: "PIZZA"`

### Configurar un chart para que acepte un value "mensaje"

Se debe configurar el siguiente comando en el values donde MENSAJE es una variable de entorno del sistema:

`echo $MENSAJE & sleep 1000`

Se implementó inicialmente un pod.yaml utilizando dnstool:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnstool
  labels:
    app: dnstool
spec:
  containers:
  - name: dnstool
    image: nicolaka/netshoot:latest
    command: ["/bin/sh"]
    env:
      - name: MENSAJE
        value: {{ .Values.message | default "empty" | upper | quote }}
    args: ['-c', 'echo $MENSAJE', 'sleep 1000']
```

Se desplegó en modo de prueba para ver el manifiesto y corroborar que este todo en correcto, esto se puede hacer de dos formas ya sea utilizando el comando template ó utilizando los flags --dry-run y/o --debug.

La diferencia es que helm template solo renderiza el YAML localmente mientras que helm install --dry-run renderiza el YAML y luego lo envía al API Server de Kubernetes para validarlo contra el estado actual del cluster.

```bash
╰─➤  helm template test-first-chart ./first-chart --set 'message=HOLA MUNDO'
---
# Source: first-chart/templates/deployment.yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnstool
  labels:
    app: dnstool
spec:
  containers:
  - name: dnstool
    image: nicolaka/netshoot:latest
    command: ["/bin/sh"]
    env:
      - name: MENSAJE
        value: "HOLA MUNDO"
    args: ['-c', 'echo $MENSAJE; sleep 1000']

╰─➤  helm install test-first-chart ./first-chart --set 'message=HOLA MUNDO'
NAME: test-first-chart
LAST DEPLOYED: Tue May 20 10:58:50 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

╰─➤  k get pods
NAME      READY   STATUS    RESTARTS   AGE
dnstool   1/1     Running   0          13s

╰─➤  k logs dnstool
HOLA MUNDO
```

Finalmente generamos el deployment:
```bash
╰─➤  cat first-chart/templates/deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dnstool-deployment
  labels:
    app: dnstool
spec:
  selector:
    matchLabels:
      app: dnstool
  replicas: 1
  template:
    metadata:
      name: dnstool
      labels:
        app: dnstool
    spec:
      containers:
      - name: dnstool
        image: nicolaka/netshoot:latest
        command: ["/bin/sh"]
        env:
          - name: MENSAJE
            value: {{ .Values.message | default "empty" | upper | quote }}
        args: ['-c', 'echo $MENSAJE; sleep 1000']% 

╰─➤  helm install test-first-chart ./first-chart --set 'message=HOLA MUNDO DESDE UN DEPLOYMENT'                                                         130 ↵
NAME: test-first-chart
LAST DEPLOYED: Tue May 20 12:11:14 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

╰─➤  k logs dnstool-deployment-75fbf85bfd-jcjcs       
HOLA MUNDO DESDE UN DEPLOYMENT
```
### Troubleshooting

- Si el pod se reinicia muchas veces puede estar mal configurado los parametros, por ejemplo:
```yaml
# definicion del container con error:
  - name: dnstool
    image: nicolaka/netshoot:latest
    command: ["/bin/sh"]
    env:
      - name: MENSAJE
        value: "HOLA MUNDO"
    args: ['-c', 'echo $MENSAJE', 'sleep 1000']
```
El pod ejecutará el comando echo pasando por parametro el mensaje y ademas sleep 1000 lo que hará que el pod termine rapidamente generando errores.

Solucion: 
```yaml
  command: ["/bin/sh"]
  args: ['-c', 'echo $MENSAJE; sleep 1000']
```
el ";" asegura que se ejecuten dos comandos en secuencia.