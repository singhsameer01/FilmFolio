# FilmFolio

The goal of this project is to secure `movies-app` using [`Keycloak`](https://www.keycloak.org/)(with PKCE). `movies-app` consists of two applications: one is a [Spring Boot](https://docs.spring.io/spring-boot/index.html) Rest API called `movies-api` and another is a [React](https://react.dev/) application called `movies-ui`.

## Applications

- ### movies-api

  `Spring Boot` Web Java backend application that exposes a REST API to manage **movies**. Its secured endpoints can just be accessed if an access token (JWT) issued by `Keycloak` is provided.
  
  `movies-api` stores its data in a [`Mongo`](https://www.mongodb.com/) database.

  `movie-api` has the following endpoints:

  | Endpoint                                                          | Secured | Roles                            |
  |-------------------------------------------------------------------|---------|----------------------------------|
  | `GET /api/userextras/me`                                          | Yes     | `MOVIES_ADMIN` and `MOVIES_USER` |
  | `POST /api/userextras/me -d {avatar}`                             | Yes     | `MOVIES_ADMIN` and `MOVIES_USER` | 
  | `GET /api/movies`                                                 | No      |                                  |
  | `GET /api/movies/{imdbId}`                                        | No      |                                  |
  | `POST /api/movies -d {"imdb","title","director","year","poster"}` | Yes     | `MOVIES_ADMIN`                   |
  | `DELETE /api/movies/{imdbId}`                                     | Yes     | `MOVIES_ADMIN`                   |
  | `POST /api/movies/{imdbId}/comments -d {"text"}`                  | Yes     | `MOVIES_ADMIN` and `MOVIES_USER` |

- ### movies-ui

  `React` frontend application where `users` can see and comment movies and `admins` can manage movies. To access the application, `user` / `admin` must login using his/her username and password. Those credentials are managed by `Keycloak`. All the requests from `movies-ui` to secured endpoints in `movies-api` include an access token (JWT) that is generated when `user` / `admin` logs in.
  
  `movies-ui` uses [`Semantic UI React`](https://react.semantic-ui.com/) as CSS-styled framework.

## Prerequisites

- [`Java 21`](https://www.oracle.com/java/technologies/downloads/#java21) or higher;
- [`npm`](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- A containerization tool (e.g., [`Docker`](https://www.docker.com), [`Podman`](https://podman.io), etc.)
- [`jq`](https://jqlang.github.io/jq/)
- [`OMDb API`](https://www.omdbapi.com/) KEY

  To use the `Wizard` option to search and add a movie, we need to get an API KEY from OMDb API. To do this, access https://www.omdbapi.com/apikey.aspx and follow the steps provided by the website.

  Once we have the API KEY, create a file called `.env.local` in the `springboot-react-keycloak/movies-ui` folder with the following content:
  ```text
  REACT_APP_OMDB_API_KEY=<your-api-key>
  ```

## PKCE

As `Keycloak` supports [`PKCE`](https://datatracker.ietf.org/doc/html/rfc7636) (`Proof Key for Code Exchange`) since version `7.0.0`, we are using it in this project. 

## Start Environment

In a terminal, navigate to the `springboot-react-keycloak` root folder and run:
```bash
./init-environment.sh
```

## Initialize Keycloak

In a terminal and inside the `springboot-react-keycloak` root folder run:
```bash
./init-keycloak.sh
```

This script will:
- create `company-services` realm;
- disable the required action `Verify Profile`;
- create `movies-app` client;
- create the client role `MOVIES_USER` for the `movies-app` client;
- create the client role `MOVIES_ADMIN` for the `movies-app` client;
- create `USERS` group;
- create `ADMINS` group;
- add `USERS` group as realm default group;
- assign `MOVIES_USER` client role to `USERS` group;
- assign `MOVIES_USER` and `MOVIES_ADMIN` client roles to `ADMINS` group;
- create `user` user;
- assign `USERS` group to user;
- create `admin` user;
- assign `ADMINS` group to admin.

## Running movies-app using Maven & Npm

- **movies-api**

  - Open a terminal and navigate to the `springboot-react-keycloak/movies-api` folder;

  - Run the following `Maven` command to start the application:
    ```bash
    ./mvnw clean spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=9080"
    ```

- **movies-ui**

  - Open another terminal and navigate to the `springboot-react-keycloak/movies-ui` folder;

  - Run the command below if you are running the application for the first time:
    ```bash
    npm install
    ```

  - Run the `npm` command below to start the application:
    ```bash
    npm start
    ```

## Applications URLs

| Application | URL                                   | Credentials                           |
|-------------|---------------------------------------|---------------------------------------|
| movie-api   | http://localhost:9080/swagger-ui.html | [Access Token](#getting-access-token) |
| movie-ui    | http://localhost:3000                 | `admin/admin` or `user/user`          |
| Keycloak    | http://localhost:8080                 | `admin/admin`                         |

## Testing movies-api endpoints

We can manage movies by directly accessing `movies-api` endpoints using the Swagger website or `curl`. For the secured endpoints like `POST /api/movies`, `PUT /api/movies/{id}`, `DELETE /api/movies/{id}`, etc, we need to inform an access token issued by `Keycloak`.

### Getting Access Token

- Open a terminal.

- Run the following commands to get the access token:
  ```bash
  ACCESS_TOKEN="$(curl -s -X POST \
    "http://localhost:8080/realms/company-services/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=movies-app" | jq -r .access_token)"

  echo $ACCESS_TOKEN
  ```
  > **Note**: In [jwt.io](https://jwt.io), we can decode and verify the `JWT` access token.

### Calling movies-api endpoints using curl

- Trying to add a movie without access token:
  ```bash
  curl -i -X POST "http://localhost:9080/api/movies" \
    -H "Content-Type: application/json" \
    -d '{ "imdbId": "tt5580036", "title": "I, Tonya", "director": "Craig Gillespie", "year": 2017, "poster": "https://m.media-amazon.com/images/M/MV5BMjI5MDY1NjYzMl5BMl5BanBnXkFtZTgwNjIzNDAxNDM@._V1_SX300.jpg"}'
  ```

  It should return:
  ```text
  HTTP/1.1 401
  ```

- Trying again to add a movie, now with access token (obtained at [getting-access-token](#getting-access-token)):
  ```bash
  curl -i -X POST "http://localhost:9080/api/movies" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{ "imdbId": "tt5580036", "title": "I, Tonya", "director": "Craig Gillespie", "year": 2017, "poster": "https://m.media-amazon.com/images/M/MV5BMjI5MDY1NjYzMl5BMl5BanBnXkFtZTgwNjIzNDAxNDM@._V1_SX300.jpg"}'
  ```

  It should return:
  ```text
  HTTP/1.1 201
  {
    "imdbId": "tt5580036",
    "title": "I, Tonya",
    "director": "Craig Gillespie",
    "year": "2017",
    "poster": "https://m.media-amazon.com/images/M/MV5BMjI5MDY1NjYzMl5BMl5BanBnXkFtZTgwNjIzNDAxNDM@._V1_SX300.jpg",
    "comments": []
  }
  ```

- Getting the list of movies. This endpoint does not require access token:
  ```bash
  curl -i http://localhost:9080/api/movies
  ```

  It should return:
  ```text
  HTTP/1.1 200
  [
    {
      "imdbId": "tt5580036",
      "title": "I, Tonya",
      "director": "Craig Gillespie",
      "year": "2017",
      "poster": "https://m.media-amazon.com/images/M/MV5BMjI5MDY1NjYzMl5BMl5BanBnXkFtZTgwNjIzNDAxNDM@._V1_SX300.jpg",
      "comments": []
    }
  ]
  ```

### Calling movies-api endpoints using Swagger

- Access `movies-api` Swagger website, http://localhost:9080/swagger-ui.html.

- Click `Authorize` button.

- In the form that opens, paste the `access token` (obtained at [getting-access-token](#getting-access-token)) in the `Value` field. Then, click `Authorize` and `Close` to finalize.

- Done! We can now access the secured endpoints.

- ## Shutdown

- To stop `movies-api` and `movies-ui`, go to the terminals where they are running and press `Ctrl+C`;

- To stop and remove docker containers, network and volumes, go to a terminal and, inside the `springboot-react-keycloak` root folder, run the command below:
  ```bash
  ./shutdown-environment.sh
  ```
