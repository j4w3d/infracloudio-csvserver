
Instructions
===

Steps to be taken as per the csvserver assignment.

---

## Part 1

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

![Screenshot - Part-1 Result](https://github.com/j4w3d/infracloudio-csvserver/blob/main/solution/part-1-result.png)

---

## Part 2