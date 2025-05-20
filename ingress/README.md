# Habilitar ingress para grafana
## Objetivo:

- Comprender como usar comandos basicos de helm.
- Aprender a validar que la tarea realmente está terminada.
- Revisar recursos de un chart con recursos deployados en el cluster.
- Entender uso de grafana.
- Comprender que es un ingress.
- Comprender como modificar un values para habilitar y configurar un template.
- Comprender como configurar archivos de sistema operativo.

Links:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack 
https://github.com/grafana/helm-charts/blob/main/charts/grafana/ 
https://github.com/grafana/helm-charts/blob/main/charts/grafana/templates/ingress.yaml 

## Descripción tarea:

Utilizando helm upgrade modificar el values del chart de kube-prometheus-stack para habilitar y configurar el ingress con un host específico como por ejemplo: grafana.craftech.io.

Se debe modificar el archivo /etc/hosts para que al ingresar la url en el navegador redireccione al servicio en el cluster local.

## Teorico
### Que es un ingress? Debe estar en un namespace separado o en el mismo que quiere fowardear el trafico? funciona internamente con la tecnologia de nginx?

Un Ingress es un objeto API que define reglas que permiten el acceso externo a los servicios en un clúster. [doc](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/).

Ejemplo: 
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-aplicacion-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
    - host: mi-dominio.com  # <--- ¡Aquí defines tu dominio!
      http:
        paths:
          - path: /  # Cuando accedan a mi-dominio.com/
            pathType: Prefix
            backend:
              service:
                name: mi-servicio-web  # Se envía a este servicio
                port:
                  number: 80
          - path: /api # Cuando accedan a mi-dominio.com/api
            pathType: Prefix
            backend:
              service:
                name: mi-servicio-api # Se envía a este servicio
                port:
                  number: 8080
    - host: otro-dominio.com # Puedes tener múltiples dominios en un solo Ingress
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: otro-servicio-web
                port:
                  number: 80
  # Opcional: un backend por defecto si ninguna regla coincide
  defaultBackend:
    service:
      name: servicio-default
      port:
        number: 80
```
Este ingress define


Un Ingress no expone puertos ni protocolos arbitrarios. La exposición a internet de servicios distintos de HTTP y HTTPS suele utilizar un servicio de tipo Service.Type=NodePort o Service.Type=LoadBalancer.

El nombre de un objeto Ingress debe ser un DNS subdomain name válido. 
`spec`: tiene toda la información necesaria para configurar un balanceador de carga o un servidor proxy.

Un backend es una combinación de un Service y un puerto. Las peticiones HTTP (y HTTPS) al Ingress que coinciden con el host y la ruta de la regla se envían al backend del listado.

Un `defaultBackend` se configura frecuentemente en un controlador de Ingress para dar servicio a cualquier petición que no coincide con una ruta en la especificación.

Tipos de ruta:
- ImplementationSpecific
- Exact
- Prefix

### Que es un Ingress Controller?  

Cumple las reglas establecidas en el Ingress, podriamos decir que es el motor. No necesariamente tiene que estar en un namespace separado, pero es una buena práctica para mantener el orden. Muchos Ingress Controllers utilizan la tecnología de Nginx como su motor principal, tambien podrian utilizar por ejemplo traefik. doc.

El dominio (por ej mi-dominio.com) se configura ingres utilizando la clave host en rules, luego el Ingress Controller ejecuta la logica trabajando en conjunto con un Load Balancer externo.

### Que es un Ingress Class?
Los Ingress pueden ser implementados por distintos controladores, comúnmente con una configuración distinta. Cada Ingress debería especificar una clase, una referencia a un recurso IngressClass que contiene información adicional incluyendo el nombre del controlador que debería implementar la clase. El alcance por defecto es en todo el clúster, o solamente para un namespace. Puedes marcar un ingressClass en particular por defecto para tu clúster `metadata.annotations:ingressclass.kubernetes.io/is-default-class: "true"`

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: external-lb
spec:
  controller: example.com/ingress-controller
  parameters:
    apiGroup: k8s.example.com
    kind: IngressParameters
    name: external-lb
```

`apiGroup: k8s.example.com` es un "Custom Resource Definition" (CRD).

Uso de varios controladores Ingress: Puedes desplegar cualquier número de controladores Ingress utilizando clase ingress dentro de un clúster. 

## Desarrollo de tareas:

Para configurar en minikube debemos instalar un addon que configura automaticamente un Ingress Controller.

```bash
╰─➤  minikube addons enable ingress                                                                                                                                                     130 ↵
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.11.3
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.4
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.4
🔎  Verifying ingress addon...
minikube addons enable ingress🌟  The 'ingress' addon is enabled

╰─➤  kubectl get pods -n ingress-nginx                                                                                                                                                  130 ↵
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-pcvbl        0/1     Completed   0          2m56s
ingress-nginx-admission-patch-zgxr9         0/1     Completed   0          2m56s
ingress-nginx-controller-56d7c84fd4-s45qn   1/1     Running     0          2m56s

Create/Patch son jobs de kubernetes que realizan tareas finitas.

Como modificar un values para habilitar y configurar un template?

╰─➤  helm upgrade kube-prometeus-stack prometheus-community/kube-prometheus-stack -n dev 
--set 'grafana.ingress.enabled=true' 
--set 'grafana.ingress.hosts[0]=grafana.craftech.io'         

Release "kube-prometeus-stack" has been upgraded. Happy Helming!
NAME: kube-prometeus-stack

# vemos que se ha generado el ingress
╰─➤  kubectl get ingress -n dev
NAME                           CLASS   HOSTS                ADDRESS        PORTS   AGE
kube-prometeus-stack-grafana   nginx   grafana.craftech.io  192.168.49.2   80      118s

# podemos hacer una prueba rapida para ver si funciona
╰─➤  curl --resolve "grafana.craftech.io:80:$( minikube ip )" -i http://grafana.craftech.io                                                                                                 6 ↵
HTTP/1.1 302 Found
Date: Fri, 16 May 2025 13:57:43 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 29
Connection: keep-alive
Cache-Control: no-store
Location: /login
X-Content-Type-Options: nosniff
X-Frame-Options: deny
X-Xss-Protection: 1; mode=block

<a href="/login">Found</a>.

# modificamos la resolucion de dominio local
╰─➤  cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 agustin-her-ThinkPad-E14-Gen-6
192.168.49.2 grafana.craftech.io
```

podemos intentar acceder ahora desde el navegador y ver los resultados http://grafana.craftech.io/login

Como observacion vemos que al intentar acceder directamente desde la ip http://192.168.49.2 no funciona ya que el proxy inverso solo permite acceder mediante el dominio de la petición HTTP.


## ¿qué es un IngressClass? ¿cómo se definió en tu implementación de grafana?

Entiendo que un Ingress Class es el manifiesto que apunta al Ingress Controller, entonces en un Ingress lo que  haces es especificar el nombre de el class (y si no lo especificas se usa el class que esta configurado por defecto) y el class te dice cual controlador va a resolver el manifiesto. 

En minikube se activó la extension de ingress, lo que hace es crear unos pods, entre ellos el controller, y ademas depliega el ingress class que apunta a spec:controller: k8s.io/ingress-nginx, esta configurado por defecto y su nombre es nginx

```bash
╰─➤  kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-v59rr        0/1     Completed   0          13m
ingress-nginx-admission-patch-l592m         0/1     Completed   0          13m
ingress-nginx-controller-56d7c84fd4-s5srp   1/1     Running     0          13m

╰─➤  k get ingressClass               
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       13m

╰─➤  k get ingressClass nginx -o yaml                                                                                                                     1 ↵
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.k8s.io/v1","kind":"IngressClass","metadata":{"annotations":{"ingressclass.kubernetes.io/is-default-class":"true"},"labels":{"app.kubernetes.io/component":"controller","app.kubernetes.io/instance":"ingress-nginx","app.kubernetes.io/name":"ingress-nginx"},"name":"nginx"},"spec":{"controller":"k8s.io/ingress-nginx"}}
  creationTimestamp: "2025-05-20T19:09:27Z"
  generation: 1
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  name: nginx
  resourceVersion: "20728"
  uid: efb6f4ce-d66d-4ee5-ada7-03c0f4ff513e
spec:
  controller: k8s.io/ingress-nginx
```