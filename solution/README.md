
Instructions
===

Steps to be taken as per the csvserver assignment.

---

## Part I

1. Run the container image `infracloudio/csvserver:latest` in background and check if it's running.

```sh

# Run the container in the background
$ docker run -d infracloudio/csvserver:latest

# Check the status of the container
$ docker ps -a

CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS                      PORTS     NAMES
bb0393585613   infracloudio/csvserver:latest   "/csvserver/csvserver"   19 seconds ago   Exited (1) 16 seconds ago             awesome_archimedes

```

> Status - Exited (1) 16 seconds ago (not Running)


2. If it's failing then try to find the reason, once you find the reason, move to the next step.

```sh

# Check the container logs using container id from last step (step 1)
$ docker logs bb0393585613

2022/05/25 16:27:44 error while reading the file "/csvserver/inputdata": open /csvserver/inputdata: no such file or directory

```

3. Write a bash script `gencsv.sh` to generate a file named inputFile

```sh
#!/bin/bash

N="${1:-10}" # Default value for entries is 10

for (( i=0; i<$N; i++ )); do echo "$i, $(( $RANDOM % 100000 + 1 ))"; done > inputFile

```

4. Run the container again in the background with file generated in (3) available inside the container (remember the reason you found in (2)).

```sh
$ docker run -v `pwd`/inputFile:/csvserver/inputdata -d infracloudio/csvserver:latest

$ docker ps

CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS          PORTS      NAMES
ee65bf7c86fe   infracloudio/csvserver:latest   "/csvserver/csvserver"   49 seconds ago   Up 47 seconds   9300/tcp   youthful_mirzakhani

```

> Found Port  - `9300/tcp`

5. Get shell access to the container and find the port on which the application is listening. Once done, stop / delete the running container.

```sh

# Login to the container shell using id (from step 4)
$ docker exec -it ee65bf7c86fe bash

[root@ee65bf7c86fe csvserver]# netstat -nltup

Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp6       0      0 :::9300                 :::*                    LISTEN      1/csvserver
```

> Program - `csvserver` is running on port `9300`

> we can also use `docker inspect <container-id/name>` to check ports

Stop / delete the running container.

```sh

# Stop the container by using id/name (from step 4)
$ docker stop ee65bf7c86fe

# Delete the container by using id/name (from step 4)
$ docker rm ee65bf7c86fe
```

6. Same as (4), run the container and make sure,
  - The application is accessible on the host at http://localhost:9393
  - Set the environment variable `CSVSERVER_BORDER` to have value `Orange`.

```sh

$ docker run -v `pwd`/inputFile:/csvserver/inputdata -p 127.0.0.1:9393:9300 -e CSVSERVER_BORDER=Orange -d infracloudio/csvserver:latest

$ docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED         STATUS         PORTS                      NAMES
7acbd7277f84   infracloudio/csvserver:latest   "/csvserver/csvserver"   4 seconds ago   Up 3 seconds   127.0.0.1:9393->9300/tcp   pedantic_morse
```

```sh

# check the endpoint
curl -I http://localhost:9393

HTTP/1.1 200 OK
Date: Wed, 25 May 2022 17:21:47 GMT
Content-Length: 655
Content-Type: text/html; charset=utf-8
```

Open in web browser - http://localhost:9393

![Screenshot - Part-1 Result](https://github.com/j4w3d/infracloudio-csvserver/blob/main/solution/screenshots/Screenshot-part-1-result.png)

---

## Part II

0. Delete any containers running from the last part.

```sh

# Stop all the containers using image `infracloudio/csvserver:latest`
$ docker stop $(docker ps | grep "infracloudio/csvserver:latest" | awk '{ print $1 }' )

# Remove all the containers using image `infracloudio/csvserver:latest`
$ docker rm $(docker ps -a| grep "infracloudio/csvserver:latest" | awk '{ print $1 }' )
```

1. Create a `docker-compose.yaml` file for the setup from part I.

```yaml

version: '3.3'
services:
  csvserver_app:
    image: infracloudio/csvserver:latest
    container_name: csvserver_app
    environment:
      - CSVSERVER_BORDER=Orange
    ports:
      - "127.0.0.1:9393:9300"
    volumes:
      - "./inputFile:/csvserver/inputdata"
    restart: unless-stopped
```


2. One should be able to run the application with `docker-compose up`.

```sh

$ docker-compose up

[+] Running 2/2
 ⠿ Network solution_default  Created                                                                                                             0.1s
 ⠿ Container csvserver_app   Created                                                                                                             0.2s
Attaching to csvserver_app
csvserver_app  | 2022/05/25 18:01:30 listening on ****

```

---

## Part III

0. Delete any containers running from the last part.

```sh

# Remove all the containers using image `infracloudio/csvserver:latest`
$ docker rm $(docker ps -a| grep "infracloudio/csvserver:latest" | awk '{ print $1 }' )
```

1. Add Prometheus container (`prom/prometheus:v2.22.0`) to the `docker-compose.yaml` form part II.

```yaml
version: '3.3'
services:
...
...
  prometheus_app:
    image: prom/prometheus:v2.22.0
    container_name: prometheus_app
    command: ["--web.enable-lifecycle", "--config.file=/etc/prometheus/prometheus.yml", "--log.level=debug"]
    ports:
      - 9090:9090
    volumes:
      - "./prometheus.yml:/etc/prometheus/prometheus.yml"
    restart: unless-stopped

```

> using `--web.enable-lifecycle` we can reload configuration files (e.g. rules) without restarting Prometheus

2. Configure Prometheus to collect data from our application at <application>:<port>/metrics endpoint. (Where the <port> is the port from I.5)

```yaml

# prometheus.yml

global:
  scrape_interval: 30s
  scrape_timeout: 10s

scrape_configs:
  - job_name: services
    metrics_path: /metrics
    static_configs:
      - targets:
          - 'prometheus_app:9090'
          - 'csvserver_app:9300'

```

3. Make sure that Prometheus is accessible at http://localhost:9090 on the host.

> Already published the port `9090` in `docker-compose.yaml` file

![Screenshot - Part 3 result - prometheus targets](https://github.com/j4w3d/infracloudio-csvserver/blob/main/solution/screenshots/Screenshot-part-3-prometheus-targets.png)

4. Type `csvserver_records` in the query box of Prometheus. Click on `Execute` and then switch to the `Graph` tab.

![Screenshot - Part 3 - prometheus query result](https://github.com/j4w3d/infracloudio-csvserver/blob/main/solution/screenshots/Screenshot-part-3-prometheus-query-result.png)

The Prometheus instance should be accessible at http://localhost:9090, and it should show a straight line graph with value 10 (consider shrinking the time range to 5m).

![Screenshot - Part 3 - prometheus graph](https://github.com/j4w3d/infracloudio-csvserver/blob/main/solution/screenshots/Screenshot-part-3-prometheus-graph.png)

---
